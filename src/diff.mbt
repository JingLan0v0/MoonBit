///|
priv struct IndexedRow {
  key : Array[String]
  values : Array[String]
  record : Int
}

///|
fn key_id(parts : Array[String]) -> String {
  let b = StringBuilder()
  for part in parts {
    b.write_string("\{part.length()}:\{part}")
  }
  b.to_string()
}

///|
fn compare_key(a : Array[String], b : Array[String]) -> Int {
  for i = 0; i < a.length(); i = i + 1 {
    let c = a[i].lexical_compare(b[i])
    if c != 0 {
      return c
    }
  }
  0
}

///|
fn index_headers(table : Table) -> Map[String, Int] {
  let result : Map[String, Int] = Map([])
  for i, name in table.headers {
    result[name] = i
  }
  result
}

///|
fn index_rows(
  table : Table,
  headers : Map[String, Int],
  keys : Array[String],
  side : String,
) -> Map[String, IndexedRow] raise MoonRowError {
  let result : Map[String, IndexedRow] = Map([])
  for i, row in table.rows {
    let parts : Array[String] = []
    for key in keys {
      let value = row[headers[key]]
      if value.is_empty() {
        fail("EMPTY_KEY", side, "empty key component: \{key}", record=i + 2)
      }
      parts.push(value)
    }
    let id = key_id(parts)
    if result.get(id) is Some(previous) {
      fail(
        "DUPLICATE_KEY",
        side,
        "key duplicates record \{previous.record}",
        record=i + 2,
      )
    }
    result[id] = { key: parts, values: row, record: i + 2, }
  }
  result
}

///|
fn row_data(
  row : IndexedRow,
  headers : Map[String, Int],
  columns : Array[String],
) -> RowData {
  {
    key: row.key,
    fields: columns.map(fn(name) {
      { column: name, value: row.values[headers[name]], }
    }),
  }
}

///|
/// Compares parsed snapshots. All matching and cell comparison is exact string equality.
/// Ignored columns may exist on only one side; other schemas must match.
pub fn compare(
  before : Table,
  after : Table,
  options : Options,
) -> DiffResult raise MoonRowError {
  let bh = index_headers(before)
  let ah = index_headers(after)
  let keys : Map[String, Bool] = Map([])
  let ignored : Map[String, Bool] = Map([])
  if options.keys.is_empty() {
    fail("MISSING_KEY", "options", "at least one key column is required")
  }
  for key in options.keys {
    if keys.contains(key) {
      fail("DUPLICATE_KEY_OPTION", "options", "key column repeated: \{key}")
    }
    if !bh.contains(key) || !ah.contains(key) {
      fail("KEY_COLUMN", "options", "key must exist in both tables: \{key}")
    }
    keys[key] = true
  }
  for name in options.ignore {
    if ignored.contains(name) {
      fail("DUPLICATE_IGNORE", "options", "ignore column repeated: \{name}")
    }
    if keys.contains(name) {
      fail("IGNORE_KEY", "options", "cannot ignore a key column: \{name}")
    }
    if !bh.contains(name) && !ah.contains(name) {
      fail("IGNORE_COLUMN", "options", "unknown ignore column: \{name}")
    }
    ignored[name] = true
  }
  let columns = before.headers.filter(fn(name) { !ignored.contains(name) })
  let other = after.headers.filter(fn(name) { !ignored.contains(name) })
  columns.sort_by(fn(a, b) { a.lexical_compare(b) })
  other.sort_by(fn(a, b) { a.lexical_compare(b) })
  if columns != other {
    fail("SCHEMA_MISMATCH", "both", "non-ignored column names differ")
  }
  let compared = columns.filter(fn(name) { !keys.contains(name) })
  if compared.is_empty() {
    fail("NO_VALUE_COLUMNS", "options", "keep at least one non-key column")
  }
  let bi = index_rows(before, bh, options.keys, "before")
  let ai = index_rows(after, ah, options.keys, "after")
  let added : Array[RowData] = []
  let removed : Array[RowData] = []
  let changed : Array[RowChange] = []
  let mut unchanged = 0
  let mut changed_cells = 0
  for id, old in bi {
    match ai.get(id) {
      None => removed.push(row_data(old, bh, columns))
      Some(new) => {
        let changes : Array[CellChange] = []
        for name in compared {
          let b = old.values[bh[name]]
          let a = new.values[ah[name]]
          if b != a {
            changes.push({ column: name, before: b, after: a, })
          }
        }
        if changes.is_empty() {
          unchanged += 1
        } else {
          changed_cells += changes.length()
          changed.push({ key: old.key, changes, })
        }
      }
    }
  }
  for id, row in ai {
    if !bi.contains(id) {
      added.push(row_data(row, ah, columns))
    }
  }
  added.sort_by(fn(a, b) { compare_key(a.key, b.key) })
  removed.sort_by(fn(a, b) { compare_key(a.key, b.key) })
  changed.sort_by(fn(a, b) { compare_key(a.key, b.key) })
  {
    schema_version: 1,
    keys: options.keys.copy(),
    columns: compared,
    summary: {
      before_rows: before.rows.length(),
      after_rows: after.rows.length(),
      added: added.length(),
      removed: removed.length(),
      changed: changed.length(),
      unchanged,
      changed_cells,
      has_diff: !added.is_empty() || !removed.is_empty() || !changed.is_empty(),
    },
    added,
    removed,
    changed,
  }
}

///|
/// Convenience API using the same parser and comparator as the command line tool.
pub fn compare_csv(
  before : String,
  after : String,
  options : Options,
  limits? : Limits = default_limits(),
) -> DiffResult raise MoonRowError {
  compare(
    parse_csv(before, side="before", limits~),
    parse_csv(after, side="after", limits~),
    options,
  )
}
