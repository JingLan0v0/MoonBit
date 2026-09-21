# Mooncakes 发布与交付

## 当前状态

本项目尚未发布到 Mooncakes。模块名 `JingLan0v0/moonrow` 中的用户名必须与实际 Mooncakes 账号一致；不能因为 GitHub 用户名相同就认定注册已经完成。

## 本地发布检查

```sh
node scripts/verify.mjs
```

完整检查包含 `scripts/check-package.mjs`：验证模块、CLI 和 Node 包版本一致，检查包中必需源码与示例，排除生成文件及历史申报附件，然后执行 `moon package` 生成本地包。当前版本生成 `_build/publish/JingLan0v0-moonrow-0.1.0.zip`。

`.moonignore` 管理 Mooncakes 包内容。它会替代同目录 `.gitignore` 的发布规则，因此显式重复生成物排除规则。必要源码、测试、示例和开发脚本仍保留。

## 首次实际发布

1. 参赛者在 https://mooncakes.io 使用 GitHub 登录并确认用户名。
2. 使用官方 `moon login` 流程完成本机认证；不要把密码、令牌提交到仓库。
3. 确认模块名、版本和本地检查结果后，在项目根目录执行 `moon publish`。
4. 在 Mooncakes 核验包页面，在一个全新 MoonBit 项目中通过 `moon add JingLan0v0/moonrow@0.1.0` 安装并调用公共接口，保存实际成功记录。

第 4 步中的安装命令仅在发布成功后才可用。发布可能需要账号拥有对应命名空间；未完成注册认证时，本地打包通过不等于发布成功。

## Git 源码与便携包

`scripts/package.ps1` 从干净 Git 提交导出源码包，并构建包含 CLI 产物的便携包。输出 `delivery.json` 记录源提交及产物 SHA256，`SHA256.json` 记录压缩包校验值。便携包需要 Node.js，不需要 MoonBit 编译器；不捆绑 Node.js。

发布到注册表与 GitHub Release 是不同动作。没有实际发布记录前，不在 README 展示可安装版本徽章，也不把本地压缩包称为公开 Release。
