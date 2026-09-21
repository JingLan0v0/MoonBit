///|
test "help version repeated keys format and positional separator" {
  assert_true(@cli.parse_args(["--help"]) is Help)
  assert_true(@cli.parse_args(["--version"]) is Version)
  let cmd = @cli.parse_args([
    "--key", "sku", "--key", "store", "--ignore", "stamp", "--format", "json", "--",
    "-old.csv", "new.csv",
  ])
  guard cmd is Compare(c) else { fail("expected comparison") }
  assert_eq(c.before, "-old.csv")
  assert_eq(c.options.keys, ["sku", "store"])
  assert_true(c.format is Json)
}

///|
test "usage errors are detected before file operations" {
  for
    args in [
      [],
      ["a", "b"],
      ["a", "b", "--key"],
      ["a", "b", "--key", "--format"],
      ["a", "b", "--wat"],
      ["a", "b", "--key", "id", "--format", "yaml"],
      ["a", "b", "--key", "id", "--format", "json", "--format", "text"],
    ] {
    let bad = try {
      ignore(@cli.parse_args(args))
      false
    } catch {
      _ => true
    }
    assert_true(bad)
  }
}
