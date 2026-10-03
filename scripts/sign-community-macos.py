"""Ad-hoc sign every Mach-O leaf, then its framework/bundle containers.
Qt QML plugins live under Resources and are not all covered by codesign --deep.
SPDX-License-Identifier: GPL-3.0-only
"""
from pathlib import Path
import subprocess
import sys
app = Path(sys.argv[1]).resolve()
magics = {b'\xcf\xfa\xed\xfe', b'\xce\xfa\xed\xfe', b'\xfe\xed\xfa\xcf', b'\xca\xfe\xba\xbe', b'\xbe\xba\xfe\xca'}
binaries = []
for path in app.rglob('*'):
    if path.is_symlink():
        target = path.resolve()
        if not target.is_relative_to(app):
            raise RuntimeError(f'External bundle symlink: {path} -> {target}')
    elif path.is_file():
        with path.open('rb') as source:
            if source.read(4) in magics:
                binaries.append(path)
for path in binaries:
    subprocess.run(['codesign', '--force', '--sign', '-', str(path)], check=True, capture_output=True)
for framework in sorted(app.rglob('*.framework'), key=lambda p: len(p.parts), reverse=True):
    subprocess.run(['codesign', '--force', '--sign', '-', str(framework)], check=True, capture_output=True)
subprocess.run(['codesign', '--force', '--deep', '--sign', '-', str(app)], check=True)
for path in binaries:
    subprocess.run(['codesign', '--verify', '--strict', str(path)], check=True, capture_output=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
print(f'PASS: signed and verified {len(binaries)} Mach-O files plus the app bundle')
