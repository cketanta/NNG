class_name StartPanel
extends CenterContainer
## 开局选择初始武器（近战鞭子或远程法杖）。
## 未选中的武器保持 0 级，可在商店购买。

var _main: Main

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(_make_title("选择初始武器"))
	var hint := Label.new()
	hint.text = "只能选一把，另一把可在商店购买"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	for weapon_id in ["whip", "staff"]:
		var btn := Button.new()
		btn.text = "%s：%s" % [_main.weapon_name(weapon_id), _desc(weapon_id)]
		btn.pressed.connect(_on_choose.bind(weapon_id))
		vbox.add_child(btn)

func _on_choose(weapon_id: String) -> void:
	_main.start_with_weapon(weapon_id)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_main.back_to_difficulty()

func _desc(weapon_id: String) -> String:
	if weapon_id == "whip":
		return "近战连斩"
	return "远程散射"

func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
