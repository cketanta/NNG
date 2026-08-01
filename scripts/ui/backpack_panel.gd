class_name BackpackPanel
extends CenterContainer
## 背包（B 键，游戏暂停）：人物属性 + 已拥有武器（含属性） + 已拥有道具（含总加成）。
## 布局：横向三列（玩家属性｜武器｜道具），整体包在 ScrollContainer 里，超高时纵向滚动。
## 天赋树已停用，不再内嵌天赋树控件。

var _main: Main
var _gold_label: Label
var _stats_label: Label
var _weapon_rows: Dictionary = {}  # 武器 id -> { name, effect, attr }
var _items_label: Label

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
		_weapon_rows[weapon_id] = { "name": name_label, "effect": effect_label, "attr": attr_label }
	return box

func _make_items_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(340, 0)
	box.add_theme_stylebox_override("panel", UiStyle.section(2))  # 道具：橙
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("道具"))
	_items_label = Label.new()
	_items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_items_label)
	return box

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	_stats_label.text = _main.player_stats_text()
	for weapon_id in _weapon_rows:
		var row: Dictionary = _weapon_rows[weapon_id]
		var level: int = _main.player.weapon_levels.get(weapon_id, 0)
		if level < 1:
			row.name.text = "%s  未获得" % _main.weapon_name(weapon_id)
			row.effect.text = ""
			row.attr.text = ""
		else:
			row.name.text = "%s  Lv.%d" % [_main.weapon_name(weapon_id), level]
			row.effect.text = _main.weapon_effect_text(weapon_id, level)
			row.attr.text = _main.weapon_attr_text(weapon_id)
	_items_label.text = _items_text()

## 已拥有道具：每个道具一行（含数量与总加成，不重复列）。
func _items_text() -> String:
	var lines: Array[String] = []
	for item_id in ItemDefs.all_ids():
		var count: int = _main.player.item_counts.get(item_id, 0)
		if count < 1:
			continue
		lines.append("[%s] %s ×%d\n%s\n%s" % [
			ItemDefs.rarity_name(item_id), ItemDefs.name(item_id), count,
			ItemDefs.desc(item_id), _item_total_text(item_id),
		])
	if lines.is_empty():
		return "暂无道具"
	return "\n".join(lines)

## 每种道具的总加成（乘算显示底数与次数）。
func _item_total_text(item_id: String) -> String:
	var count: int = _main.player.item_counts.get(item_id, 0)
	var kind := ItemDefs.kind(item_id)
	match kind:
		"ranged_flat", "melee_flat", "ranged_speed", "move_speed", "armor", "luck":
			return "当前总加成 ×%d" % count
		"max_hp":
			return "血量上限 +%d" % (10 * count)
		"heal":
			return "累计回复 %d 血" % (10 * count)
		"ranged_mult", "melee_mult":
			return "攻击 ×1.1^%d" % count
		"melee_range_mult":
			return "距离 ×1.1^%d" % count
		"ranged_cooldown", "melee_cooldown":
			return "冷却 ×0.9^%d" % count
		"ring":
			return "刷怪 ×2，全武器攻击 ×1.5"
	return ""

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
