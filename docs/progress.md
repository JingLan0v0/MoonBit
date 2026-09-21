# 实施交接

## 当前授权和目标

2026-09-21，用户已明确授权按方案开始项目。用户提供仓库 https://github.com/JingLan0v0/MoonBit.git 。优先争取 150 + 350 元月度支持，不扩大为冲奖项目。

## 环境

- 工具链位于工作区上级 `.tools/moon`，没有修改系统 PATH。
- moon 0.1.20260920 (914d7da)，moonc v0.10.14+7d59c7ec9；Node.js v24.14.0。
- 官方 SHA256 清单中的 16 个二进制文件均已校验。
- 本机仅验证 JS 后端；标准库 JS bundle 已成功生成。

## 已完成

- CSV 解析、表结构校验、组合主键、精确比较、确定排序、三种报告、CLI 和独立库调用示例。
- 18 组 MoonBit 测试通过；11 组集成场景、85 次实际进程验证通过；25 组固定种子数据双向对照独立参考结果。
- 默认文件字节数、行数、列数和 UTF-16 字段限制的低于/等于/超过边界通过。
- `node scripts/verify.mjs` 已在 Windows x64 / Node.js 24.14.0 完整通过。
- 已从 fea341c 的 Git 源码导出到独立干净目录重新构建，18 组 MoonBit 测试与 11 组/85 次进程验证再次全部通过，确认无未提交文件依赖。
- 固定版本官方校验值与本机 16 个二进制文件均一致，归档地址已验证可用。
- 中文 README、API/架构/限制、AI 辅助和验收文档已形成；一页申报 PDF 已生成并渲染检查。
- 已同步公开仓库 main，保留全部真实阶段提交。GitHub Linux / Windows CI 均已通过，远程实证见下方链接及 `verification-ci.json`。
- 本地阶段记录：ae13933 初始方案与项目；e7f099d 核心实现；07c6bcf 独立验证和边界检查；后续提交以 `git log` 为准。

## 外部待办

- 用户已将仓库改为 Public；GitHub API 确认公开。分支为 main，origin 指向用户提供的仓库。
- GitHub 网页登录已成功；初次正常推送 609b140 并关联 origin/main。随后 Git 传输不稳定，通过 GitHub 官方 Git 数据接口同步原始提交，逐一验证 blob/tree/commit 哈希相同，仅快进 main；未改写历史。正常连接恢复后继续普通 push，不使用 force。
- 正式章程本轮仍未读到正文。报名、入群、申报审核状态待用户确认；没有替用户发消息或提交表单。
- 最新 CI 实证：https://github.com/JingLan0v0/MoonBit/actions/runs/35585337068 ，对应 1d6a67279963198953f8142b096c21ec77920007。Linux 与 Windows 的完整验证、生成接口检查、证据上传均已通过。后续仅交付材料更新时使用 `[skip ci]`，避免无意义重跑。
- 首次运行 https://github.com/JingLan0v0/MoonBit/actions/runs/35584063766 的 Windows 安装标准库超时，未进入产品测试。增加固定版本、双官方镜像、超时重试、二进制校验和仅 JS 标准库打包后，已在上述新运行验证解决。
- 用户需要填写真实报名信息、确认入群，并在申报通过/验收通过/到账时提供真实回执。

## 下一步

协助填写一页说明和报名资料，补核验正式章程，确认入群与报名回执。主体功能不应继续无目的扩张。本地测试证据见 `docs/verification-windows.json` 与 `docs/verification-clean-windows.json`；完整复现入口见 README。交付压缩包可用 `scripts/package.ps1` 重建。

## 恢复入口

先读本文件，再读 `project-plan.md` 与 `competition.md`；检查实际 Git 状态和验证日志再继续。计划与实测分开记录。用户开工授权优先于旧方案的“暂不开发”历史描述。
