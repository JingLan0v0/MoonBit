# 可复现业务场景

所有数据均为虚构数据。先在仓库根目录执行 `node scripts/build.mjs`。
下面三条命令都应返回 **1**，表示成功发现差异，不是执行失败。

## 1. 商品目录审核

运营人员收到两个日期的商品目录，需要检查价格调整、上架和下架。
按 `sku` 匹配并忽略每次都会变化的导出时间，避免行顺序变化产生噪声。

```sh
node bin/moonrow.cjs examples/catalog/before.csv examples/catalog/after.csv --key sku --ignore updated_at --format markdown
```

预期新增 A004、删除 A002、A001 价格从 `3.00` 变为 `3.50`，另有两条记录不变。
报告可用于人工复核；它不代表商品变化已经获得业务审批。

## 2. 多仓库存核对

同一商品在多个仓库都有库存，单独使用商品编号会产生重复键。
仓管人员用商品编号和仓库组成主键，比较两次库存导出，忽略导出时间。

```sh
node bin/moonrow.cjs examples/inventory/before.csv examples/inventory/after.csv --key sku --key warehouse --ignore exported_at --format json
```

预期 A001/North 库存从 `10` 变为 `12`，A001/South 不变；新增 A003/North，删除 A002/North。
库只报告字符串变化，不计算库存收支或推断差异原因。

## 3. 部署配置复核

开发者比较部署前后的配置导出，用服务名和环境定位配置项。
编号字符串中的前导零可能有意义，因此不做自动数值转换。

```sh
node bin/moonrow.cjs examples/config/before.csv examples/config/after.csv --key service --key environment --format text
```

预期 checkout/production 的 `value` 从 `001` 变为 `1`，search/production 不变。
只重排行列而不改变值时应返回 0；重复主键等非法输入返回 2。

三组预期都由 `tests/integration.mjs` 实际启动 CLI 验证。
这些是产品使用说明，不是参赛者人工撰写的申报书。
