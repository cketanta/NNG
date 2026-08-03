class_name BackpackPanel
extends Control
## 全屏背包（B 键，游戏暂停）：横向三列 玩家属性 / 武器（只显示名称与等级，不含天赋） / 道具。

var _main: Main
var _gold_label: Label
var _stats_label: Label
var _weapons_box: VBoxContainer  # 武器列
var _items_box: GridContainer    # 道具列（2 列网格）

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.add_child(UiStyle.fullscreen_bg())  # 底层全屏背景贴图
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 16)
	bg.add_child(margin)
	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	vbox.add_child(UiStyle.big_title("背包"))
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gold_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body)
	body.add_child(_make_stats_box())    # 左：玩家属性
	body.add_child(_make_weapons_box())  # 中：武器
	body.add_child(_make_items_box())    # 右：道具

	var close := Button.new()
	close.text = "关闭（Esc）"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func _make_stats_box() -> Control:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", UiStyle.section(0))
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("玩家属性"))
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_stats_label)
	return box

func _make_weapons_box() -> Control:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", UiStyle.section(1))
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("武器"))
	_weapons_box = VBoxContainer.new()
	v.add_child(_weapons_box)
	return box

func _make_items_box() -> Control:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", UiStyle.section(2))
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("道具"))
	_items_box = GridContainer.new()  # 道具卡片 2 列网格（规整矩形）
	_items_box.columns = 2
	_items_box.add_theme_constant_override("h_separation", 8)
	_items_box.add_theme_constant_override("v_separation", 8)
	v.add_child(_items_box)
	return box

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	_stats_label.text = _main.player_stats_text()
	_rebuild_weapons()
	_rebuild_items()

## 武器列：只显示名称与等级（背包不含天赋）。
func _rebuild_weapons() -> void:
	for child in _weapons_box.get_children():
		child.queue_free()
	var slots: Array = _main.player.weapon_slots
	if slots.is_empty():
		_weapons_box.add_child(UiStyle.card_label("暂无武器（商店购买）"))
		return
	for slot in slots:
		_weapons_box.add_child(UiStyle.card_label("%s  Lv.%d（天赋点 %d）" % [
			_main.weapon_name(slot.id), slot.level, slot.tree.points]))

## 道具列：已拥有道具卡片（保留显示）。
func _rebuild_items() -> void:
	for child in _items_box.get_children():
		child.queue_free()
	var owned: Array[String] = []
	for item_id in ItemDefs.all_ids():
		if _main.player.item_counts.get(item_id, 0) > 0:
			owned.append(item_id)
	if owned.is_empty():
		_items_box.add_child(UiStyle.card_label("暂无道具"))
		return
	for item_id in owned:
		var card := UiStyle.item_card()
		card.custom_minimum_size = Vector2(220, 0)  # 规整矩形卡片
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		card.add_child(v)
		v.add_child(UiStyle.item_icon(ItemDefs.icon(item_id), 32))
		var count: int = _main.player.item_counts.get(item_id, 0)
		var name_label := UiStyle.card_label("[%s] %s ×%d" % [
			ItemDefs.rarity_name(item_id), ItemDefs.name(item_id), count],
			ItemDefs.rarity_color(item_id))
		name_label.add_theme_font_size_override("font_size", 13)
		v.add_child(name_label)
		var desc_label := UiStyle.card_label(ItemDefs.desc(item_id))
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(desc_label)
		_items_box.add_child(card)

func _on_close_pressed() -> void:
	_main.close_backpack()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_main.close_backpack()

func _make_section_title(text: String) -> Control:
	return UiStyle.title_bar(text)
