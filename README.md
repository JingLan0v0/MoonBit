# MoonRow

[![Verify MoonRow](https://github.com/JingLan0v0/MoonBit/actions/workflows/ci.yml/badge.svg)](https://github.com/JingLan0v0/MoonBit/actions/workflows/ci.yml)

**按业务主键比较两份 CSV，找出新增、删除和字段变化。**

MoonRow 是用 MoonBit 编写的可复用数据差异库和离线命令行工具。它按编号对应记录，行列重排不会产生假差异；组合主键、重复键诊断和精确字符串比较让业务差异可以被程序和人工共同复核。

当前版本为 **0.1.0**，支持 **JS 后端**，已发布到 [Mooncakes](https://mooncakes.io/docs/JingLan0v0/moonrow)；npm 尚未发布。源码可构建，也可生成便携包。

## 适用场景

| 使用者与问题 | 匹配方式 | 可复现成果 |
| --- | --- | --- |
| 运营核对两次商品目录，检查上架、下架和价格修改 | 商品编号，忽略导出时间 | 新增 1、删除 1、修改 1、未变化 2 |
| 仓管核对多仓库存，同一商品可能出现在多个仓库 | 商品编号＋仓库 | 区分 A001/North 与 A001/South，只报告实际变化 |
| 开发者复核部署配置，前导零变化可能影响业务 | 服务＋环境 | 明确报告字符串 `001` → `1` |

输入、命令、预期结果及使用边界见 [三个完整示例](examples/README.md)。样例全部为虚构数据，并由集成测试验证。

## 五分钟运行

需要 Node.js **22 或更新版本**（CI 固定为 **24.14.0**）和 MoonBit **0.10.14+7d59c7ec9**。完整版本记录见 [toolchain.json](toolchain.json)。项目无额外 npm 或 Mooncakes 依赖，无需 `npm install`、API 密钥或后台服务。

### 1. 获取源码与工具链

```sh
git clone https://github.com/JingLan0v0/MoonBit.git
cd MoonBit
```

MoonBit 官方安装入口：[下载页面](https://www.moonbitlang.cn/download)。以下命令保存并运行官方安装脚本。

Windows PowerShell：

```powershell
$env:MOONBIT_INSTALL_VERSION = '0.10.14+7d59c7ec9'
Invoke-WebRequest https://cli.moonbitlang.cn/install/powershell.ps1 -OutFile "$env:TEMP/install-moonbit.ps1"
& "$env:TEMP/install-moonbit.ps1"
```

Linux：

```sh
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh -o /tmp/install-moonbit.sh
bash /tmp/install-moonbit.sh '0.10.14+7d59c7ec9'
export PATH="$HOME/.moon/bin:$PATH"
```

安装后重新打开终端，确认 `node --version` 和 `moon version --all` 可用。

### 2. 构建并比较

```sh
node scripts/build.mjs
node bin/moonrow.cjs examples/catalog/before.csv examples/catalog/after.csv --key sku --ignore updated_at
```

预期摘要：

```text
before=4 after=4 added=1 removed=1 changed=1 unchanged=2 changed_cells=1
```

明细为新增 A004、删除 A002、A001 的 price 从 `3.00` 变为 `3.50`，A003/A005 不变。
**该命令返回 1，表示成功发现差异。**

已取得便携交付包的用户只需要 Node.js，可直接运行比较命令或在 Windows 双击 `打开示例.cmd`。GitHub 源码不含 `dist/`，需要先构建；当前没有公开的 Release 下载地址。

### 3. 完整验证

```sh
node scripts/verify.mjs
```

依次执行静态检查、MoonBit 单元测试、格式检查、公共接口生成、发布构建、独立库调用、实际进程测试及 Mooncakes 本地包检查。整个验证命令成功时返回 0。

## 命令与退出码

```text
moonrow BEFORE.csv AFTER.csv --key COLUMN [options]
```

通过 `node bin/moonrow.cjs` 调用，无需全局安装；可选 `npm link` 建立本机 `moonrow` 命令。

| 参数 | 说明 |
| --- | --- |
| `--key COLUMN` | 必填，可重复，顺序决定组合主键的顺序 |
| `--ignore COLUMN` | 可重复，忽略非主键列，例如导出时间 |
| `--format text/json/markdown` | 默认 text；只能指定一次 |
| `--` | 后续参数作为文件路径处理，适合以短横线开头的文件名 |
| `--help` / `-h` | 显示帮助 |
| `--version` | 显示版本 |

| 退出码 | 含义 | 自动化处理 |
| --- | --- | --- |
| 0 | 比较成功，无差异；或帮助／版本命令成功 | 可继续 |
| 1 | 比较成功，发现差异 | 按业务决定是否中断 |
| 2 | 参数、输入格式、主键、资源限制或读文件错误 | 先处理错误 |

报告仅输出到标准输出，诊断仅输出到标准错误。不会修改输入文件。

```sh
node bin/moonrow.cjs examples/inventory/before.csv examples/inventory/after.csv --key sku --key warehouse --ignore exported_at --format json > inventory-diff.json
node bin/moonrow.cjs examples/catalog/before.csv examples/catalog/after.csv --key sku --ignore updated_at --format markdown > catalog-diff.md
```

路径含空格时加引号。Windows PowerShell 5.1 重定向可能产生 UTF-16 文件；需要保存 UTF-8 报告时使用 PowerShell 7 或显式指定输出编码。

## 库接口

模块导入路径仍是 `JingLan0v0/moonrow`，`src/` 是物理源码目录，不是导入路径的一部分。

在其他 MoonBit 项目中安装已发布版本：

```sh
moon add JingLan0v0/moonrow@0.1.0
```

```text
import { "JingLan0v0/moonrow" @moonrow }
```

调用 `compare_csv(before, after, { keys: ["id"], ignore: [] })` 得到 `DiffResult`，失败抛出带诊断信息的 `MoonRowError`。核心库接收字符串，不访问文件或网络。

完整可运行调用包位于 [src/examples/library_usage](src/examples/library_usage)：

```sh
moon run src/examples/library_usage --target js
```

详见 [API 与 JSON 结构](docs/api.md)、[生成接口](src/pkg.generated.mbti)和[发布验证](docs/publishing.md)。

## 比较语义与边界

- UTF-8、逗号分隔、非空且唯一的表头。支持文件头 BOM、LF/CRLF、中文、emoji、引号内逗号／双引号／换行。
- 表头、主键和值都精确区分大小写和空格。`001` 与 `1`、`1.0` 与 `1.00` 不相同。
- 至少一列主键，组合键各部分不可为空；重复键直接报错，不选择第一条或最后一条。
- 除忽略列外，两侧列名集合必须相同。忽略列可以只存在一侧，但不可是主键；至少保留一个非主键比较列。
- 主键变化视为删除和新增。差异按键确定排序，便于回归核对。
- 默认每文件上限：10 MiB、50,000 条数据记录、100 列；每字段 262,144 个 UTF-16 单元。全部在内存中处理，内存占用大于原文件大小。
- 不支持 `.xlsx`、GBK、stdin、数据库直连、远程 URL、数值容差、自动类型推断或补丁应用。
- CSV 解析、主键索引、比较与报告由 MoonBit 实现；Node.js 只承担宿主读写、编码和进程接口。

完整规则见 [限制说明](docs/limitations.md)。这是专门的数据快照比较工具，不声称替代通用表格分析库。

## 常见问题

| 现象 | 原因与处理 |
| --- | --- |
| `MoonRow is not built yet` | 源码未构建，先运行 `node scripts/build.mjs` |
| CI／终端显示退出码 1 | 可能是正常差异；阅读报告，不要把 1 当成输入错误 |
| `DUPLICATE_KEY` | 主键不唯一，检查数据或增加 `--key` 组成业务唯一键 |
| `SCHEMA_MISMATCH` | 两份文件的非忽略列不一致；核对导出结构或明确忽略无关列 |
| `UTF8` | 文件不是合法 UTF-8，需要在来源工具中重新导出或转换 |
| `LIMIT_*` | 超过声明的资源边界；拆分业务数据或使用适合该规模的工具 |
| 安装工具链下载超时 | 网络下载问题；稍后重试官方安装入口。CI 使用隔离安装和备用官方镜像 |

## 仓库结构

```text
src/                       MoonBit 可复用核心及包内单元测试
  cli/                     参数解析与报告格式选择
  cmd/main/                命令编排 + 独立 host.mbt 系统适配
  examples/library_usage/  独立库调用示例
bin/                       Node 命令启动器
examples/                  三组业务 CSV 与预期结果
scripts/                   构建、工具链、校验、交付打包
tests/                     真实进程测试与独立参考结果
docs/                      API、架构、限制、发布与比赛状态
.github/                   双平台 CI、缺陷及 PR 模板
```

MoonBit 单元测试遵循工具链要求，与被测包同目录；跨进程测试在 `tests/`。`dist/`、`_build/`、`artifacts/` 是生成目录，不提交源码仓库。

## 测试、维护与许可

验证覆盖 18 组 MoonBit 测试、13 组集成场景／87 次真实进程调用，其中包含 25 组固定种子数据双向独立对照，以及文件大小、字段长度、行列数的边界检查。最新云端结果以 [GitHub Actions](https://github.com/JingLan0v0/MoonBit/actions) 为准，历史记录附带被测提交编号。

- [架构与设计取舍](docs/architecture.md)
- [贡献流程](CONTRIBUTING.md)
- [验收复现](docs/acceptance.md)
- [比赛要求与当前缺口](docs/competition.md)
- [开发交接状态](docs/progress.md)

原创实现，采用 [Apache-2.0](LICENSE)；参考来源见 [第三方说明](THIRD_PARTY_NOTICES.md)，AI 使用情况见 [AI 辅助说明](docs/ai-assistance.md)。问题反馈请附最小虚构样例，勿上传真实客户数据。

参赛路径为月度新项目，选题为数据处理。工程通过不代表官方验收通过；**正式申报书须由参赛者本人撰写、确认并提交**，仓库历史 AI 草稿不能替代它。Mooncakes 0.1.0 已发布，用户已确认完成飞书报名；入群、审核及支持发放仍以赛事方真实回执为准。
