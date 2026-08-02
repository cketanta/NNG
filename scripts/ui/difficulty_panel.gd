class_name DifficultyPanel
extends CenterContainer
## 开局先选择难度（在选武器之前）。
## 难度只影响刷怪速率、怪物血量与怪物攻击力。

var _main: Main

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(_make_title("选择难度"))
	var hint := Label.new()
	hint.text = "难度影响刷怪速率、怪物血量与怪物攻击力"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	for diff_id in _main.difficulty_ids():
		var btn := Button.new()
		btn.text = _main.difficulty_name(diff_id)
		btn.pressed.connect(_on_choose.bind(diff_id))
		vbox.add_child(btn)

	var test_btn := Button.new()
	test_btn.text = "测试模式（可调波数/金币/属性/攻击方式/无限道具）"
	test_btn.pressed.connect(_on_test_mode_pressed)
	vbox.add_child(test_btn)

func _on_choose(diff_id: String) -> void:
	_main.choose_difficulty(diff_id)

func _on_test_mode_pressed() -> void:
	_main.choose_test_mode()

func _make_title(text: String) -> Label:
	return UiStyle.big_title(text)
