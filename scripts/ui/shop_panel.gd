class_name ShopPanel
extends CenterContainer
## 波次之间的商店（游戏暂停）：售卖武器，价格随拥有等级递增，重复购买叠加效果。

var _main: Main
var _gold_label: Label
var _item_rows: Dictionary = {}  # 武器 id -> { name, effect, cost, button }

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(_make_title("商店"))
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gold_label)

	for weapon_id in _main.weapon_ids():
		vbox.add_child(_make_item_row(weapon_id))

	var close := Button.new()
	close.text = "开始下一波"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func _make_item_row(weapon_id: String) -> Control:
	var box := VBoxContainer.new()
	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var effect_label := Label.new()
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(effect_label)
	var cost_label := Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cost_label)
	var buy := Button.new()
	buy.text = "购买"
	buy.pressed.connect(_on_buy_pressed.bind(weapon_id))
	box.add_child(buy)

	_item_rows[weapon_id] = { "name": name_label, "effect": effect_label, "cost": cost_label, "button": buy }
	return box

func _on_buy_pressed(weapon_id: String) -> void:
	_main.buy_weapon(weapon_id)
	refresh()

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	for weapon_id in _item_rows:
		var row: Dictionary = _item_rows[weapon_id]
		var level: int = _main.player.weapon_levels.get(weapon_id, 1)
		var cost: int = _main.weapon_cost(weapon_id)
		row.name.text = "%s  Lv.%d" % [_main.weapon_name(weapon_id), level]
		row.effect.text = _effect_text(weapon_id, level)
		row.cost.text = "价格: %d 金币" % cost
		row.button.disabled = _main.player.gold < cost

func _effect_text(weapon_id: String, level: int) -> String:
	return _main.weapon_effect_text(weapon_id, level)

func _on_close_pressed() -> void:
	_main.close_shop()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_main.close_shop()

func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
