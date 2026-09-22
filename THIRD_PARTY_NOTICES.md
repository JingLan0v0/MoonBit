# 第三方与参考说明

MoonRow 的 CSV 状态机、校验、组合键编码、差异计算与报告实现为本项目编写，没有从同类 CSV 比较工具复制或移植源码。

| 来源 | 用途 | 许可/性质 |
| --- | --- | --- |
| MoonBit 标准库，0.10.14+7d59c7ec9 | 字符串、集合、JSON 序列化和测试 | Apache-2.0；https://github.com/moonbitlang/core |
| Node.js | 文件、参数、编码、标准流、构建和验证宿主 | Node.js 自身许可；https://github.com/nodejs/node/blob/main/LICENSE；本交付不捆绑 Node.js 二进制 |
| MoonBit 工具链模板 | 初始项目配置、Apache-2.0 LICENSE、AGENTS 指引 | 官方工具生成；https://docs.moonbitlang.com/ |
| RFC 4180 | CSV 语法背景参考 | 规范参考，未复制规范正文；https://www.rfc-editor.org/info/rfc4180/ |
| simonw/csv-diff | 主键比较使用场景调研 | Apache-2.0 项目；未复制代码；https://github.com/simonw/csv-diff |
| MoonVerity | MoonBit 同类生态调研 | 未引入为依赖；https://mooncakes.io/docs/Wchwch777/moonverity |
| CJR-zhang/mbitsv | MoonBit 分隔文本与主键 diff 生态调研 | MIT；未引入为依赖，未复制或移植代码；https://github.com/CJR-zhang/mbitsv |

生成产物包含由 MoonBit 标准库编译而来的代码，交付包应保留本文件、LICENSE 及 NOTICE。编译器和标准库安装文件位于工作区 `.tools`，不加入项目源码仓库或产品交付包。

PDF 申报材料生成工具是开发辅助，不参与产品运行；不得把其字体或依赖视为本项目原创代码。
