///|
priv enum CsvState {
  Start
  Bare
  Quoted
  Closed
}

///|
priv struct Parser {
  side : String
  limits : Limits
  records : Array[Array[String]]
  mut fields : Array[String]
  field : StringBuilder
  mut field_units : Int
  mut state : CsvState
  mut line : Int
  mut column : Int
  mut previous_cr : Bool
  mut pending_cr : Bool
  mut touched : Bool
}

///|
fn Parser::error(
  self : Parser,
  code : String,
  message : String,
) -> Unit raise MoonRowError {
  fail(
    code,
    self.side,
    message,
    record=self.records.length() + 1,
    line=self.line,
    column=self.column,
  )
}

///|
fn Parser::append(self : Parser, ch : Char) -> Unit raise MoonRowError {
  let units = if ch.to_int() > 0xFFFF { 2 } else { 1 }
  if self.field_units + units > self.limits.max_field_units {
    self.error("LIMIT_FIELD", "field exceeds UTF-16 unit limit")
  }
  self.field.write_char(ch)
  self.field_units += units
}

///|
fn Parser::end_field(self : Parser) -> Unit raise MoonRowError {
  if self.fields.length() >= self.limits.max_columns {
    self.error("LIMIT_COLUMNS", "record exceeds column limit")
  }
  self.fields.push(self.field.to_string())
  self.field.reset()
  self.field_units = 0
  self.state = Start
}

///|
fn Parser::end_record(self : Parser) -> Unit raise MoonRowError {
  self.end_field()
  if self.records.length() > 0 &&
    self.fields.length() != self.records[0].length() {
    self.error(
      "ROW_WIDTH",
      "record has \{self.fields.length()} fields; expected \{self.records[0].length()}",
    )
  }
  if self.records.length() > self.limits.max_rows {
    self.error("LIMIT_ROWS", "input exceeds data record limit")
  }
  self.records.push(self.fields)
  self.fields = []
  self.touched = false
}

///|
/// Parses the documented UTF-8 CSV text dialect. The host must decode bytes strictly.
/// Header validation and record-width validation happen here, not only in the CLI.
pub fn parse_csv(
  text : String,
  side? : String = "input",
  limits? : Limits = default_limits(),
) -> Table raise MoonRowError {
  if limits.max_rows < 0 || limits.max_columns < 1 || limits.max_field_units < 1 {
    fail(
      "INVALID_LIMITS", side, "limits require rows >= 0, columns >= 1, field units >= 1",
    )
  }
  let p : Parser = {
    side,
    limits,
    records: [],
    fields: [],
    field: StringBuilder(),
    field_units: 0,
    state: Start,
    line: 1,
    column: 1,
    previous_cr: false,
    pending_cr: false,
    touched: false,
  }
  let mut first = true
  for ch in text {
    if first {
      first = false
      if ch == '\uFEFF' {
        continue
      }
    }
    if p.pending_cr {
      if ch != '\n' {
        p.error("CSV_BARE_CR", "CR outside quotes must be followed by LF")
      }
      p.pending_cr = false
      p.end_record()
    } else {
      p.touched = true
      match p.state {
        Quoted => if ch == '"' { p.state = Closed } else { p.append(ch) }
        Start | Bare | Closed =>
          match ch {
            ',' => p.end_field()
            '\n' => p.end_record()
            '\r' => p.pending_cr = true
            '"' =>
              match p.state {
                Start => p.state = Quoted
                Closed => {
                  p.append('"')
                  p.state = Quoted
                }
                _ => p.error("CSV_QUOTE", "quote inside an unquoted field")
              }
            _ =>
              match p.state {
                Closed =>
                  p.error(
                    "CSV_AFTER_QUOTE", "unexpected character after closing quote",
                  )
                _ => {
                  p.append(ch)
                  p.state = Bare
                }
              }
          }
      }
    }
    if ch == '\r' {
      p.line += 1
      p.column = 1
      p.previous_cr = true
    } else if ch == '\n' {
      if !p.previous_cr {
        p.line += 1
      }
      p.column = 1
      p.previous_cr = false
    } else {
      p.column += 1
      p.previous_cr = false
    }
  }
  if p.pending_cr {
    p.error("CSV_BARE_CR", "CR outside quotes must be followed by LF")
  }
  if p.state is Quoted {
    p.error("CSV_UNCLOSED", "unterminated quoted field")
  }
  if p.touched {
    p.end_record()
  }
  if p.records.is_empty() {
    fail("EMPTY_INPUT", side, "CSV needs a header record")
  }
  let headers = p.records[0]
  let seen : Map[String, Bool] = Map([])
  for name in headers {
    if name.is_empty() {
      fail("EMPTY_HEADER", side, "header names must not be empty", record=1)
    }
    if seen.contains(name) {
      fail("DUPLICATE_HEADER", side, "duplicate header: \{name}", record=1)
    }
    seen[name] = true
  }
  let rows : Array[Array[String]] = []
  for i = 1; i < p.records.length(); i = i + 1 {
    rows.push(p.records[i])
  }
  { headers, rows, }
}
