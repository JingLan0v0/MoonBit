# Mooncakes 发布与交付

## 当前状态

`JingLan0v0/moonrow@0.1.0` 已于 2026-09-22 发布到 [Mooncakes](https://mooncakes.io/docs/JingLan0v0/moonrow)。注册表查询返回版本 0.1.0、Apache-2.0、仓库链接及校验和；随后在全新项目中通过 `moon add JingLan0v0/moonrow@0.1.0` 安装，`moon check --target js` 和公共 `compare_csv` 调用均成功。可复核记录见 `verification-registry.json`。

## 本地发布检查

```sh
node scripts/verify.mjs
```

完整检查包含 `scripts/check-package.mjs`：验证模块、CLI 和 Node 包版本一致，检查包中必需源码与示例，排除生成文件及历史申报附件，然后执行 `moon package` 生成本地包。当前版本生成 `_build/publish/JingLan0v0-moonrow-0.1.0.zip`。

`.moonignore` 管理 Mooncakes 包内容。它会替代同目录 `.gitignore` 的发布规则，因此显式重复生成物排除规则。必要源码、测试、示例和开发脚本仍保留。

## 首次实际发布记录

1. 使用 GitHub 注册并确认 Mooncakes 用户名为 `JingLan0v0`。
2. `moon publish --dry-run` 服务端返回预检成功。
3. `moon publish` 返回 `200 OK`，随后公开注册表查询成功。
4. 在全新 MoonBit 项目中安装固定版本并调用公共接口，得到一条字段变化的正确 JSON 报告。

版本 0.1.0 已存在，不要重复发布同一版本。后续发布必须先更新 `moon.mod`、CHANGELOG 和相关文档，再完成同样的预检、正式发布与全新安装验证。认证文件只保存在本机工具目录，不进入仓库。

## Git 源码与便携包

`scripts/package.ps1` 从干净 Git 提交导出源码包，并构建包含 CLI 产物的便携包。输出 `delivery.json` 记录源提交及产物 SHA256，`SHA256.json` 记录压缩包校验值。便携包需要 Node.js，不需要 MoonBit 编译器；不捆绑 Node.js。

发布到注册表与 GitHub Release 是不同动作。当前已发布 Mooncakes 包，但没有 GitHub Release 或 npm 包；本地压缩包不能称为公开 Release。
