// Local publication preflight only. This never authenticates or uploads a package.
import assert from 'node:assert/strict';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { root, moon, env, runMoon } from './toolchain.mjs';

const manifest = readFileSync(resolve(root, 'moon.mod'), 'utf8');
const version = manifest.match(/^version\s*=\s*"([^"]+)"/m)?.[1];
assert.ok(version, 'MoonBit version is required');
assert.equal(JSON.parse(readFileSync(resolve(root, 'package.json'), 'utf8')).version, version);
assert.ok(readFileSync(resolve(root, 'src/model.mbt'), 'utf8').includes(`"${version}"`), 'CLI version must match');
const p = spawnSync(moon, ['package', '--list'], { cwd: root, env, encoding: 'utf8', timeout: 120000 });
assert.ifError(p.error);
assert.equal(p.status, 0, p.stderr || p.stdout);
// The pinned Moon tool prints its listing on stderr; accept either stream.
const files = `${p.stdout}\n${p.stderr}`.split(/\r?\n/).map(s => s.trim().replaceAll('\\', '/')).filter(Boolean);
for (const required of ['moon.mod', 'src/moon.pkg', 'src/model.mbt', 'src/pkg.generated.mbti',
  'src/cmd/main/host.mbt', 'LICENSE', 'NOTICE', 'README.md', 'examples/inventory/before.csv', 'tests/integration.mjs']) {
  assert.ok(files.includes(required), `Missing package file: ${required}`);
}
for (const file of files) {
  assert.ok(!/^(?:dist|artifacts|output|node_modules|docs\/archive)\//.test(file), `Unexpected publication content: ${file}`);
  assert.ok(!/\.(?:pdf|pem|key)$/i.test(file), `Unexpected publication attachment: ${file}`);
}
runMoon(['package']);
mkdirSync(resolve(root, 'artifacts'), { recursive: true });
writeFileSync(resolve(root, 'artifacts/package-check.json'), JSON.stringify({
  checked_at: new Date().toISOString(), version, passed: true,
  scope: 'Local package contents and version consistency; not a registry publication',
}, null, 2) + '\n');
console.log('Mooncakes package preflight passed (local only; not published).');
