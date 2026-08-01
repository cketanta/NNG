class_name ShopPanel
extends CenterContainer
## 波次之间的商店（游戏暂停）。
## 布局：整体更横向——左展示区（玩家属性｜武器 上下叠道具栏），右购买区（武器升级｜道具购买 并排）。
## 商店内容包在 ScrollContainer 里：高度超过视口时上下滚动。
## 道具每波随机刷 5 个，每个道具本波仅可购买一次（跨波可重复获得）。

var _main: Main
var _gold_label: Label
var _stats_label: Label
var _item_rows: Dictionary = {}    # 武器 id -> { name, effect, attr }（左侧武器展示）
var _inventory_box: VBoxContainer  # 道具栏（左侧，已拥有道具，每道具一张卡片）
var _upgrade_rows: Dictionary = {} # 武器 id -> { name, cost, button }（右侧武器升级）
var _shop_item_rows: Dictionary = {}  # 道具 id -> { name, effect, cost, button }（右侧道具购买）
var _item_container: VBoxContainer

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	# 整体包滚动容器：高度固定，内容超高时出现纵向滑动条。
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1040, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var panel := PanelContainer.new()
	scroll.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	vbox.add_child(_make_title("商店"))
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gold_label)

	# 主体：左展示区 + 右购买区
	var body := HBoxContainer.new()
	vbox.add_child(body)

	# 左列：顶部（玩家属性｜武器）并排，下方道具栏。
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(480, 0)
	body.add_child(left)

	var top_row := HBoxContainer.new()
	left.add_child(top_row)
	top_row.add_child(_make_stats_box())    # 左上：玩家属性
	top_row.add_child(_make_weapons_box())  # 左中：玩家属性右侧 = 武器

	left.add_child(_make_inventory_box())   # 左下：道具栏（已拥有道具）

	# 右列：武器升级｜道具购买 横向并排（减少纵向高度）。
	var right := HBoxContainer.new()
	body.add_child(right)
	right.add_child(_make_upgrade_box())
	right.add_child(_make_item_shop_box())

	var close := Button.new()
	close.text = "开始下一波"
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
	for weapon_id in _main.weapon_ids():
		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(name_label)
		var effect_label := Label.new()
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(effect_label)
		var attr_label := Label.new()
		attr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(attr_label)
		_item_rows[weapon_id] = { "name": name_label, "effect": effect_label, "attr": attr_label }
	return box

func _make_inventory_box() -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.section(2))  # 道具栏：橙
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("道具栏"))
	_inventory_box = VBoxContainer.new()
	v.add_child(_inventory_box)
	return box

func _make_upgrade_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(230, 0)
	box.add_theme_stylebox_override("panel", UiStyle.section(3))  # 武器升级：紫
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("武器升级"))
	for weapon_id in _main.weapon_ids():
		var row := VBoxContainer.new()
		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(name_label)
		var cost_label := Label.new()
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(cost_label)
		var buy := Button.new()
		buy.text = "升级"
		buy.pressed.connect(_on_buy_pressed.bind(weapon_id))
		row.add_child(buy)
		v.add_child(row)
		_upgrade_rows[weapon_id] = { "name": name_label, "cost": cost_label, "button": buy }
	return box

func _make_item_shop_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_stylebox_override("panel", UiStyle.section(2))  # 道具购买：橙
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("道具购买"))
	_item_container = VBoxContainer.new()
	v.add_child(_item_container)
	return box

func _on_buy_pressed(weapon_id: String) -> void:
	_main.buy_weapon(weapon_id)
	refresh()

func _on_buy_item_pressed(item_id: String) -> void:
	_main.buy_item(item_id)
	refresh()

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	_stats_label.text = _main.player_stats_text()
	# 左侧武器展示
	for weapon_id in _item_rows:
		var row: Dictionary = _item_rows[weapon_id]
		var level: int = _main.player.weapon_levels.get(weapon_id, 1)
		row.name.text = "%s  Lv.%d" % [_main.weapon_name(weapon_id), level]
		row.effect.text = _main.weapon_effect_text(weapon_id, level)
		row.attr.text = _main.weapon_attr_text(weapon_id)
	# 左侧道具栏
	_rebuild_inventory()
	# 右侧武器升级
	for weapon_id in _upgrade_rows:
		var row: Dictionary = _upgrade_rows[weapon_id]
		var level: int = _main.player.weapon_levels.get(weapon_id, 1)
		var cost: int = _main.weapon_cost(weapon_id)
		row.name.text = "%s  当前 Lv.%d" % [_main.weapon_name(weapon_id), level]
		row.cost.text = "升级价格: %d 金币" % cost
		row.button.disabled = _main.player.gold < cost
	# 右侧道具购买
	_rebuild_shop_items()

## 左侧道具栏：已拥有道具，每个道具一张卡片（名称×数量 + 效果）。
func _rebuild_inventory() -> void:
	for child in _inventory_box.get_children():
		child.queue_free()
	var owned: Array[String] = []
	for item_id in ItemDefs.all_ids():
		if _main.player.item_counts.get(item_id, 0) > 0:
			owned.append(item_id)
	if owned.is_empty():
		_inventory_box.add_child(UiStyle.card_label("暂无道具"))
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
		_inventory_box.add_child(card)

## 右侧道具购买：按本波刷出的道具重建。已购买的唯一道具不显示；本波已购的道具置灰「已购买」。
func _rebuild_shop_items() -> void:
	for child in _item_container.get_children():
		child.queue_free()
	_shop_item_rows.clear()
	for item_id in _main.shop_item_offerings:
		if ItemDefs.is_unique(item_id) and item_id in _main.purchased_unique:
			continue
		# 每个可购道具一张卡片，与左侧库存区风格一致。
		var card := UiStyle.item_card()
		var row_box := VBoxContainer.new()
		card.add_child(row_box)
		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", ItemDefs.rarity_color(item_id))
		row_box.add_child(name_label)
		var effect_label := Label.new()
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_box.add_child(effect_label)
		var cost_label := Label.new()
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_box.add_child(cost_label)
		var buy := Button.new()
		buy.text = "购买"
		buy.pressed.connect(_on_buy_item_pressed.bind(item_id))
		row_box.add_child(buy)
		_item_container.add_child(card)

		name_label.text = "[%s] %s" % [ItemDefs.rarity_name(item_id), ItemDefs.name(item_id)]
		effect_label.text = ItemDefs.desc(item_id)
		cost_label.text = "价格: %d 金币" % ItemDefs.cost(item_id)
		var bought_this_wave: bool = _main.bought_items_this_wave.get(item_id, false)
		buy.disabled = _main.player.gold < ItemDefs.cost(item_id) or bought_this_wave
		if bought_this_wave:
			buy.text = "已购买"
		_shop_item_rows[item_id] = { "name": name_label, "effect": effect_label, "cost": cost_label, "button": buy }

func _on_close_pressed() -> void:
	_main.close_shop()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# 标记已处理，阻断同一事件继续传给 main（shop 状态下 main 不弹暂停，但保持统一约定）。
		get_viewport().set_input_as_handled()
		_main.close_shop()

func _make_title(text: String) -> Label:
	return UiStyle.big_title(text)

func _make_section_title(text: String) -> Control:
	return UiStyle.title_bar(text)
