///|
extern "js" fn write_stdout(text : String) -> Unit =
  #|(text) => process.stdout.write(text)

///|
extern "js" fn set_exit(code : Int) -> Unit =
  #|(code) => { process.exitCode = code; }

///|
extern "js" fn write_stderr(text : String) -> Unit =
  #|(text) => process.stderr.write(text)

///|
extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

///|
// Host-only operations: bounded regular-file reads and fatal UTF-8 decoding.
// Return [error code, message or text] to avoid JS exceptions crossing the FFI.
extern "js" fn read_utf8(path : String) -> FixedArray[String] =
  #|(path) => {
  #|  const fs = require('node:fs');
  #|  const limit = 10 * 1024 * 1024;
  #|  let fd;
  #|  try {
  #|    fd = fs.openSync(path, 'r');
  #|    const stat = fs.fstatSync(fd);
  #|    if (!stat.isFile()) return ['IO_FILE', 'input must be a regular file'];
  #|    if (stat.size > limit) return ['LIMIT_BYTES', 'input exceeds 10 MiB'];
  #|    const chunks = [];
  #|    let total = 0;
  #|    while (total <= limit) {
  #|      const buffer = Buffer.allocUnsafe(Math.min(65536, limit + 1 - total));
  #|      const count = fs.readSync(fd, buffer, 0, buffer.length, null);
  #|      if (!count) break;
  #|      chunks.push(buffer.subarray(0, count));
  #|      total += count;
  #|    }
  #|    if (total > limit) return ['LIMIT_BYTES', 'input exceeds 10 MiB'];
  #|    try {
  #|      return ['', new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(Buffer.concat(chunks, total))];
  #|    } catch (_) { return ['UTF8', 'input is not valid UTF-8']; }
  #|  } catch (error) {
  #|    return ['IO_READ', String(error.code || 'read failed')];
  #|  } finally {
  #|    if (fd !== undefined) { try { fs.closeSync(fd); } catch (_) {} }
  #|  }
  #|}
