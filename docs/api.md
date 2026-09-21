# MoonBit 库接口

正式公共签名见根目录 `pkg.generated.mbti`，由 `moon info --target js` 生成。

## 调用

在调用包的 `moon.pkg` 中导入：

```text
import { "JingLan0v0/moonrow" @moonrow }
```

本仓库的 `examples/library_usage` 是独立调用包，实际执行：

```text
moon run examples/library_usage --target js
```

当前尚未发布 Mooncakes，不能假定 `moon add JingLan0v0/moonrow` 已经可用。外部使用者可先检出源码，参照这个独立包调用。

## 核心接口

| 接口 | 用途 |
| --- | --- |
| `compare_csv(before, after, options, limits?)` | 一步解析与比较，返回 `DiffResult`，失败抛出 `MoonRowError` |
| `parse_csv(text, side?, limits?)` | 解析和校验表头/列数；返回内部不可修改的 `Table` |
| `compare(before_table, after_table, options)` | 复用已经解析的表，校验并比较 |
| `Table::headers()` / `row_count()` | 获取表头副本和数据记录数量 |
| `render_json` / `render_text` / `render_markdown` | 将同一个结果转换为报告 |
| `render_diagnostic` | 格式化错误，转义错误消息中的控制字符 |
| `default_limits()` | 默认资源限制 |

`Options` 有 `keys: Array[String]` 与 `ignore: Array[String]`。至少一个主键和一个非主键比较列。表头、键值和数据原值精确区分空格与大小写。

库接收 MoonBit 字符串，不执行文件访问。调用者负责严格 UTF-8 解码和输入字节预算；CLI 已实现这两项。库的 `Limits` 在解析中限制记录数、列数和字段 UTF-16 单元数。用户自定义较大限制会增加内存占用。

## JSON 报告 v1

- `schema_version`: `1`。
- `keys`: 使用者指定的主键列顺序。
- `columns`: 参与比较的非主键列，按 UTF-16 字典序排列。
- `summary`: `before_rows`、`after_rows`、`added`、`removed`、`changed`、`unchanged`、`changed_cells`、`has_diff`。
- `added` / `removed`: 每项有 `key` 字符串数组、`fields` 数组。后者每项为 `column` 和 `value`，包括主键列但不包括忽略列。
- `changed`: 每项有 `key` 和 `changes`；每个变更包含 `column`、`before`、`after`，值都是字符串。

所有结果列表按主键组成字符串逐项的 UTF-16 字典序排列，字段按列名字典序排列。`10` 排在 `2` 前；不做本地语言排序或数字排序。无时间戳、随机标识等影响可复现性的字段。

新增/删除/修改/未变化统计的是记录数；`changed_cells` 是修改字段数。不输出未变化记录的完整数据。

## 错误模型

`MoonRowError(Diagnostic)` 包含 `code`、`side`、`record`、`line`、`column`、`message`。`record` 是从 1 开始的 CSV 逻辑记录号，表头为 1；错误消息中的冲突记录也采用同一编号。物理行列从 1 开始，列按 Unicode 字符计数。未知或不适用的位置为 0。多行引号字段导致物理行和逻辑记录不同。

| 错误类别 | 错误码 |
| --- | --- |
| CSV 语法 | CSV_BARE_CR、CSV_QUOTE、CSV_AFTER_QUOTE、CSV_UNCLOSED |
| 表格形状 | EMPTY_INPUT、EMPTY_HEADER、DUPLICATE_HEADER、ROW_WIDTH |
| 比较配置 | MISSING_KEY、DUPLICATE_KEY_OPTION、KEY_COLUMN、IGNORE_KEY、IGNORE_COLUMN、DUPLICATE_IGNORE、NO_VALUE_COLUMNS、SCHEMA_MISMATCH |
| 数据标识 | EMPTY_KEY、DUPLICATE_KEY |
| 库资源限制 | INVALID_LIMITS、LIMIT_ROWS、LIMIT_COLUMNS、LIMIT_FIELD |
| CLI / 文件 | USAGE、IO_READ、IO_FILE、UTF8、LIMIT_BYTES |

重复主键报告同侧的当前记录号和第一次出现的记录号，避免悄悄覆盖数据。所有错误终止本次比较，不输出可能被误当成成功的半份报告。
