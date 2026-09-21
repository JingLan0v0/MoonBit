import { runMoon } from './toolchain.mjs';

runMoon(['check', '--target', 'js', '--deny-warn']);
runMoon(['test', '--target', 'js', '--deny-warn']);
runMoon(['fmt', '--check']);
runMoon(['info', '--target', 'js']);
await import('./build.mjs');
runMoon(['run', 'src/examples/library_usage', '--target', 'js']);
await import('../tests/integration.mjs');
