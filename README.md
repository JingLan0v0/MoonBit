# MoonRow

**按业务编号比较两份 CSV，准确找出新增、删除和字段变化。**

MoonRow 用 MoonBit 实现解析、主键匹配和报告生成，提供可复用库及离线命令行。适合商品目录、数据库导出和数据处理结果的变更复核。行顺序或列顺序变化不会产生假差异。

## 快速运行

运行已构建的交付包只需要 Node.js 22 或更新版本；本项目实测为 **Node.js 24.14.0**。没有 npm 运行依赖，无需 API 密钥和后台服务。

```text
node bin/moonrow.cjs examples/catalog/before.csv examples/catalog/after.csv --key sku --ignore updated_at
```

预期：新增 A004、删除 A002、A001 的 price 从 `3.00` 改为 `3.50`，A003/A005 不变。

```text
before=4 after=4 added=1 removed=1 changed=1 unchanged=2 changed_cells=1
```

**这个示例的退出码是 1，表示成功发现差异。** 0 表示无差异，2 才是参数或输入错误。

从 Git 仓库取得的源码不包含生成产物，请先按下一节构建。

## 从源码构建

工具链固定为 `0.10.14+7d59c7ec9`，完整环境见 [toolchain.json](toolchain.json)。安装方式参见 [MoonBit 官方下载页](https://www.moonbitlang.cn/download)。

Windows PowerShell 安装固定版本：

```powershell
$env:MOONBIT_INSTALL_VERSION = '0.10.14+7d59c7ec9'
Invoke-WebRequest https://cli.moonbitlang.cn/install/powershell.ps1 -OutFile install-moonbit.ps1
./install-moonbit.ps1
```

Linux 安装固定版本：

```sh
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh -o install-moonbit.sh
bash install-moonbit.sh '0.10.14+7d59c7ec9'
export PATH="$HOME/.moon/bin:$PATH"
```

安装后确认 `moon version --all` 可运行，在项目根目录执行：

```text
node scripts/build.mjs
node bin/moonrow.cjs --help
node scripts/verify.mjs
```

构建生成 `dist/moonrow.cjs`。构建脚本优先使用上级目录 `.tools/moon` 中的本地工具链，否则使用 PATH 中的 `moon`。项目没有额外 Mooncakes 或 npm 依赖，不需要 `npm install`。Windows 当前工作区还提供 `scripts/moon.ps1` 调用本地工具链。

## 常用命令

```text
node bin/moonrow.cjs before.csv after.csv --key id
node bin/moonrow.cjs before.csv after.csv --key sku --key warehouse --ignore updated_at
node bin/moonrow.cjs before.csv after.csv --key id --format json
node bin/moonrow.cjs before.csv after.csv --key id --format markdown
node bin/moonrow.cjs --version
```

可以将标准输出重定向保存报告。错误只写标准错误，不会混入 JSON。可用 `npm link` 自行建立本机 `moonrow` 命令，但这不是运行的前提；当前未发布 npm 包。

## 比较规则

- UTF-8 CSV、非空唯一表头；支持 BOM、LF/CRLF、中文、emoji、引号中的逗号/双引号/换行。
- 显式指定单列或组合主键；空主键、重复主键直接报错并指出记录。
- 原样比较字符串：`001` 与 `1` 不同，不自动推断数字、日期或空值。
- 非忽略列的列名集合必须相同；允许列重排。忽略列可以只存在于一侧，但至少存在一侧且不能是主键。
- 至少保留一个非主键比较列。主键变化表示一条删除加一条新增。
- 每个文件最多 10 MiB / 50,000 条数据记录 / 100 列；每字段最多 262,144 个 UTF-16 单元。内存内处理，不面向无限大文件。
- 报告排序固定；JSON 保留字符串原值；文本和 Markdown 转义特殊字符以便安全显示。

完整约定见 [限制说明](docs/limitations.md)。

## 库调用与结构

核心包为 `JingLan0v0/moonrow`。独立示例包：

```text
moon run src/examples/library_usage --target js
```

详细接口见 [API 文档](docs/api.md) 和 [生成的接口](src/pkg.generated.mbti)，实现取舍见 [架构说明](docs/architecture.md)。目前尚未发布 Mooncakes，不能用未发布的包版本安装。

## 测试与验收

`node scripts/verify.mjs` 执行静态检查、MoonBit 测试、格式检查、公共接口生成、正式构建、独立库示例和实际进程测试。固定种子的独立参考实现核对完整 JSON，另覆盖错误输入、UTF-8、组合主键、报告转义和所有默认限制边界。

验证证据写入本机 `artifacts/integration-results.json`，不把临时大文件提交到仓库。[验收说明](docs/acceptance.md) 记录本地复现和 Linux / Windows 远程通过的证据。

GitHub Actions 已配置 Windows / Linux 检查；当前状态必须以 [Actions 实际运行](https://github.com/JingLan0v0/MoonBit/actions) 为准，不能仅凭配置文件宣称通过。

## 开源与参赛

原创实现，Apache-2.0 许可证。使用 MoonBit 标准库和 Node.js 宿主，参考来源与许可见 [第三方说明](THIRD_PARTY_NOTICES.md)，AI 辅助说明见 [docs/ai-assistance.md](docs/ai-assistance.md)。

本项目拟参加 2026 MoonBit 九月黑客松“数据处理”方向。参赛申报、官方审核、验收与支持发放状态见 [实施交接](docs/progress.md)。代码完成不代表比赛已经通过。

遇到问题请在仓库 Issues 中附上最小虚构样例、命令、版本、预期与实际输出；不要上传含个人信息的原始业务表。
