///|
pub(all) enum Format {
  Text
  Json
  Markdown
}

///|
pub(all) struct CompareCommand {
  before : String
  after : String
  options : @lib.Options
  format : Format
}

///|
pub(all) enum Command {
  Help
  Version
  Compare(CompareCommand)
}

///|
fn usage_error(message : String) -> Unit raise @lib.MoonRowError {
  raise @lib.MoonRowError({
    code: "USAGE",
    side: "options",
    record: 0,
    line: 0,
    column: 0,
    message,
  })
}

///|
pub fn parse_args(args : Array[String]) -> Command raise @lib.MoonRowError {
  if args == ["--help"] || args == ["-h"] {
    return Help
  }
  if args == ["--version"] {
    return Version
  }
  let paths : Array[String] = []
  let keys : Array[String] = []
  let ignore : Array[String] = []
  let mut format = Text
  let mut format_seen = false
  let mut positional = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if !positional && arg == "--" {
      positional = true
      i += 1
      continue
    }
    if !positional && (arg == "--key" || arg == "--ignore" || arg == "--format") {
      if i + 1 >= args.length() {
        usage_error("missing value for \{arg}")
      }
      let value = args[i + 1]
      if value.is_empty() || value.has_prefix("--") {
        usage_error("invalid value for \{arg}")
      }
      match arg {
        "--key" => keys.push(value)
        "--ignore" => ignore.push(value)
        _ => {
          if format_seen {
            usage_error("--format may only appear once")
          }
          format_seen = true
          format = match value {
            "text" => Text
            "json" => Json
            "markdown" => Markdown
            _ => {
              usage_error("format must be text, json, or markdown")
              Text
            }
          }
        }
      }
      i += 2
    } else {
      if !positional && arg.has_prefix("-") {
        usage_error("unknown option: \{arg}")
      }
      paths.push(arg)
      i += 1
    }
  }
  if paths.length() != 2 {
    usage_error("provide BEFORE.csv and AFTER.csv")
  }
  if keys.is_empty() {
    usage_error("provide at least one --key COLUMN")
  }
  Compare({
    before: paths[0],
    after: paths[1],
    options: { keys, ignore, },
    format,
  })
}

///|
pub fn help() -> String {
  "MoonRow \{@lib.version()} - compare CSV snapshots by business key\n\nUsage: moonrow BEFORE.csv AFTER.csv --key COLUMN [options]\n\n  --key COLUMN       Repeat for a composite key (required)\n  --ignore COLUMN    Repeat to exclude non-key columns\n  --format FORMAT    text (default), json, markdown\n  --                 Treat remaining arguments as paths\n  --help, -h         Show help\n  --version          Show version\n\nUTF-8 CSV only; exact string comparison; no numeric conversion.\nLimits per input: 10 MiB, 50000 data records, 100 columns,\n262144 UTF-16 units per field. Files are read locally and never uploaded.\nExit codes: 0 no difference, 1 difference, 2 invalid input or I/O error.\n"
}

///|
pub fn render(result : @lib.DiffResult, format : Format) -> String {
  match format {
    Text => @lib.render_text(result)
    Json => @lib.render_json(result)
    Markdown => @lib.render_markdown(result)
  }
}
