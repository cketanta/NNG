class_name ShopPanel
extends Control
## 全屏商店：左 = 玩家属性 + 武器槽位（点选两把同名合成、每把可出售）；右 = 武器购买 + 道具购买。
## 合成只在商店进行：点选一把武器（高亮）→ 点选同名的另一把 → 合成。

var _main: Main
var _gold_label: Label
var _stats_label: Label
var _slots_box: VBoxContainer    # 武器槽位区（重建）
var _buy_box: VBoxContainer      # 武器购买区
var _item_container: VBoxContainer  # 道具购买区
var _selected := -1              # 选中的武器槽位索引（合成用）

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UiStyle.panel(Color(0.04, 0.05, 0.08, 0.96), Color(0.3, 0.38, 0.5, 0.9), 0, 2))
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	bg.add_child(margin)
	var body := HBoxContainer.new()
	margin.add_child(body)

	# 左：玩家属性 + 武器槽位（合成 + 出售）。
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	left.add_child(UiStyle.big_title("商店"))
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_gold_label)
	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", UiStyle.section(0))
	var stats_v := VBoxContainer.new()
	stats_panel.add_child(stats_v)
	stats_v.add_child(UiStyle.title_bar("玩家属性"))
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_v.add_child(_stats_label)
	left.add_child(stats_panel)
	var slots_panel := PanelContainer.new()
	slots_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slots_panel.add_theme_stylebox_override("panel", UiStyle.section(1))
	var slots_v := VBoxContainer.new()
	slots_panel.add_child(slots_v)
	slots_v.add_child(UiStyle.title_bar("武器槽位（点选两把同名合成）"))
	_slots_box = VBoxContainer.new()
	slots_v.add_child(_slots_box)
	left.add_child(slots_panel)

	# 右：武器购买 + 道具购买。
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(430, 0)
	body.add_child(right)
	var buy_panel := PanelContainer.new()
	buy_panel.add_theme_stylebox_override("panel", UiStyle.section(2))
	var buy_v := VBoxContainer.new()
	buy_panel.add_child(buy_v)
	buy_v.add_child(UiStyle.title_bar("武器购买"))
	_buy_box = VBoxContainer.new()
	buy_v.add_child(_buy_box)
	right.add_child(buy_panel)
	var item_panel := PanelContainer.new()
	item_panel.add_theme_stylebox_override("panel", UiStyle.section(3))
	var item_v := VBoxContainer.new()
	item_panel.add_child(item_v)
	item_v.add_child(UiStyle.title_bar("道具购买"))
	_item_container = VBoxContainer.new()
	item_v.add_child(_item_container)
	right.add_child(item_panel)
	var close := Button.new()
	close.text = "开始下一波"
	close.pressed.connect(_on_close_pressed)
	right.add_child(close)

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	_stats_label.text = _main.player_stats_text()
	_rebuild_slots()
	_rebuild_buy()
	_rebuild_items()

## 武器槽位区：每把武器一行（选中高亮 + 出售按钮）。
func _rebuild_slots() -> void:
	for child in _slots_box.get_children():
		child.queue_free()
	var slots: Array = _main.player.weapon_slots
	if slots.is_empty():
		_slots_box.add_child(UiStyle.card_label("没有武器（去商店购买）"))
		return
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		var row := HBoxContainer.new()
		var select_btn := Button.new()
		select_btn.text = "%s  Lv.%d" % [_main.weapon_name(slot.id), slot.level]
		select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == _selected:
			select_btn.modulate = Color(0.6, 1.0, 0.6)  # 选中高亮
		select_btn.pressed.connect(_on_slot_clicked.bind(i))
		row.add_child(select_btn)
		var sell := Button.new()
		sell.text = "出售 %d" % (_main.weapon_cost(slot.id, slot.level) / 2)
		sell.pressed.connect(_on_sell_pressed.bind(i))
		row.add_child(sell)
		_slots_box.add_child(row)
	if _selected >= slots.size():
		_selected = -1

## 槽位点选：第一次选中，第二次点同名合成，点自己取消选中。
func _on_slot_clicked(idx: int) -> void:
	if _selected == -1:
		_selected = idx
	elif _selected == idx:
		_selected = -1
	else:
		_main.combine_weapons(_selected, idx)
		_selected = -1
	refresh()

func _on_sell_pressed(idx: int) -> void:
	_main.sell_weapon(idx)
	_selected = -1
	refresh()

## 武器购买区：短刃 / 左轮。
func _rebuild_buy() -> void:
	for child in _buy_box.get_children():
		child.queue_free()
	for id in _main.weapon_ids():
		var level: int = _main.player.weapon_level(id)
		var cost: int = _main.weapon_cost(id, level)
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "%s（已有 Lv.%d）" % [_main.weapon_name(id), level]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var buy := Button.new()
		buy.text = "购买 %d" % cost
		buy.disabled = _main.player.gold < cost
		buy.pressed.connect(_on_buy_weapon.bind(id))
		row.add_child(buy)
		_buy_box.add_child(row)

## 道具购买区：本波 5 个随机道具。
func _rebuild_items() -> void:
	for child in _item_container.get_children():
		child.queue_free()
	for item_id in _main.shop_item_offerings:
		if ItemDefs.is_unique(item_id) and item_id in _main.purchased_unique:
			continue
		var card := UiStyle.item_card()
		var row_box := VBoxContainer.new()
		card.add_child(row_box)
		var name_label := UiStyle.card_label("[%s] %s" % [ItemDefs.rarity_name(item_id), ItemDefs.name(item_id)], ItemDefs.rarity_color(item_id))
		row_box.add_child(name_label)
		row_box.add_child(UiStyle.card_label(ItemDefs.desc(item_id)))
		var buy := Button.new()
		var bought_this_wave: bool = _main.bought_items_this_wave.get(item_id, false)
		buy.text = "已购买" if bought_this_wave else "购买 %d 金币" % ItemDefs.cost(item_id)
		buy.disabled = _main.player.gold < ItemDefs.cost(item_id) or bought_this_wave
		buy.pressed.connect(_on_buy_item.bind(item_id))
		row_box.add_child(buy)
		_item_container.add_child(card)

func _on_buy_weapon(id: String) -> void:
	_main.buy_weapon(id)
	refresh()

func _on_buy_item(item_id: String) -> void:
	_main.buy_item(item_id)
	refresh()

func _on_close_pressed() -> void:
	_main.close_shop()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_main.close_shop()
