///|
extern "js" fn write_stdout(text : String) -> Unit =
  #|(text) => process.stdout.write(text)

///|
extern "js" fn set_exit(code : Int) -> Unit =
  #|(code) => { process.exitCode = code; }

///|
fn main {
  write_stdout("MoonRow toolchain ready\n")
  set_exit(0)
}
