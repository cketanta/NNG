class_name AttackSelectPanel
extends CenterContainer
## 首次升级时弹出的攻击方式选择面板（游戏暂停）：
## 在短刃 / 左轮中二选一，选中后固定，天赋树围绕所选攻击方式展开。

var _main: Main

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(UiStyle.big_title("选择攻击方式"))
	var hint := Label.new()
	hint.text = "首次升级：在两种攻击方式中选择一种（只能选一次）"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	for attack_id in ["blade", "revolver"]:
		var btn := Button.new()
		btn.text = "%s：%s" % [_main.attack_name(attack_id), _main.attack_desc(attack_id)]
		btn.pressed.connect(_on_choose.bind(attack_id))
		vbox.add_child(btn)

func _on_choose(attack_id: String) -> void:
	_main.choose_attack(attack_id)
