class_name TalentPanel
extends CenterContainer
## 升级弹出的天赋窗口：显示天赋树与可用点数；可花费或关闭（点数攒着以后用）。
## 窗口显示时游戏暂停。

var _main: Main
var _points_label: Label
var _tree_ui: TalentTreeUI

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(_make_title("天赋树"))
	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_points_label)

	_tree_ui = TalentTreeUI.new()
	_tree_ui.setup(_main.talent_tree, _on_buy)
	vbox.add_child(_tree_ui)

	var close := Button.new()
	close.text = "关闭（可攒着以后再点）"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func _on_buy(branch_id: String) -> void:
	_main._on_talent_purchased(branch_id)

func refresh() -> void:
	_points_label.text = "可用天赋点: %d" % _main.talent_tree.points
	_tree_ui.refresh()

func _on_close_pressed() -> void:
	_main.close_talent()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_main.close_talent()

func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
