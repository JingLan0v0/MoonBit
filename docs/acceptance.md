# 本地验收与提交说明

## 状态

2026-09-21：Windows 本地与干净目录复现全部通过，公开仓库已同步，Linux / Windows 远程 CI 均已通过。工程已具备验收演示条件；这不是主办方的通过证明。章程已读取；Mooncakes 发布、人工申报书、报名、入群和官方验收尚需完成或确认。

最新远程验证：[GitHub Actions](https://github.com/JingLan0v0/MoonBit/actions/runs/35606815890) 和 [结果快照](verification-engineering-ci.json)，对应 ac7747c，Windows/Linux 均成功。独立解压 Mooncakes 本地包后完整验证通过，见 [干净包证据](verification-engineering-windows.json)。后续证据文档提交不改变被测源码；旧版本结果仍保留在 verification-ci.json。

## 一次复现

1. 获取源码，安装 `toolchain.json` 对应的 MoonBit 和 Node.js。
2. 执行 `node scripts/verify.mjs`，成功结束为退出码 0。
3. 查看 `artifacts/integration-results.json`、`artifacts/catalog.json` 和两种可读报告。
4. 独立运行商品主样例，检查一增一删一改两条不变，以及成功差异的退出码 1。

生成物不进入 Git 源码树；运行脚本会生成 `dist` 和 `artifacts`。公开源码位于 https://github.com/JingLan0v0/MoonBit 。便携交付包另包含已构建的 `dist/moonrow.cjs`，只需 Node.js 即可演示。

## 证据对应表

| 要求 | 证据 |
| --- | --- |
| MoonBit 主实现 | `src/*.mbt`、`src/cli/args.mbt`、`src/cmd/main/main.mbt` |
| 可复用库 | `src/pkg.generated.mbti`、`src/examples/library_usage`、`docs/api.md` |
| 可运行示例 | `examples/catalog`、README 命令、`artifacts/catalog.*` |
| 必要测试 | `src/core_test.mbt`、`src/validation_test.mbt`、`src/cli/args_test.mbt`、`tests/integration.mjs` |
| 可复现 | `toolchain.json`、构建/验证脚本、`docs/verification-windows.json` |
| 可维护和可解释 | `docs/architecture.md`、`limitations.md`、`ai-assistance.md` |
| 开源合规 | LICENSE、NOTICE、THIRD_PARTY_NOTICES.md |
| 过程记录 | 本地与远程均保留真实阶段 commits、CHANGELOG |
| 公开仓库/Issues/PR | 仓库已公开，主代码已同步；后续实际需求和缺陷再形成 Issues/PR，不伪造历史 |
| 申报/入群/支持 | 需要实际回执和用户确认，不能从代码推定 |

## 五分钟演示

- 0:00—0:40：介绍业务编号匹配，展示两个输入文件的记录重排。
- 0:40—1:40：执行商品样例；指出 A004 新增、A002 删除、A001 price 变化，另两条不变。
- 1:40—2:20：同一文件比较，展示零差异与退出码 0。
- 2:20—3:00：运行重复主键样例，展示错误码、冲突记录位置和退出码 2。
- 3:00—4:00：展示 JSON/Markdown、独立库调用与测试记录。
- 4:00—5:00：说明核心 MoonBit / 宿主 I/O 的分工、资源限制和许可证。

## 本期仍待核实

本轮确认 Mooncakes 发布、人工撰写的一页 Markdown、至少三个场景、不少于 10 个有效提交为要求。日期存在主页/表单 9 月 30 日与章程 9 月 24 日冲突，须以赛事群确认；最终验收入口和补件安排也待通知。详见 `competition.md`。
