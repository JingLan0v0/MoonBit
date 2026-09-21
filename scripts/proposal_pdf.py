"""Optional submission-document generator; not a product runtime dependency."""
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from pypdf import PdfReader

root = Path(__file__).resolve().parents[1]
out = root / "output/pdf/MoonRow-项目申报书.pdf"
out.parent.mkdir(parents=True, exist_ok=True)
font = Path("C:/Windows/Fonts/msyh.ttc")
pdfmetrics.registerFont(TTFont("CN", str(font), subfontIndex=0))
style = ParagraphStyle("body", fontName="CN", fontSize=10, leading=16, textColor=HexColor("#25364A"), wordWrap="CJK")
small = ParagraphStyle("small", parent=style, fontSize=8.5, leading=13)
c = canvas.Canvas(str(out), pagesize=A4)
c.setTitle("MoonRow - 项目申报书")
c.setAuthor("MoonRow contributors")
w, h = A4
c.setFillColor(HexColor("#102B46")); c.rect(0, h-135, w, 135, fill=1, stroke=0)
c.setFillColor(HexColor("#58DFC0")); c.setFont("CN", 10); c.drawString(42, h-32, "2026 MOONBIT HACKATHON  /  数据处理")
c.setFillColor(HexColor("#FFFFFF")); c.setFont("CN", 29); c.drawString(42, h-74, "MoonRow")
c.setFont("CN", 12); c.drawString(42, h-101, "CSV 主键差异比较库与命令行工具")
c.setFont("CN", 9); c.drawRightString(w-42, h-122, "原创开源  |  Apache-2.0  |  v0.1.0 本地候选版本")
y = h-158
def para(text, st=style, gap=8):
    global y
    p=Paragraph(text, st); _, ph=p.wrap(w-84, y-44); p.drawOn(c,42,y-ph); y-=ph+gap
def section(title, text):
    global y
    c.setFillColor(HexColor("#087F76")); c.setFont("CN",11); c.drawString(42,y-12,title); y-=23
    para(text)

para('GitHub：JingLan0v0　　姓名/队伍：________________', small, 3)
para('仓库：<link href="https://github.com/JingLan0v0/MoonBit" color="#087F76">https://github.com/JingLan0v0/MoonBit</link>', small, 11)
section("01  真实需求", "两次商品目录或数据库导出可能改变行列顺序，逐行比较会产生噪声。MoonRow 按业务主键对应记录，准确报告新增、删除及字段前后值，方便开发者复核数据变化。")
section("02  MoonBit 核心实现", "用 MoonBit 实现 CSV 状态机、表结构校验、单列/组合主键索引、精确字符串比较和文本/JSON/Markdown 报告。Node.js 仅提供文件读取、UTF-8 解码、标准流及退出码。离线运行，核心库可复用，无付费接口。")
section("03  清晰的功能边界", "支持 BOM、中文、引号转义、跨行字段、行列重排及忽略列；拒绝空键、重复键和非法 CSV。每文件上限 10 MiB、5 万条记录、100 列。不做数据库连接、Excel 原生格式、自动数值推断或云端服务。")
section("04  可复现验收", "固定商品样例得到：新增 1、删除 1、修改 1、未变化 2；price 从字符串 3.00 变为 3.50。退出码 0/1/2 分别表示无差异、有差异和输入错误。Windows 已通过 18 组 MoonBit 测试、11 组集成场景共 85 次进程验证，含 25 组固定种子数据双向独立核对及资源边界测试。")
section("05  交付与计划", "交付核心库、CLI、README、示例、测试、许可证、架构/API/限制说明和固定工具链。Windows/Linux CI 已配置，远程结果待实际运行。2026-09-21 已有本地候选版本，计划 9 月 28 日前准备最终验收材料，并根据官方反馈补件。")
para("当前状态：仓库公开与远程同步、报名、入群、官方审核及支持发放仍待确认。联系方式由参赛者在正式报名表中填写。", small, 0)
assert y > 48, f"Page overflow at {y}"
c.setStrokeColor(HexColor("#D5E1E9")); c.line(42,38,w-42,38)
c.setFillColor(HexColor("#63758A")); c.setFont("CN",8); c.drawString(42,24,"MoonRow / 项目说明 / 2026-09-21"); c.drawRightString(w-42,24,"1 / 1")
c.save()
reader=PdfReader(out)
assert len(reader.pages)==1
text=reader.pages[0].extract_text()
for token in ["MoonRow", "85", "Apache"]:
    assert token in text
print(out)
print(f"Verified single page, {len(text)} extracted characters")
