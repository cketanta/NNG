class_name BackpackPanel
extends CenterContainer
## 背包（B 键，游戏暂停）：拥有的武器 + 金币 + 攒下的天赋点，
## 并内嵌同一个可花费的天赋树。

var _main: Main
var _gold_label: Label
var _items_label: Label
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

	vbox.add_child(_make_title("背包"))
	_gold_label = Label.new()
	vbox.add_child(_gold_label)
	_items_label = Label.new()
	vbox.add_child(_items_label)
	_points_label = Label.new()
	vbox.add_child(_points_label)

	_tree_ui = TalentTreeUI.new()
	_tree_ui.setup(_main.talent_tree, _on_buy)
	vbox.add_child(_tree_ui)

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func _on_buy(branch_id: String) -> void:
	_main._on_talent_purchased(branch_id)

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	_items_label.text = _items_text()
	_points_label.text = "天赋点: %d（在下方的天赋树花费）" % _main.talent_tree.points
	_tree_ui.refresh()

func _items_text() -> String:
	var lines: Array[String] = []
	for weapon_id in _main.weapon_ids():
		var level: int = _main.player.weapon_levels.get(weapon_id, 0)
		if level < 1:
			lines.append("• %s  未获得" % _main.weapon_name(weapon_id))
		else:
			lines.append("• %s  Lv.%d\n    %s" % [_main.weapon_name(weapon_id), level, _main.weapon_effect_text(weapon_id, level)])
	return "\n".join(lines)

func _on_close_pressed() -> void:
	_main.close_backpack()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_main.close_backpack()

func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
