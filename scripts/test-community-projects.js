// SPDX-License-Identifier: GPL-3.0-only
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const dir = path.join(__dirname, '../examples/Community');
for (const name of ['PID.ssproj', 'UARTdrawing.ssproj']) {
  const p = JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8'));
  assert(p.groups.length > 0);
  for (const s of p.sources) {
    assert(!s.connection?.deviceId, 'Do not publish hardware identifiers');
    assert(!Object.hasOwn(s.connection || {}, 'portIndex'));
    new vm.Script(s.frameParserCode);
  }
}
const p = JSON.parse(fs.readFileSync(path.join(dir, 'PID.ssproj'), 'utf8'));
const context = vm.createContext({});
vm.runInContext(p.sources[0].frameParserCode, context);
function frame(actual, target) {
  const data = Buffer.alloc(49);
  data[0] = 0xab;
  data.writeFloatLE(actual, 1);
  data.writeFloatLE(target, 5);
  return Array.from(data);
}
function parse(data) { return JSON.parse(JSON.stringify(context.parse(data))); }
const a = frame(12.5, 157), b = frame(25, 314);
assert.deepEqual(parse(a), [[12.5, 157]]);
assert.deepEqual(parse(a.slice(0, 5)), []);
assert.deepEqual(parse(a.slice(5)), [[12.5, 157]]);
assert.deepEqual(parse(a.concat(b)), [[12.5, 157], [25, 314]]);
const rows = [];
for (const byte of a) rows.push(...parse([byte]));
assert.deepEqual(rows, [[12.5, 157]]);
assert.deepEqual(parse([0, 0, 0].concat(b)), [[25, 314]]);
console.log('PASS: both project files; PID framing across complete, split, joined, bytewise and noisy input.');
