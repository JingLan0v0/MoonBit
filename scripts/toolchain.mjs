import { existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

export const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const local = resolve(root, '../.tools/moon');
const localExe = resolve(local, 'bin', process.platform === 'win32' ? 'moon.exe' : 'moon');
export const moon = existsSync(localExe) ? localExe : 'moon';
export const env = existsSync(localExe) ? { ...process.env, MOON_HOME: local } : process.env;

export function runMoon(args) {
  const p = spawnSync(moon, args, { cwd: root, env, stdio: 'inherit' });
  if (p.error) throw p.error;
  if (p.status !== 0) throw new Error(`moon ${args.join(' ')} failed (${p.status})`);
}
