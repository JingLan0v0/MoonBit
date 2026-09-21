///|
pub fn render_json(result : DiffResult) -> String {
  @json.to_json(result).stringify(indent=2) + "\n"
}

///|
/// Escapes control characters so user data cannot inject terminal sequences.
pub fn quote_text(value : String) -> String {
  let b = StringBuilder()
  b.write_char('"')
  for ch in value {
    match ch {
      '"' => b.write_string("\\\"")
      '\\' => b.write_string("\\\\")
      '\n' => b.write_string("\\n")
      '\r' => b.write_string("\\r")
      '\t' => b.write_string("\\t")
      _ => {
        let n = ch.to_int()
        if n < 32 ||
          (n >= 127 && n <= 159) ||
          (n >= 0x202A && n <= 0x202E) ||
          (n >= 0x2066 && n <= 0x2069) {
          b.write_string("\\u{\{n.to_string(radix=16)}}")
        } else {
          b.write_char(ch)
        }
      }
    }
  }
  b.write_char('"')
  b.to_string()
}

///|
fn key_label(key : Array[String]) -> String {
  key.map(quote_text).join(", ")
}

///|
fn field_label(fields : Array[FieldValue]) -> String {
  fields
  .map(fn(f) { "\{quote_text(f.column)}=\{quote_text(f.value)}" })
  .join(", ")
}

///|
pub fn render_text(result : DiffResult) -> String {
  let s = result.summary
  let b = StringBuilder()
  b.write_string("MoonRow \{version()}\n")
  b.write_string(
    "before=\{s.before_rows} after=\{s.after_rows} added=\{s.added} removed=\{s.removed} changed=\{s.changed} unchanged=\{s.unchanged} changed_cells=\{s.changed_cells}\n",
  )
  for row in result.added {
    b.write_string("+ [\{key_label(row.key)}] \{field_label(row.fields)}\n")
  }
  for row in result.removed {
    b.write_string("- [\{key_label(row.key)}] \{field_label(row.fields)}\n")
  }
  for row in result.changed {
    b.write_string("~ [\{key_label(row.key)}]\n")
    for c in row.changes {
      b.write_string(
        "  \{quote_text(c.column)}: \{quote_text(c.before)} -> \{quote_text(c.after)}\n",
      )
    }
  }
  b.to_string()
}

///|
// Numeric character references preserve visible text without introducing Markdown or HTML.
fn markdown(value : String) -> String {
  let b = StringBuilder()
  for ch in quote_text(value) {
    let n = ch.to_int()
    if (n >= 33 && n <= 47) ||
      (n >= 58 && n <= 64) ||
      (n >= 91 && n <= 96) ||
      (n >= 123 && n <= 126) {
      b.write_string("&#\{n};")
    } else {
      b.write_char(ch)
    }
  }
  b.to_string()
}

///|
pub fn render_markdown(result : DiffResult) -> String {
  let s = result.summary
  let b = StringBuilder()
  b.write_string("# MoonRow comparison\n\n")
  b.write_string(
    "| Before | After | Added | Removed | Changed | Unchanged | Changed cells |\n| --- | --- | --- | --- | --- | --- | --- |\n",
  )
  b.write_string(
    "| \{s.before_rows} | \{s.after_rows} | \{s.added} | \{s.removed} | \{s.changed} | \{s.unchanged} | \{s.changed_cells} |\n\n",
  )
  b.write_string(
    "| Status | Key | Column | Before | After |\n| --- | --- | --- | --- | --- |\n",
  )
  for row in result.added {
    for f in row.fields {
      b.write_string(
        "| added | \{markdown(key_label(row.key))} | \{markdown(f.column)} | — | \{markdown(f.value)} |\n",
      )
    }
  }
  for row in result.removed {
    for f in row.fields {
      b.write_string(
        "| removed | \{markdown(key_label(row.key))} | \{markdown(f.column)} | \{markdown(f.value)} | — |\n",
      )
    }
  }
  for row in result.changed {
    for c in row.changes {
      b.write_string(
        "| changed | \{markdown(key_label(row.key))} | \{markdown(c.column)} | \{markdown(c.before)} | \{markdown(c.after)} |\n",
      )
    }
  }
  b.to_string()
}

///|
pub fn render_diagnostic(d : Diagnostic) -> String {
  "[\{d.code}] \{d.side} record=\{d.record} line=\{d.line} column=\{d.column}: \{quote_text(d.message)}\n"
}
