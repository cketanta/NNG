class_name BackpackPanel
extends CenterContainer
## 背包（B 键，游戏暂停）：人物属性 + 已拥有武器（含属性） + 已拥有道具（含总加成）。
## 布局：横向三列（玩家属性｜武器｜道具），整体包在 ScrollContainer 里，超高时纵向滚动。
## 天赋树已停用，不再内嵌天赋树控件。

var _main: Main
var _gold_label: Label
var _stats_label: Label
var _weapon_rows: Dictionary = {}  # 武器 id -> { name, effect, attr }（仅已获得武器）
var _weapons_container: VBoxContainer  # 武器列（动态重建，未获得武器不显示）
var _items_box: VBoxContainer  # 已拥有道具（每道具一张卡片）

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	# 整体包滚动容器：高度固定，内容超高时出现纵向滑动条。
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(840, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var panel := PanelContainer.new()
	scroll.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	vbox.add_child(_make_title("背包"))
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gold_label)

	# 主体：横向三列。
	var body := HBoxContainer.new()
	vbox.add_child(body)
	body.add_child(_make_stats_box())    # 左：玩家属性
	body.add_child(_make_weapons_box())  # 中：武器
	body.add_child(_make_items_box())    # 右：道具

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func _make_stats_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(170, 0)
	box.add_theme_stylebox_override("panel", UiStyle.section(0))  # 玩家属性：蓝
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("玩家属性"))
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_stats_label)
	return box

func _make_weapons_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_stylebox_override("panel", UiStyle.section(1))  # 武器：绿
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("武器"))
	_weapons_container = VBoxContainer.new()
	v.add_child(_weapons_container)
	return box

func _make_items_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(340, 0)
	box.add_theme_stylebox_override("panel", UiStyle.section(2))  # 道具：橙
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("道具"))
	_items_box = VBoxContainer.new()
	v.add_child(_items_box)
	return box

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	_stats_label.text = _main.player_stats_text()
	_rebuild_weapons()
	_rebuild_items()

## 武器列：只显示已获得的武器（level>=1），未获得武器不占行。
func _rebuild_weapons() -> void:
	for child in _weapons_container.get_children():
		child.queue_free()
	_weapon_rows.clear()
	var owned_count := 0
	for weapon_id in _main.weapon_ids():
		var level: int = _main.player.weapon_levels.get(weapon_id, 0)
		if level < 1:
			continue
		owned_count += 1
		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_weapons_container.add_child(name_label)
		var effect_label := Label.new()
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_weapons_container.add_child(effect_label)
		var attr_label := Label.new()
		attr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_weapons_container.add_child(attr_label)
		_weapon_rows[weapon_id] = { "name": name_label, "effect": effect_label, "attr": attr_label }
		name_label.text = "%s  Lv.%d" % [_main.weapon_name(weapon_id), level]
		effect_label.text = _main.weapon_effect_text(weapon_id, level)
		attr_label.text = _main.weapon_attr_text(weapon_id)
	if owned_count == 0:
		var none := Label.new()
		none.text = "暂无武器"
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_weapons_container.add_child(none)

## 已拥有道具：每个道具一张卡片（名称×数量 + 效果 + 总加成），上下堆叠以卡片边框区分。
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
		var v := VBoxContainer.new()
		card.add_child(v)
		var count: int = _main.player.item_counts.get(item_id, 0)
		v.add_child(UiStyle.card_label("[%s] %s ×%d" % [
			ItemDefs.rarity_name(item_id), ItemDefs.name(item_id), count],
			ItemDefs.rarity_color(item_id)))
		v.add_child(UiStyle.card_label(ItemDefs.desc(item_id)))
		_items_box.add_child(card)

func _on_close_pressed() -> void:
	_main.close_backpack()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# 标记已处理，阻断同一事件继续传给 main，防止 main 随后弹暂停。
		get_viewport().set_input_as_handled()
		_main.close_backpack()

func _make_title(text: String) -> Label:
	return UiStyle.big_title(text)

func _make_section_title(text: String) -> Control:
	return UiStyle.title_bar(text)
