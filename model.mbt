///|
/// Resource limits apply while parsing, before unbounded intermediate growth.
pub(all) struct Limits {
  max_rows : Int
  max_columns : Int
  max_field_units : Int
} derive(Eq, ToJson)

///|
pub fn default_limits() -> Limits {
  { max_rows: 50000, max_columns: 100, max_field_units: 262144, }
}

///|
pub(all) struct Diagnostic {
  code : String
  side : String
  record : Int
  line : Int
  column : Int
  message : String
} derive(Eq, ToJson)

///|
pub(all) suberror MoonRowError {
  MoonRowError(Diagnostic)
}

///|
fn fail(
  code : String,
  side : String,
  message : String,
  record? : Int = 0,
  line? : Int = 0,
  column? : Int = 0,
) -> Unit raise MoonRowError {
  raise MoonRowError({ code, side, record, line, column, message, })
}

///|
/// Parsed CSV. Record numbers are 1-based CSV records, including the header.
/// Table construction is private; callers obtain validated shape through parse_csv.
struct Table {
  headers : Array[String]
  rows : Array[Array[String]]
}

///|
pub fn Table::headers(self : Table) -> Array[String] {
  self.headers.copy()
}

///|
pub fn Table::row_count(self : Table) -> Int {
  self.rows.length()
}

///|
pub(all) struct Options {
  keys : Array[String]
  ignore : Array[String]
} derive(Eq, ToJson)

///|
pub(all) struct FieldValue {
  column : String
  value : String
} derive(Eq, ToJson)

///|
pub(all) struct RowData {
  key : Array[String]
  fields : Array[FieldValue]
} derive(Eq, ToJson)

///|
pub(all) struct CellChange {
  column : String
  before : String
  after : String
} derive(Eq, ToJson)

///|
pub(all) struct RowChange {
  key : Array[String]
  changes : Array[CellChange]
} derive(Eq, ToJson)

///|
pub(all) struct Summary {
  before_rows : Int
  after_rows : Int
  added : Int
  removed : Int
  changed : Int
  unchanged : Int
  changed_cells : Int
  has_diff : Bool
} derive(Eq, ToJson)

///|
pub(all) struct DiffResult {
  schema_version : Int
  keys : Array[String]
  columns : Array[String]
  summary : Summary
  added : Array[RowData]
  removed : Array[RowData]
  changed : Array[RowChange]
} derive(Eq, ToJson)

///|
pub fn version() -> String {
  "0.1.0"
}
