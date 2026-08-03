class_name DifficultyPanel
extends Control
## 开局主菜单：浮动星光背景 + 艺术标题 + 难度选择（入场淡入/缩放动画）。
## 难度只影响刷怪速率、怪物血量与怪物攻击力。

const STARFIELD_SCRIPT := preload("res://scripts/effects/starfield.gd")

var _main: Main
var _title: Label
var _intro_t := -1.0  # 入场动画计时（<0 表示未播放）

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	add_child(UiStyle.fullscreen_bg())      # 底层星空背景贴图
	var starfield: Node2D = STARFIELD_SCRIPT.new()  # 背景之上浮动星光
	add_child(starfield)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# 艺术标题：NNG + 副标题。
	_title = Label.new()
	_title.text = "NNG"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 68)
	_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_title.add_theme_constant_override("shadow_offset_x", 4)
	_title.add_theme_constant_override("shadow_offset_y", 4)
	vbox.add_child(_title)
	var sub := UiStyle.card_label("类吸血鬼幸存者 · 开局直接开战（初始破旧手枪）", Color(0.72, 0.82, 0.96))
	sub.add_theme_font_size_override("font_size", 16)
	vbox.add_child(sub)

	# 难度选择：按钮 + 描述。
	vbox.add_child(UiStyle.title_bar("选择难度"))
	for diff_id in _main.difficulty_ids():
		var btn := Button.new()
		btn.text = _main.difficulty_name(diff_id)
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_choose.bind(diff_id))
		vbox.add_child(btn)
		var desc := _difficulty_desc(diff_id)
		if desc != "":
			var l := UiStyle.card_label(desc, Color(0.6, 0.68, 0.8))
			l.add_theme_font_size_override("font_size", 14)
			vbox.add_child(l)

	# 测试模式。
	var test_btn := Button.new()
	test_btn.text = "测试模式（可调波数/金币/属性/武器/无限道具）"
	test_btn.custom_minimum_size = Vector2(0, 46)
	test_btn.pressed.connect(_on_test_mode_pressed)
	vbox.add_child(test_btn)
	# 图鉴入口（角落）。
	var bestiary_btn := Button.new()
	bestiary_btn.text = "图鉴（怪物/武器/道具/天赋树）"
	bestiary_btn.custom_minimum_size = Vector2(0, 44)
	bestiary_btn.pressed.connect(_on_bestiary_pressed)
	vbox.add_child(bestiary_btn)

func _on_bestiary_pressed() -> void:
	_main.open_bestiary()

func _difficulty_desc(diff_id: String) -> String:
	match diff_id:
		"easy":
			return "怪物更慢更弱，适合熟悉玩法"
		"normal":
			return "标准体验"
		"hard":
			return "怪物更强更密，高难度挑战"
	return ""

## 入场动画：面板淡入 + 标题缩放回落（手动 _process 驱动，暂停下也运行）。
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and _title != null:
		modulate.a = 0.0
		_title.scale = Vector2(1.3, 1.3)
		_intro_t = 0.0

func _process(delta: float) -> void:
	if _intro_t < 0.0:
		return
	_intro_t += delta
	modulate.a = minf(_intro_t / 0.35, 1.0)
	var p := minf(_intro_t / 0.5, 1.0)
	_title.scale = Vector2.ONE + Vector2(0.3, 0.3) * (1.0 - p)
	if _intro_t >= 0.5:
		_intro_t = -1.0

func _on_choose(diff_id: String) -> void:
	_main.choose_difficulty(diff_id)

func _on_test_mode_pressed() -> void:
	_main.choose_test_mode()
