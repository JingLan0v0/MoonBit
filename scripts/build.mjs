import { mkdirSync, copyFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { root, runMoon } from './toolchain.mjs';

runMoon(['build', '--target', 'js', '--release']);
mkdirSync(resolve(root, 'dist'), { recursive: true });
copyFileSync(resolve(root, '_build/js/release/build/cmd/main/main.js'), resolve(root, 'dist/moonrow.cjs'));
console.log('Built dist/moonrow.cjs');
