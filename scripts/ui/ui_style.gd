class_name UiStyle
extends RefCounted
## 暗色系 UI 样式工厂：基于 9-patch 贴图（assets/ui/）的 StyleBoxTexture，供各面板复用。
## 分区底色/边框按顺序轮换（蓝/绿/橙/紫），让相邻分区一眼可分。
## 所有方法签名与 v1.3 保持一致（panel/section/item_card/card_label/title_bar/big_title），
## 内部从纯色 StyleBoxFlat 换成贴图，调用方无需改动。

const TEX_PANEL := preload("res://assets/ui/panel_bg.svg")        # 圆角面板 9-patch（margin 16）
const TEX_TITLE := preload("res://assets/ui/title_bar.svg")       # 分区标题条 9-patch（margin 8）
const TEX_BG := preload("res://assets/ui/bg_full.svg")            # 全屏背景大图

# 分区边框色（按顺序轮换；也作为 section 的整体色调）
const SECTION_BORDERS := [
	Color(0.35, 0.60, 0.95),  # 玩家属性：蓝
	Color(0.40, 0.85, 0.50),  # 武器/武器升级：绿
	Color(0.95, 0.65, 0.30),  # 道具/道具购买：橙
	Color(0.75, 0.55, 0.95),  # 兜底：紫
]

## 生成一个贴图化 StyleBoxTexture：底色/边框由贴图承载，参数保留兼容（不做纯色 override）。
## bg 作为色调微调参考（默认白色 = 贴图原样）；corner/border_w 由贴图决定。
static func panel(bg: Color = Color(1, 1, 1, 1), _border: Color = Color(1, 1, 1, 1), _corner := 8, _border_w := 2) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = TEX_PANEL
	sb.set_texture_margin_all(16.0)
	sb.content_margin_left = 18.0
	sb.content_margin_top = 14.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 14.0
	sb.modulate_color = bg
	return sb

## 第 index 个分区的样式：panel_bg 贴图 + 分区色调（边框色向白色提亮，底色仍暗）。
static func section(index: int) -> StyleBoxTexture:
	var t: Color = SECTION_BORDERS[index % SECTION_BORDERS.size()]
	var sb := StyleBoxTexture.new()
	sb.texture = TEX_PANEL
	sb.set_texture_margin_all(16.0)
	sb.content_margin_left = 18.0
	sb.content_margin_top = 14.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 14.0
	# 以分区色为基准提亮：底色×亮色仍暗、边框呈彩色，延续分区区分。
	sb.modulate_color = Color(0.55 + 0.45 * t.r, 0.55 + 0.45 * t.g, 0.55 + 0.45 * t.b)
	return sb

## 道具条目卡片容器：贴图圆角底 + 细边框，中性色调。上下堆叠时每张卡片自带边框，一眼可分。
static func item_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", panel(Color(0.92, 0.94, 1.0, 1.0)))
	return card

## 卡片内一行居中文本（默认亮色，可传稀有度等颜色）。
static func card_label(text: String, color: Color = Color(0.9, 0.93, 0.98)) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	return label

## 物品小图标：居中 TextureRect，懒加载纹理（空路径显示空位）。
static func item_icon(icon_path: String, size := 40.0) -> TextureRect:
	var icon := TextureRect.new()
	if icon_path != "":
		icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(size, size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return icon

## 带贴图横条的分区标题（PanelContainer + 居中 Label）。
static func title_bar(text: String) -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _title_stylebox())
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	bar.add_child(label)
	return bar

## 全屏背景层：bg_full 大图铺满视口，忽略鼠标事件（不挡交互）。
static func fullscreen_bg() -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = TEX_BG
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return tr

## 整窗大标题（字号 22，亮色）。
static func big_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	return label

## 标题条贴图样式（内部复用）。
static func _title_stylebox() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = TEX_TITLE
	sb.set_texture_margin_all(8.0)
	sb.content_margin_left = 12.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 4.0
	return sb
