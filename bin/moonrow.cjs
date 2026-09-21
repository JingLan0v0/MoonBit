#!/usr/bin/env node
'use strict';
const { existsSync } = require('node:fs');
const { join } = require('node:path');
const artifact = join(__dirname, '../dist/moonrow.cjs');
if (!existsSync(artifact)) {
  process.stderr.write('MoonRow is not built yet. Run: node scripts/build.mjs\n');
  process.exitCode = 2;
} else {
  require(artifact);
}
