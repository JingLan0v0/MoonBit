///|
fn error_code(run : () -> Unit raise @moonrow.MoonRowError) -> String {
  try {
    run()
    "NO_ERROR"
  } catch {
    @moonrow.MoonRowError(d) => d.code
  }
}

///|
test "invalid CSV is rejected with specific diagnostics" {
  let cases = [
    ("", "EMPTY_INPUT"),
    ("\uFEFF", "EMPTY_INPUT"),
    ("id,\nv,x", "EMPTY_HEADER"),
    ("id,id\n1,2", "DUPLICATE_HEADER"),
    ("id,v\n1", "ROW_WIDTH"),
    ("id,v\n1,a,b", "ROW_WIDTH"),
    ("id,v\n1,\"broken", "CSV_UNCLOSED"),
    ("id,v\n1,x\"y", "CSV_QUOTE"),
    ("id,v\n1,\"x\"oops", "CSV_AFTER_QUOTE"),
    ("id,v\r1,x", "CSV_BARE_CR"),
    ("id,v\n1,x\r", "CSV_BARE_CR"),
    ("id,v\n\n", "ROW_WIDTH"),
  ]
  for item in cases {
    let (input, expected) = item
    assert_eq(error_code(() => ignore(@moonrow.parse_csv(input))), expected)
  }
}

///|
test "empty data tables are legal but headers remain required" {
  for header in ["id,v", "id,v\n", "id,v\r\n"] {
    let r = @moonrow.compare_csv(header, header, { keys: ["id"], ignore: [], })
    assert_eq(r.summary.before_rows, 0)
    assert_eq(r.summary.has_diff, false)
  }
  assert_eq(@moonrow.parse_csv("single\n\n").row_count(), 1)
}

///|
test "duplicate and empty key diagnostics retain record numbers" {
  let err = try {
    ignore(
      @moonrow.compare_csv("id,v\n1,a\n1,b", "id,v", {
        keys: ["id"],
        ignore: [],
      }),
    )
    None
  } catch {
    @moonrow.MoonRowError(d) => Some(d)
  }
  guard err is Some(d) else { fail("expected duplicate key error") }
  assert_eq(d.code, "DUPLICATE_KEY")
  assert_eq(d.side, "before")
  assert_eq(d.record, 3)
  assert_true(d.message.contains("record 2"))
  assert_eq(
    error_code(() => {
      ignore(
        @moonrow.compare_csv("id,v", "id,v\n,x", { keys: ["id"], ignore: [], }),
      )
    }),
    "EMPTY_KEY",
  )
}

///|
test "syntax errors distinguish physical lines and logical records" {
  let err = try {
    ignore(@moonrow.parse_csv("id,v\n1,\"two\nlines\"z", side="before"))
    None
  } catch {
    @moonrow.MoonRowError(d) => Some(d)
  }
  guard err is Some(d) else { fail("expected syntax error") }
  assert_eq(d.record, 2)
  assert_eq(d.line, 3)
  assert_eq(d.column, 7)
}

///|
test "option validation covers missing duplicate unknown and ignored keys" {
  let cases : Array[(@moonrow.Options, String)] = [
    ({ keys: [], ignore: [], }, "MISSING_KEY"),
    ({ keys: ["id", "id"], ignore: [], }, "DUPLICATE_KEY_OPTION"),
    ({ keys: ["missing"], ignore: [], }, "KEY_COLUMN"),
    ({ keys: ["id"], ignore: ["id"], }, "IGNORE_KEY"),
    ({ keys: ["id"], ignore: ["x"], }, "IGNORE_COLUMN"),
    ({ keys: ["id"], ignore: ["v", "v"], }, "DUPLICATE_IGNORE"),
    ({ keys: ["id"], ignore: ["v"], }, "NO_VALUE_COLUMNS"),
  ]
  for item in cases {
    let (options, expected) = item
    assert_eq(
      error_code(() => {
        ignore(@moonrow.compare_csv("id,v\n1,a", "id,v\n1,a", options))
      }),
      expected,
    )
  }
}

///|
test "ignored column can exist on one side only" {
  let b = "id,v,stamp\n1,a,old"
  let a = "v,id\na,1"
  assert_eq(
    error_code(() => {
      ignore(@moonrow.compare_csv(b, a, { keys: ["id"], ignore: [], }))
    }),
    "SCHEMA_MISMATCH",
  )
  let r = @moonrow.compare_csv(b, a, { keys: ["id"], ignore: ["stamp"], })
  assert_eq(r.summary.unchanged, 1)
}

///|
test "exact string semantics preserve whitespace case numeric forms and newlines" {
  for
    pair in [
      ("001", "1"),
      ("1.0", "1.00"),
      (" a", "a"),
      ("A", "a"),
      ("", " "),
      ("x\r\ny", "x\ny"),
    ] {
    let (a, b) = pair
    let r = @moonrow.compare_csv("id,v\n1,\"\{a}\"", "id,v\n1,\"\{b}\"", {
      keys: ["id"],
      ignore: [],
    })
    assert_eq(r.summary.changed, 1)
    assert_eq(r.changed[0].changes[0].before, a)
    assert_eq(r.changed[0].changes[0].after, b)
  }
}

///|
test "limits are checked at below equal and above boundaries" {
  let limits : @moonrow.Limits = {
    max_rows: 2,
    max_columns: 2,
    max_field_units: 3,
  }
  for s in ["id,v", "id,v\n1,ab", "id,v\n1,abc\n2,😀x"] {
    ignore(@moonrow.parse_csv(s, limits~))
  }
  for
    pair in [
      ("id,v\n1,abcd", "LIMIT_FIELD"),
      ("id,v\n1,😀😀", "LIMIT_FIELD"),
      ("id,v,x", "LIMIT_COLUMNS"),
      ("id,v\n1,a\n2,b\n3,c", "LIMIT_ROWS"),
    ] {
    let (s, expected) = pair
    assert_eq(
      error_code(() => ignore(@moonrow.parse_csv(s, limits~))),
      expected,
    )
  }
  ignore(
    @moonrow.parse_csv("id,v", limits={
      max_rows: 0,
      max_columns: 2,
      max_field_units: 2,
    }),
  )
  assert_eq(
    error_code(() => {
      ignore(
        @moonrow.parse_csv("id", limits={
          max_rows: -1,
          max_columns: 2,
          max_field_units: 2,
        }),
      )
    }),
    "INVALID_LIMITS",
  )
}

///|
test "literal separator and length-prefix patterns cannot collide in composite keys" {
  let s = "a,b,v\n1:a,b,1\n1,a:b,2\na|b,c,3\na,b|c,4\n😀,中,5\n中,😀,6"
  let r = @moonrow.compare_csv(s, s, { keys: ["a", "b"], ignore: [], })
  assert_eq(r.summary.unchanged, 6)
}

///|
test "deterministic ordering uses lexical UTF-16 order not string length" {
  let a = "id,z,alpha\nb,old,x\naaa,old,x"
  let b = "alpha,id,z\ny,aaa,new\ny,b,new"
  let r = @moonrow.compare_csv(a, b, { keys: ["id"], ignore: [], })
  assert_eq(r.columns, ["alpha", "z"])
  assert_eq(r.changed[0].key, ["aaa"])
  assert_eq(r.changed[0].changes[0].column, "alpha")
  assert_eq(r.summary.changed_cells, 4)
}

///|
test "JSON preserves values and text and Markdown escape active characters" {
  let r = @moonrow.compare_csv("id,v\n1,old", "id,v\n1,<script>|`x`", {
    keys: ["id"],
    ignore: [],
  })
  assert_true(@moonrow.render_json(r).contains("<script>|`x`"))
  let markdown = @moonrow.render_markdown(r)
  assert_true(!markdown.contains("<script>"))
  assert_true(markdown.contains("&#124;"))
  assert_true(markdown.contains("&#96;"))
  let escaped = @moonrow.quote_text("a\u001Bb\u009Bc\u202Ed\n")
  assert_true(!escaped.contains("\u001B"))
  assert_true(!escaped.contains("\u009B"))
  assert_true(!escaped.contains("\u202E"))
  assert_true(escaped.contains("\\n"))
}

///|
test "fixed generated records satisfy permutation and reverse invariants" {
  for seed = 0; seed < 20; seed = seed + 1 {
    let before = StringBuilder()
    let after = StringBuilder()
    let reordered = StringBuilder()
    before.write_string("id,value\n")
    after.write_string("id,value\n")
    reordered.write_string("value,id\n")
    for i = 0; i < 30; i = i + 1 {
      if (i + seed) % 5 != 0 {
        before.write_string("\{i},v\{i}\n")
      }
      if (i + seed) % 7 != 0 {
        after.write_string("\{i},v\{i + (i + seed) % 3}\n")
      }
    }
    for i = 29; i >= 0; i = i - 1 {
      if (i + seed) % 5 != 0 {
        reordered.write_string("v\{i},\{i}\n")
      }
    }
    let options : @moonrow.Options = { keys: ["id"], ignore: [], }
    let r = @moonrow.compare_csv(before.to_string(), after.to_string(), options)
    let same = @moonrow.compare_csv(
      reordered.to_string(),
      after.to_string(),
      options,
    )
    assert_true(r == same)
    let reverse = @moonrow.compare_csv(
      after.to_string(),
      before.to_string(),
      options,
    )
    assert_true(r.added == reverse.removed)
    assert_true(r.removed == reverse.added)
    assert_eq(r.summary.changed, reverse.summary.changed)
    assert_eq(
      r.summary.before_rows,
      r.summary.removed + r.summary.changed + r.summary.unchanged,
    )
    assert_eq(
      r.summary.after_rows,
      r.summary.added + r.summary.changed + r.summary.unchanged,
    )
    for i, row in r.changed {
      assert_eq(row.key, reverse.changed[i].key)
      for j, c in row.changes {
        assert_eq(c.before, reverse.changed[i].changes[j].after)
        assert_eq(c.after, reverse.changed[i].changes[j].before)
      }
    }
  }
}
