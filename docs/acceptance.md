# 本地验收与提交说明

## 状态

2026-09-21：Windows 本地与干净目录复现全部通过，公开仓库已同步，Linux / Windows 远程 CI 均已通过。工程已具备验收演示条件；这不是主办方的通过证明。正式章程复核、报名、入群和官方验收尚需完成或确认。

远程验证记录：[GitHub Actions](https://github.com/JingLan0v0/MoonBit/actions/runs/35585337068) 和 [真实结果快照](verification-ci.json)。验证对应 1d6a672；后续材料更新不改变产品算法。

## 一次复现

1. 获取源码，安装 `toolchain.json` 对应的 MoonBit 和 Node.js。
2. 执行 `node scripts/verify.mjs`，成功结束为退出码 0。
3. 查看 `artifacts/integration-results.json`、`artifacts/catalog.json` 和两种可读报告。
4. 独立运行商品主样例，检查一增一删一改两条不变，以及成功差异的退出码 1。

生成物不进入 Git 源码树；运行脚本会生成 `dist` 和 `artifacts`。公开源码位于 https://github.com/JingLan0v0/MoonBit 。便携交付包另包含已构建的 `dist/moonrow.cjs`，只需 Node.js 即可演示。

## 证据对应表

| 要求 | 证据 |
| --- | --- |
| MoonBit 主实现 | 根目录 `.mbt`、`cli/args.mbt`、`cmd/main/main.mbt` |
| 可复用库 | `pkg.generated.mbti`、`examples/library_usage`、`docs/api.md` |
| 可运行示例 | `examples/catalog`、README 命令、`artifacts/catalog.*` |
| 必要测试 | `core_test.mbt`、`validation_test.mbt`、`cli/args_test.mbt`、`scripts/integration.mjs` |
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

正式章程及报名表完整字段、截止具体时分与时区、验收入口、补件期、是否需发布 Mooncakes/视频/额外规模要求、150/350 元适用单位与支付流程。详见 `competition.md`，不使用旧赛事规则替代。
