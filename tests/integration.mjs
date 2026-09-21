import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, writeFileSync, readFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { performance } from 'node:perf_hooks';
import { root } from '../scripts/toolchain.mjs';

const artifacts = resolve(root, 'artifacts');
mkdirSync(artifacts, { recursive: true });
const tmp = mkdtempSync(join(artifacts, 'integration-'));
const records = [];
let calls = 0;
function execute(args) {
  calls++;
  const p = spawnSync(process.execPath, [resolve(root, 'bin/moonrow.cjs'), ...args], {
    cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, timeout: 30000,
  });
  assert.ifError(p.error);
  assert.equal(p.signal, null);
  return p;
}
function files(before, after) {
  const b = join(tmp, '旧 表.csv'); const a = join(tmp, '新 表.csv');
  writeFileSync(b, before); writeFileSync(a, after);
  return [b, a];
}
function jsonDiff(before, after, options = []) {
  const p = execute([...files(before, after), '--key', 'id', '--format', 'json', ...options]);
  assert.ok(p.status === 0 || p.status === 1, p.stderr);
  assert.equal(p.stderr, '');
  const value = JSON.parse(p.stdout);
  assert.equal(p.status, value.summary.has_diff ? 1 : 0);
  return value;
}
function bad(before, after, code, options = []) {
  const p = execute([...files(before, after), '--key', 'id', ...options]);
  assert.equal(p.status, 2, p.stderr);
  assert.equal(p.stdout, '');
  assert.ok(p.stderr.includes(`[${code}]`), p.stderr);
  assert.ok(!p.stderr.includes('at Object.'), 'no raw stack traces');
}
function test(name, fn) {
  const start = performance.now(); fn();
  records.push({ name, passed: true, duration_ms: Math.round(performance.now() - start) });
  console.log(`PASS ${name}`);
}

test('catalog expected result and three report formats', () => {
  const base = ['examples/catalog/before.csv', 'examples/catalog/after.csv', '--key', 'sku', '--ignore', 'updated_at'];
  const p = execute([...base, '--format', 'json']);
  assert.equal(p.status, 1); assert.equal(p.stderr, '');
  const r = JSON.parse(p.stdout);
  assert.deepEqual(r.summary, { before_rows: 4, after_rows: 4, added: 1, removed: 1, changed: 1, unchanged: 2, changed_cells: 1, has_diff: true });
  assert.deepEqual(r.changed, [{ key: ['A001'], changes: [{ column: 'price', before: '3.00', after: '3.50' }] }]);
  assert.deepEqual(r.added[0].key, ['A004']); assert.deepEqual(r.removed[0].key, ['A002']);
  assert.deepEqual(r.added[0].fields.map(f => f.column), ['name', 'price', 'sku']);
  writeFileSync(join(artifacts, 'catalog.json'), p.stdout);
  for (const format of ['text', 'markdown']) {
    const report = execute([...base, '--format', format]);
    assert.equal(report.status, 1); assert.equal(report.stderr, '');
    const visible = report.stdout.replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)));
    for (const token of ['A001', 'A002', 'A004', '3.00', '3.50']) assert.ok(visible.includes(token));
    writeFileSync(join(artifacts, `catalog.${format === 'markdown' ? 'md' : 'txt'}`), report.stdout);
  }
});

test('help version usage and actual exits 0 1 2', () => {
  assert.equal(execute(['--help']).status, 0);
  assert.equal(execute(['--version']).stdout.trim(), '0.1.0');
  const empty = execute([]); assert.equal(empty.status, 2); assert.ok(empty.stderr.includes('[USAGE]'));
  assert.equal(jsonDiff('id,v\n1,a', 'id,v\n1,a').summary.has_diff, false);
  assert.equal(jsonDiff('id,v\n1,a', 'id,v\n1,b').summary.has_diff, true);
  bad('id,v\n1,a\n1,b', 'id,v', 'DUPLICATE_KEY');
  bad('id,v', 'id,v\n,x', 'EMPTY_KEY');
  const missing = execute([join(tmp, 'missing.csv'), join(tmp, 'also-missing.csv'), '--key', 'id']);
  assert.equal(missing.status, 2); assert.ok(missing.stderr.includes('[IO_READ]')); assert.equal(missing.stdout, '');
  const directory = execute([tmp, tmp, '--key', 'id']); assert.equal(directory.status, 2);
  assert.ok(directory.stderr.includes('[IO_FILE]') || directory.stderr.includes('[IO_READ]'));
});

test('strict UTF-8, BOM, emoji, CRLF and quoted multiline values', () => {
  bad(Buffer.from([0xff, 0xfe, 0x00]), 'id,v', 'UTF8');
  bad(Buffer.from([0x69, 0x64, 0x2c, 0x76, 0x0a, 0x31, 0x2c, 0xc0, 0xaf]), 'id,v', 'UTF8');
  const input = '\ufeffid,v\r\n001,"中文,😀\r\n""quoted"""\r\n';
  const r = jsonDiff('id,v', input);
  assert.equal(r.added[0].fields.find(f => f.column === 'v').value, '中文,😀\r\n"quoted"');
  assert.equal(r.added[0].key[0], '001');
  assert.equal(jsonDiff(input, input).summary.unchanged, 1);
});

// This independent oracle works on original generated row objects. It neither
// parses CSV nor shares MoonRow's key encoding or comparison implementation.
function oracle(before, after) {
  const old = new Map(before.map(r => [r.id, r]));
  const now = new Map(after.map(r => [r.id, r]));
  const columns = ['alpha', 'v'];
  const result = { schema_version: 1, keys: ['id'], columns,
    summary: { before_rows: before.length, after_rows: after.length, added: 0, removed: 0, changed: 0, unchanged: 0, changed_cells: 0, has_diff: false },
    added: [], removed: [], changed: [] };
  const row = r => ({ key: [r.id], fields: ['alpha', 'id', 'v'].map(column => ({ column, value: r[column] })) });
  for (const id of [...new Set([...old.keys(), ...now.keys()])].sort()) {
    const b = old.get(id), a = now.get(id);
    if (!b) result.added.push(row(a));
    else if (!a) result.removed.push(row(b));
    else {
      const changes = columns.filter(c => b[c] !== a[c]).map(column => ({ column, before: b[column], after: a[column] }));
      if (changes.length) { result.changed.push({ key: [id], changes }); result.summary.changed_cells += changes.length; }
      else result.summary.unchanged++;
    }
  }
  for (const category of ['added', 'removed', 'changed']) result.summary[category] = result[category].length;
  result.summary.has_diff = !!(result.summary.added + result.summary.removed + result.summary.changed);
  return result;
}
const quote = s => `"${s.replaceAll('"', '""')}"`;
const csv = (rows, columns) => columns.map(quote).join(',') + '\n' + rows.map(r => columns.map(c => quote(r[c])).join(',')).join('\n');
let randomState = 0x5eed;
const random = () => { randomState = (Math.imul(randomState, 1664525) + 1013904223) >>> 0; return randomState; };
function shuffled(rows) { const copy = [...rows]; for (let i = copy.length - 1; i > 0; i--) { const j = random() % (i + 1); [copy[i], copy[j]] = [copy[j], copy[i]]; } return copy; }

test('25 seeded datasets match independent oracle including quoted values', () => {
  const values = ['', '001', '1.00', ' ', 'a,b', '"quoted"', 'line\nnext', 'CR\r\nLF', '😀中文', '<b>|`', 'x\ty'];
  for (let seed = 0; seed < 25; seed++) {
    const before = [], after = [];
    for (let i = 0; i < 40; i++) {
      const item = { id: `${i % 2 ? '长' : 'id'}${i}`, v: values[random() % values.length], alpha: values[random() % values.length] };
      if (random() % 5) before.push(item);
      if (random() % 5) after.push({ ...item, v: random() % 3 ? item.v : values[random() % values.length] });
    }
    const b = csv(shuffled(before), ['id', 'v', 'alpha']);
    const a = csv(shuffled(after), ['alpha', 'id', 'v']);
    assert.deepEqual(jsonDiff(b, a), oracle(before, after));
    assert.deepEqual(jsonDiff(a, b), oracle(after, before));
  }
});

test('composite key collision and ignored single-side columns', () => {
  const b = 'id,second,v,stamp\na|b,c,x,old\na,b|c,y,old';
  const a = 'second,v,id\nb|c,y,a\nc,z,a|b';
  const r = jsonDiff(b, a, ['--key', 'second', '--ignore', 'stamp']);
  assert.equal(r.summary.changed, 1); assert.equal(r.summary.unchanged, 1);
  assert.deepEqual(r.changed[0].key, ['a|b', 'c']);
});

test('default field limits below at above including UTF-16 surrogate pairs', () => {
  for (const n of [262143, 262144]) {
    const input = `id,v\n1,${'x'.repeat(n)}`;
    assert.equal(jsonDiff(input, input).summary.unchanged, 1);
  }
  bad(`id,v\n1,${'x'.repeat(262145)}`, 'id,v', 'LIMIT_FIELD');
  const emoji = `id,v\n1,${'😀'.repeat(131072)}`;
  assert.equal(jsonDiff(emoji, emoji).summary.unchanged, 1);
  bad(emoji + 'x', 'id,v', 'LIMIT_FIELD');
});

test('default column limits below at above', () => {
  for (const n of [99, 100]) {
    const input = ['id', ...Array.from({ length: n - 1 }, (_, i) => `c${i}`)].join(',');
    assert.equal(jsonDiff(input, input).summary.before_rows, 0);
  }
  bad(['id', ...Array.from({ length: 100 }, (_, i) => `c${i}`)].join(','), 'id,v', 'LIMIT_COLUMNS');
});

test('default row limits below at above', () => {
  for (const n of [49999, 50000]) {
    const input = 'id,v\n' + Array.from({ length: n }, (_, i) => `${i},v${i}`).join('\n');
    assert.equal(jsonDiff(input, input).summary.unchanged, n);
  }
  bad('id,v\n' + Array.from({ length: 50001 }, (_, i) => `${i},x`).join('\n'), 'id,v', 'LIMIT_ROWS');
});

function sizedCsv(bytes) {
  let out = 'id,v\n'; let id = 0;
  while (out.length < bytes) {
    const prefix = `${id++},`;
    const count = Math.min(260000, bytes - out.length - prefix.length - 1);
    assert.ok(count >= 0);
    out += prefix + 'x'.repeat(count) + '\n';
  }
  assert.equal(Buffer.byteLength(out), bytes);
  return out;
}
test('10 MiB bounded reader below at above byte limit', () => {
  for (const n of [10 * 1024 * 1024 - 1, 10 * 1024 * 1024]) {
    const input = sizedCsv(n);
    assert.equal(jsonDiff(input, input).summary.has_diff, false);
  }
  bad(sizedCsv(10 * 1024 * 1024 + 1), 'id,v', 'LIMIT_BYTES');
});

test('report and error control characters are inert', () => {
  const input = 'id,v\n1,"<script>|`\u001b[31m\u009b\u202ex\nnext"';
  const args = [...files('id,v\n1,old', input), '--key', 'id'];
  const text = execute(args); assert.equal(text.status, 1);
  assert.ok(!/[\u001b\u009b\u202e]/u.test(text.stdout));
  const md = execute([...args, '--format', 'markdown']);
  assert.ok(!md.stdout.includes('<script>')); assert.ok(md.stdout.includes('&#124;'));
  const error = execute([...args, '--ignore', '\u001b[31m']);
  assert.equal(error.status, 2); assert.ok(!error.stderr.includes('\u001b'));
});

test('10,000 row benchmark returns correct totals', () => {
  const before = 'id,v\n' + Array.from({ length: 10000 }, (_, i) => `${i},value${i}`).join('\n');
  const after = 'id,v\n' + Array.from({ length: 10000 }, (_, i) => `${i},value${i % 10 ? i : i + 1}`).join('\n');
  const r = jsonDiff(before, after);
  assert.equal(r.summary.changed, 1000); assert.equal(r.summary.unchanged, 9000);
});

const report = { generated_at: new Date().toISOString(), platform: process.platform, arch: process.arch, node: process.version, subprocesses: calls, suites: records };
writeFileSync(join(artifacts, 'integration-results.json'), JSON.stringify(report, null, 2) + '\n');
console.log(`Integration: ${records.length} suites, ${calls} real processes, all passed.`);
