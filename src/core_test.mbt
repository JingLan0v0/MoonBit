///|
test "catalog fixture produces one addition removal and change" {
  let before = "sku,name,price,updated_at\nA001,苹果,3.00,old\nA002,香蕉,4.00,old\nA003,梨,5.00,old\nA005,葡萄,8.00,old\n"
  let after = "sku,name,price,updated_at\nA005,葡萄,8.00,new\nA003,梨,5.00,new\nA001,苹果,3.50,new\nA004,橙子,6.00,new\n"
  let r = @moonrow.compare_csv(before, after, {
    keys: ["sku"],
    ignore: ["updated_at"],
  })
  assert_eq(r.summary.added, 1)
  assert_eq(r.summary.removed, 1)
  assert_eq(r.summary.changed, 1)
  assert_eq(r.summary.unchanged, 2)
  assert_eq(r.summary.changed_cells, 1)
  assert_eq(r.added[0].key, ["A004"])
  assert_eq(r.changed[0].changes[0].before, "3.00")
  assert_eq(r.changed[0].changes[0].after, "3.50")
}

///|
test "CSV supports quoted newlines escaped quotes BOM and unicode" {
  let text = "\uFEFFid,v\r\n1,\"hello,\"\"世界😀\"\"\r\nnext\"\r\n"
  let r = @moonrow.compare_csv(text, text, { keys: ["id"], ignore: [], })
  assert_eq(r.summary.unchanged, 1)
  assert_eq(r.summary.has_diff, false)
}

///|
test "rows and columns are aligned by name and keys" {
  let r = @moonrow.compare_csv("id,v\n2,b\n1,a", "v,id\na,1\nb,2", {
    keys: ["id"],
    ignore: [],
  })
  assert_eq(r.summary.unchanged, 2)
}

///|
test "composite key delimiter collision does not merge records" {
  let s = "a,b,v\na|b,c,1\na,b|c,2"
  let r = @moonrow.compare_csv(s, s, { keys: ["a", "b"], ignore: [], })
  assert_eq(r.summary.unchanged, 2)
}
