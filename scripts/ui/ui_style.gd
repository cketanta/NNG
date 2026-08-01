class_name UiStyle
extends RefCounted
## 暗色系 UI 样式工厂：StyleBoxFlat 与分区标题条，供各面板复用。
## 分区底色/边框按顺序轮换（蓝/绿/橙/紫），让相邻分区一眼可分。

const PANEL_BG := Color(0.08, 0.09, 0.12, 0.94)
const PANEL_BORDER := Color(0.35, 0.45, 0.6, 0.9)

# 分区底色（按顺序轮换）
const SECTION_COLORS := [
	Color(0.10, 0.18, 0.30, 0.92),  # 玩家属性：蓝
	Color(0.10, 0.26, 0.18, 0.92),  # 武器/武器升级：绿
	Color(0.28, 0.17, 0.09, 0.92),  # 道具/道具购买：橙
	Color(0.18, 0.12, 0.30, 0.92),  # 兜底：紫
]
const SECTION_BORDERS := [
	Color(0.35, 0.60, 0.95),
	Color(0.40, 0.85, 0.50),
	Color(0.95, 0.65, 0.30),
	Color(0.75, 0.55, 0.95),
]

# 分区标题条
const TITLE_BAR_BG := Color(0.22, 0.30, 0.42, 0.95)
const TITLE_BAR_BORDER := Color(0.45, 0.58, 0.78, 0.85)

## 生成一个 StyleBoxFlat：底色 / 边框色 / 圆角 / 边框宽。
static func panel(bg: Color = PANEL_BG, border: Color = PANEL_BORDER, corner := 8, border_w := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(corner)
	return sb

## 第 index 个分区的样式（底色+边框轮换）。
static func section(index: int) -> StyleBoxFlat:
	return panel(
		SECTION_COLORS[index % SECTION_COLORS.size()],
		SECTION_BORDERS[index % SECTION_BORDERS.size()],
		8, 2)

## 道具条目卡片容器：圆角底色 + 细边框。上下堆叠时每张卡片自带边框，一眼可分。
static func item_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", panel(
		Color(0.16, 0.18, 0.24, 0.95),
		Color(0.40, 0.46, 0.62, 0.9),
		6, 1))
	return card

## 卡片内一行居中文本（默认亮色，可传稀有度等颜色）。
static func card_label(text: String, color: Color = Color(0.9, 0.93, 0.98)) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	return label

## 带底色横条的分区标题（PanelContainer + 居中 Label）。
static func title_bar(text: String) -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", panel(TITLE_BAR_BG, TITLE_BAR_BORDER, 6, 1))
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	bar.add_child(label)
	return bar

## 整窗大标题（字号 22，亮色）。
static func big_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	return label
