///|
fn read_input(path : String, side : String) -> String raise @lib.MoonRowError {
  let result = read_utf8(path)
  if result[0] != "" {
    raise @lib.MoonRowError({
      code: result[0],
      side,
      record: 0,
      line: 0,
      column: 0,
      message: "\{path}: \{result[1]}",
    })
  }
  result[1]
}

///|
fn run() -> Int raise @lib.MoonRowError {
  let args : Array[String] = []
  for arg in arguments() {
    args.push(arg)
  }
  match @cli.parse_args(args) {
    Help => {
      write_stdout(@cli.help())
      0
    }
    Version => {
      write_stdout("\{@lib.version()}\n")
      0
    }
    Compare(command) => {
      let before = read_input(command.before, "before")
      let after = read_input(command.after, "after")
      let result = @lib.compare_csv(before, after, command.options)
      write_stdout(@cli.render(result, command.format))
      if result.summary.has_diff {
        1
      } else {
        0
      }
    }
  }
}

///|
fn main {
  let code = run() catch {
    @lib.MoonRowError(diagnostic) => {
      write_stderr(@lib.render_diagnostic(diagnostic))
      2
    }
  }
  set_exit(code)
}
