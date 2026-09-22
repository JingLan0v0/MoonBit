# 实施交接

## 目标与授权

用户授权继续完善项目工程化、目录分类、README 和参赛材料准备。目标为月度新项目 150+350 元支持，不能承诺审核通过。仓库 https://github.com/JingLan0v0/MoonBit ，main 分支，已公开；GitHub 已登录。

## 当前工程状态

2026-09-21 工程整理：源码迁入 src，公共导入路径仍为 JingLan0v0/moonrow；系统适配在 src/cmd/main/host.mbt，集成验证在 tests。三组业务例子为商品目录、多仓库存、部署配置。18 组 MoonBit 测试及 13 组集成场景/87 次进程调用、Mooncakes 本地打包检查均已通过。已从实际发布 ZIP 独立解压并完整复现，证据见 verification-engineering-windows.json。过程中发现忽略规则未随包分发，已在 ac7747c 修复并通过干净包复验。

工程版本 ac7747cb096660495f6e41cae09436ec5a645e1a 的 Windows/Linux 云端检查均成功：https://github.com/JingLan0v0/MoonBit/actions/runs/35606815890 ，证据见 verification-engineering-ci.json。后续文档证据提交不改变被测源码。

2026-09-22 发布完成：使用 GitHub 注册并登录 Mooncakes，账号为 `JingLan0v0`；`moon publish --dry-run` 通过，`moon publish` 返回 200 OK。公开注册表可查询 `JingLan0v0/moonrow@0.1.0`，校验和为 `41c2362ecdaf022cf7a0d3534744f32d7a60bd0c512e1c3d79d7dfe564048368`。全新项目通过固定版本安装、JS 检查及公共 API 调用，证据见 verification-registry.json。用户已确认完成飞书报名。

## 工具与复现

Node.js 24.14.0、MoonBit 0.10.14+7d59c7ec9，工作区上级 .tools/moon 为已校验工具链。没有修改全局 PATH。入口 node scripts/verify.mjs；生成 artifacts/integration-results.json、artifacts/package-check.json 和 _build/publish 包。node scripts/build.mjs 构建 dist/moonrow.cjs。交付由 scripts/package.ps1 从干净 Git 提交生成。

## 规则核验的重要更正

本轮已读取官网链接的正式章程和实际表单，详见 competition.md。此前“无法读取、Mooncakes 可能不是必需”的记录已经过时。

- Mooncakes 发布要求已完成；0.1.0 已公开并通过全新项目安装验证。后续版本不得重复使用 0.1.0。
- 正式申报书必须由参赛者人工撰写、Markdown、一页以内，并包含至少三个完整场景。原 AI 生成 Markdown/PDF 已移入 docs/archive 并排除注册表包，不能直接提交。
- 仓库要求不少于 10 个有效提交，不得凑数。当前真实提交数量用 git rev-list --count HEAD 查看，有效性仍由主办方审核。
- 官网和表单为 9 月 30 日，章程仍写 9 月 24 日，并指向赛事群口径。未确认前按较早时间准备，旧计划 9 月 28 日不可继续依赖。
- 用户已确认完成飞书报名；入群、参赛者实际理解、官方审核回执和到账仍未确认。个人材料不要进入公开仓库。

## 历史实证

旧实现 1d6a672 的 Windows/Linux CI 均通过：https://github.com/JingLan0v0/MoonBit/actions/runs/35585337068 ，快照 docs/verification-ci.json。早期干净源码验证见 verification-clean-windows.json。新验证应单独保存并附被测提交。

## 远程同步

首次 Git push 成功；之后 Git 传输偶发超时，工作区外层 .tools/sync-github.ps1 可通过官方 Git 数据接口同步现有提交，逐一核对 blob/tree/commit SHA，且仅快进分支。Git 凭据在凭据管理器；不要输出令牌或改写历史。

## 恢复顺序

先读本文件、competition.md、README，检查 git status、最新提交、真实 CI 和 Mooncakes 公开版本；再处理赛事群、审核反馈或后续发布。不要重复发布 0.1.0，也不要把模板当作真实 Issues/PR 记录。
