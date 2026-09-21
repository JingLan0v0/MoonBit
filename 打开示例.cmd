@echo off
cd /d "%~dp0"
chcp 65001 >nul
echo MoonRow - CSV 数据比较演示
echo.
node bin/moonrow.cjs examples/catalog/before.csv examples/catalog/after.csv --key sku --ignore updated_at
echo.
echo 预期：新增 1、删除 1、修改 1、未变化 2。退出码 1 表示发现差异。
pause
