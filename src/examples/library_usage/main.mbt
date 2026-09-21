///|
fn main {
  try {
    let result = @moonrow.compare_csv("id,value\n1,old", "value,id\nnew,1", {
      keys: ["id"],
      ignore: [],
    })
    println(@moonrow.render_json(result))
  } catch {
    @moonrow.MoonRowError(d) => println(@moonrow.render_diagnostic(d))
  }
}
