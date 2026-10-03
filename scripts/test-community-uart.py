#!/usr/bin/env python3
"""Exercise the built GPL app against a virtual UART, never a physical device.
Uses an isolated project copy; only this test process permits API writes to its PTY.
SPDX-License-Identifier: GPL-3.0-only
"""
import argparse
import json
import os
from pathlib import Path
import pty
import select
import shutil
import socket
import struct
import subprocess
import tempfile
import time
import tty

parser = argparse.ArgumentParser()
parser.add_argument('--app', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
app = args.app or root / 'build-community/app/Serial-Scope.app/Contents/MacOS/Serial-Scope'
# Do not accidentally connect the test to another running application's API.
try:
    occupied = socket.create_connection(('127.0.0.1', 7777), timeout=.2)
except OSError:
    pass
else:
    occupied.close()
    raise SystemExit('Port 7777 is in use. Close the other app/API before testing.')

with tempfile.TemporaryDirectory(prefix='serial-scope-test-') as tmp:
    project = Path(tmp) / 'PID.ssproj'
    shutil.copy2(root / 'examples/Community/PID.ssproj', project)
    master, slave = pty.openpty()
    tty.setraw(slave)
    os.set_blocking(master, False)
    env = dict(os.environ, SERIAL_STUDIO_API_AUTO_CONSENT='1')
    with open(Path(tmp) / 'app.log', 'w+') as log:
        proc = subprocess.Popen([str(app), '--headless', '--api-server', '--project', str(project),
                                 '--uart', os.ttyname(slave), '--baud', '115200'],
                                stdout=log, stderr=log, env=env)
        sock = None
        try:
            deadline = time.monotonic() + 30
            while True:
                if proc.poll() is not None:
                    raise RuntimeError(f'App exited with {proc.returncode}')
                try:
                    sock = socket.create_connection(('127.0.0.1', 7777), timeout=.5)
                    break
                except OSError:
                    if time.monotonic() > deadline:
                        raise TimeoutError('API did not start')
                    time.sleep(.1)
            sock.settimeout(5)
            stream = sock.makefile('rb')
            seq = 0
            def command(name, params=None):
                global seq
                seq += 1
                ident = str(seq)
                sock.sendall((json.dumps({'type': 'command', 'id': ident,
                                        'command': name, 'params': params or {}}) + '\n').encode())
                end = time.monotonic() + 8
                while time.monotonic() < end:
                    line = stream.readline()
                    if not line:
                        raise RuntimeError('API closed')
                    reply = json.loads(line)
                    if reply.get('id') == ident:
                        assert reply.get('success'), reply
                        return reply.get('result', {})
                raise TimeoutError(name)
            status = command('io.getStatus')
            assert status['isConnected'] and status['readWrite'], status
            print('PASS: --uart selects and connects the requested virtual serial port')
            frame = b'\xab' + struct.pack('<ff', 12.5, 157.0) + bytes(40)
            for _ in range(8):
                os.write(master, frame[:5])
                time.sleep(.01)
                os.write(master, frame[5:] + frame)
                time.sleep(.04)
            deadline = time.monotonic() + 5
            while True:
                data = command('dashboard.getData')
                groups = data.get('frame', {}).get('groups', [])
                values = [d['numericValue'] for g in groups for d in g.get('datasets', [])]
                if values == [12.5, 157]:
                    break
                if time.monotonic() > deadline:
                    raise AssertionError(data)
                time.sleep(.05)
            print('PASS: split and joined binary frames reach the actual dashboard datasets')
            command('console.setDataMode', {'modeIndex': 0})
            command('console.setLineEnding', {'endingIndex': 0})
            command('console.send', {'data': 'io=0#'})
            assert select.select([master], [], [], 3)[0], 'No UART transmit data'
            assert os.read(master, 100) == b'io=0#'
            command('console.setDataMode', {'modeIndex': 1})
            command('console.send', {'data': '41 42 00 FF'})
            assert select.select([master], [], [], 3)[0], 'No HEX transmit data'
            assert os.read(master, 100) == b'AB\x00\xff'
            print('PASS: console transmits exact text and HEX bytes through the virtual UART')
            command('io.disconnect')
            assert not command('io.getStatus')['isConnected']
            print('PASS: disconnect')
        except Exception:
            log.flush(); log.seek(0)
            print(log.read())
            raise
        finally:
            if sock:
                sock.close()
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill(); proc.wait()
            os.close(master); os.close(slave)
