class_name BackpackPanel
extends CenterContainer
## 背包（B 键，游戏暂停）：人物属性 + 攻击方式（含已点天赋概览） + 已拥有道具。
## 布局：横向三列（玩家属性｜攻击方式｜道具），整体包在 ScrollContainer 里，超高时纵向滚动。

var _main: Main
var _gold_label: Label
var _stats_label: Label
var _attack_container: VBoxContainer  # 攻击方式列（动态重建）
var _items_box: VBoxContainer  # 已拥有道具（每道具一张卡片）

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
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

	var body := HBoxContainer.new()
	vbox.add_child(body)
	body.add_child(_make_stats_box())    # 左：玩家属性
	body.add_child(_make_attack_box())   # 中：攻击方式
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

func _make_attack_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_stylebox_override("panel", UiStyle.section(1))  # 攻击方式：绿
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(_make_section_title("攻击方式"))
	_attack_container = VBoxContainer.new()
	v.add_child(_attack_container)
	return box

func _make_items_box() -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(330, 0)
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
	_rebuild_attack()
	_rebuild_items()

## 攻击方式列：显示当前攻击方式 + 已点天赋概览 + 加天赋提示。
func _rebuild_attack() -> void:
	for child in _attack_container.get_children():
		child.queue_free()
	var attack_id: String = _main.player.attack_id
	_attack_container.add_child(UiStyle.card_label(_main.attack_info_text(attack_id)))
	if attack_id == "" or attack_id == "pistol":
		_attack_container.add_child(UiStyle.card_label("首次升级后选择攻击方式"))
		return
	var owned_ids: Array = _main.talent_tree.owned_ids(attack_id)
	if owned_ids.is_empty():
		_attack_container.add_child(UiStyle.card_label("尚未点亮天赋（按 T 打开天赋树）"))
	else:
		for talent_id in owned_ids:
			var t: Dictionary = _main.talent_tree.def(attack_id, talent_id)
			_attack_container.add_child(UiStyle.card_label("✓ " + t.name, Color(0.6, 1.0, 0.6)))
	_attack_container.add_child(UiStyle.card_label("按 T 打开天赋树加点"))

## 已拥有道具：每个道具一张卡片（道具系统暂停使用，仅展示框架保留）。
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
