class_name PausePanel
extends CenterContainer
## 战斗中 Esc 唤出的暂停菜单：继续 / 重新开始 / 退出游戏。显示时游戏暂停。

var _main: Main
var _info_label: Label

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(_make_title("暂停"))
	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_info_label)

	var resume := Button.new()
	resume.text = "继续游戏"
	resume.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume)
	var restart := Button.new()
	restart.text = "重新开始"
	restart.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart)
	var quit_btn := Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

func refresh() -> void:
	_info_label.text = "难度: %s    第 %d 波" % [_main.difficulty_name(_main.difficulty_id), _main.wave_number]

func _on_resume_pressed() -> void:
	_main.close_pause()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_main.close_pause()

func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
