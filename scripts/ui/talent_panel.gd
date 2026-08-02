class_name TalentPanel
extends CenterContainer
## T 键打开的天赋树面板（游戏暂停）：上半显示当前攻击方式的天赋树概览，
## 下半是「选择天赋」区——每次从可选天赋中抽取三个，点击消耗 1 点天赋。

var _main: Main
var _attack_label: Label
var _points_label: Label
var _tree_box: VBoxContainer    # 天赋树概览区
var _choice_box: VBoxContainer  # 三选一加点区

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(UiStyle.big_title("天赋树"))
	_attack_label = Label.new()
	_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_attack_label)
	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_points_label)

	# 上半：当前攻击方式天赋树概览。
	var tree_panel := PanelContainer.new()
	tree_panel.add_theme_stylebox_override("panel", UiStyle.section(1))
	var tree_v := VBoxContainer.new()
	tree_panel.add_child(tree_v)
	tree_v.add_child(UiStyle.title_bar("天赋树概览（✓已拥有 ○可选 ·未解锁）"))
	_tree_box = VBoxContainer.new()
	tree_v.add_child(_tree_box)
	vbox.add_child(tree_panel)

	# 下半：三选一加点区。
	var choice_panel := PanelContainer.new()
	choice_panel.add_theme_stylebox_override("panel", UiStyle.section(0))
	var choice_v := VBoxContainer.new()
	choice_panel.add_child(choice_v)
	choice_v.add_child(UiStyle.title_bar("选择天赋（每次从可选天赋中抽取三个）"))
	_choice_box = VBoxContainer.new()
	choice_v.add_child(_choice_box)
	vbox.add_child(choice_panel)

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func refresh() -> void:
	var tree: TalentTree = _main.talent_tree
	var attack_id: String = _main.player.attack_id
	_attack_label.text = "当前攻击方式: %s" % _main.attack_name(attack_id)
	_points_label.text = "可用天赋点: %d" % tree.points
	_rebuild_tree(tree, attack_id)
	_rebuild_choices(tree, attack_id)

## 天赋树概览：逐条列出，已拥有 / 可选 / 未解锁三色区分。
func _rebuild_tree(tree: TalentTree, attack_id: String) -> void:
	for child in _tree_box.get_children():
		child.queue_free()
	if attack_id == "" or attack_id == "pistol":
		_tree_box.add_child(UiStyle.card_label("尚未选择攻击方式（首次升级时选择短刃 / 左轮）"))
		return
	for t: Dictionary in TalentTree.TREES.get(attack_id, []):
		var owned: bool = tree.is_owned(attack_id, t.id)
		var selectable_now: bool = tree.selectable(attack_id).has(t.id)
		var prefix := "✓" if owned else ("○" if selectable_now else "·")
		var line := Label.new()
		line.text = "%s %s" % [prefix, t.name]
		if owned:
			line.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		elif selectable_now:
			line.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
		else:
			line.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		_tree_box.add_child(line)
		var desc := Label.new()
		desc.text = "    " + t.desc
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.7, 0.73, 0.78))
		_tree_box.add_child(desc)

## 三选一：从可选天赋抽 3 张卡片，点击消耗 1 点解锁。
func _rebuild_choices(tree: TalentTree, attack_id: String) -> void:
	for child in _choice_box.get_children():
		child.queue_free()
	if attack_id == "" or attack_id == "pistol":
		_choice_box.add_child(UiStyle.card_label("选择攻击方式后即可加点"))
		return
	if tree.points <= 0:
		_choice_box.add_child(UiStyle.card_label("暂无天赋点（升级获得，按 T 随时加点）"))
		return
	if tree.selectable(attack_id).is_empty():
		_choice_box.add_child(UiStyle.card_label("该攻击方式的天赋已全部点满"))
		return
	for talent_id: String in tree.draw_choices(attack_id, 3):
		var t: Dictionary = tree.def(attack_id, talent_id)
		var card := UiStyle.item_card()
		var row := VBoxContainer.new()
		card.add_child(row)
		row.add_child(UiStyle.card_label(t.name, Color(0.6, 1.0, 0.6)))
		row.add_child(UiStyle.card_label(t.desc))
		var buy := Button.new()
		buy.text = "选择（消耗 1 点）"
		buy.pressed.connect(_on_choose.bind(attack_id, talent_id))
		row.add_child(buy)
		_choice_box.add_child(card)

func _on_choose(attack_id: String, talent_id: String) -> void:
	_main._on_talent_purchased(attack_id, talent_id)

func _on_close_pressed() -> void:
	_main.close_talent()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# 标记已处理，阻断同一事件继续传给 main，防止 main 随后弹暂停。
		get_viewport().set_input_as_handled()
		_main.close_talent()
