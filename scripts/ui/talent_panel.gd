class_name TalentPanel
extends Control
## 全屏天赋界面：左 = 玩家属性 + 人物天赋（4 分支直接加点）；右 = 武器列表（点选切换）
## + 选中武器的天赋树（树状图 + 三选一加点）。测试模式点击树节点可免费点亮/取消。

const TREE_VIEW_SCRIPT := preload("res://scripts/ui/talent_tree_view.gd")

var _main: Main
var _stats_label: Label
var _personal_points_label: Label
var _personal_box: VBoxContainer   # 人物天赋区
var _weapon_list: VBoxContainer    # 武器列表（8 槽）
var _tree_view: Control            # 选中武器天赋树状图
var _choice_box: VBoxContainer     # 三选一加点区
var _detail_label: Label           # 效果预览
var _selected_slot := -1           # 选中的武器槽位

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

	# 左：玩家属性 + 人物天赋。
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	left.add_child(UiStyle.big_title("天赋"))
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_stats_label)
	var personal_panel := PanelContainer.new()
	personal_panel.add_theme_stylebox_override("panel", UiStyle.section(0))
	var personal_v := VBoxContainer.new()
	personal_panel.add_child(personal_v)
	_personal_points_label = Label.new()
	_personal_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	personal_v.add_child(_personal_points_label)
	personal_v.add_child(UiStyle.title_bar("人物天赋（升级获得点数）"))
	_personal_box = VBoxContainer.new()
	personal_v.add_child(_personal_box)
	left.add_child(personal_panel)

	# 右：武器列表 + 选中武器天赋树 + 三选一。
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(520, 0)
	body.add_child(right)
	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", UiStyle.section(1))
	var list_v := VBoxContainer.new()
	list_panel.add_child(list_v)
	list_v.add_child(UiStyle.title_bar("武器（点选切换）"))
	_weapon_list = VBoxContainer.new()
	list_v.add_child(_weapon_list)
	right.add_child(list_panel)
	var tree_panel := PanelContainer.new()
	tree_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_panel.add_theme_stylebox_override("panel", UiStyle.section(2))
	var tree_v := VBoxContainer.new()
	tree_panel.add_child(tree_v)
	tree_v.add_child(UiStyle.title_bar("武器天赋（金=已点亮 蓝=可选 灰=未解锁 红框=互斥；点击节点查看）"))
	_tree_view = TREE_VIEW_SCRIPT.new()
	_tree_view.connect("node_clicked", _on_node_clicked)
	tree_v.add_child(_tree_view)
	right.add_child(tree_panel)
	var choice_panel := PanelContainer.new()
	choice_panel.add_theme_stylebox_override("panel", UiStyle.section(3))
	var choice_v := VBoxContainer.new()
	choice_panel.add_child(choice_v)
	choice_v.add_child(UiStyle.title_bar("选择天赋（每次从可选天赋中抽取三个）"))
	_choice_box = VBoxContainer.new()
	choice_v.add_child(_choice_box)
	right.add_child(choice_panel)
	_detail_label = Label.new()
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.custom_minimum_size = Vector2(480, 0)
	right.add_child(_detail_label)
	var close := Button.new()
	close.text = "关闭（Esc）"
	close.pressed.connect(_on_close_pressed)
	right.add_child(close)

func refresh() -> void:
	_stats_label.text = _main.player_stats_text()
	_personal_points_label.text = "可用人物天赋点: %d" % _main.player.player_talent.points
	_rebuild_personal()
	_rebuild_weapon_list()
	_rebuild_selected()

## 人物天赋：4 分支，每分支显示层数与加点按钮。
func _rebuild_personal() -> void:
	for child in _personal_box.get_children():
		child.queue_free()
	var pt: PlayerTalent = _main.player.player_talent
	for branch in PlayerTalent.BRANCHES:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s  Lv.%d/5" % [branch.name, pt.owned_count(branch.id)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var add := Button.new()
		add.text = "加点"
		add.disabled = not pt.can_unlock(branch.id)
		add.pressed.connect(_on_personal_add.bind(branch.id))
		row.add_child(add)
		_personal_box.add_child(row)

func _on_personal_add(branch_id: String) -> void:
	_main.unlock_personal_talent(branch_id)

## 武器列表：8 槽点选切换。
func _rebuild_weapon_list() -> void:
	for child in _weapon_list.get_children():
		child.queue_free()
	var slots: Array = _main.player.weapon_slots
	if slots.is_empty():
		_weapon_list.add_child(UiStyle.card_label("没有武器（商店购买）"))
		return
	if _selected_slot >= slots.size():
		_selected_slot = 0 if not slots.is_empty() else -1
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		var btn := Button.new()
		btn.text = "%s  Lv.%d（天赋点 %d）" % [_main.weapon_name(slot.id), slot.level, slot.tree.points]
		btn.pressed.connect(_on_weapon_selected.bind(i))
		if i == _selected_slot:
			btn.modulate = Color(0.6, 1.0, 0.6)
		_weapon_list.add_child(btn)

func _on_weapon_selected(idx: int) -> void:
	_selected_slot = idx
	refresh()

## 选中武器的天赋树 + 三选一。
func _rebuild_selected() -> void:
	if _selected_slot < 0 or _selected_slot >= _main.player.weapon_slots.size():
		_tree_view.refresh(TalentTree.new(), "", "")
		_clear_choices("点选上方武器查看与加点其天赋")
		_detail_label.text = ""
		return
	var slot: Dictionary = _main.player.weapon_slots[_selected_slot]
	if slot.id == "pistol":
		_tree_view.refresh(slot.tree, "", "")
		_clear_choices("破旧手枪没有天赋树")
		_detail_label.text = "破旧手枪没有天赋树"
		return
	_tree_view.refresh(slot.tree, slot.id, _main.weapon_name(slot.id))
	_rebuild_choices(slot)

func _clear_choices(hint: String) -> void:
	for child in _choice_box.get_children():
		child.queue_free()
	_choice_box.add_child(UiStyle.card_label(hint))

## 三选一：从选中武器可选天赋抽 3 个。
func _rebuild_choices(slot: Dictionary) -> void:
	for child in _choice_box.get_children():
		child.queue_free()
	if slot.tree.points <= 0:
		_choice_box.add_child(UiStyle.card_label("该武器暂无天赋点（武器等级 Lv.%d = %d 点）" % [slot.level, slot.level]))
		return
	if slot.tree.selectable(slot.id).is_empty():
		_choice_box.add_child(UiStyle.card_label("该武器天赋已全部点满"))
		return
	for talent_id: String in slot.tree.draw_choices(slot.id, 3):
		var t: Dictionary = slot.tree.def(slot.id, talent_id)
		var card := UiStyle.item_card()
		var row := VBoxContainer.new()
		card.add_child(row)
		row.add_child(UiStyle.card_label(t.name, Color(0.6, 1.0, 0.6)))
		row.add_child(UiStyle.card_label(t.desc))
		var buy := Button.new()
		buy.text = "选择（消耗 1 点）"
		buy.pressed.connect(_on_choose_talent.bind(slot.id, talent_id))
		row.add_child(buy)
		_choice_box.add_child(card)

func _on_choose_talent(_id: String, talent_id: String) -> void:
	_main.unlock_weapon_talent(_selected_slot, talent_id)

## 点击树状图节点：测试模式免费点亮/取消，否则显示效果预览。
func _on_node_clicked(talent_id: String) -> void:
	if _selected_slot < 0 or _selected_slot >= _main.player.weapon_slots.size():
		return
	var slot: Dictionary = _main.player.weapon_slots[_selected_slot]
	var tree: TalentTree = slot.tree
	if _main.test_mode:
		if tree.is_owned(slot.id, talent_id):
			tree.owned[slot.id][talent_id] = false
		else:
			tree.owned[slot.id][talent_id] = true
		refresh()
		return
	var t: Dictionary = tree.def(slot.id, talent_id)
	if t.is_empty():
		return
	var owned: bool = tree.is_owned(slot.id, talent_id)
	var selectable_now: bool = tree.selectable(slot.id).has(talent_id)
	var state := "已点亮" if owned else ("可选" if selectable_now else "未解锁")
	var txt := "%s（%s）\n%s" % [t.name, state, t.desc]
	if t.prereq != "":
		txt += "\n前置: %s" % tree.def(slot.id, t.prereq).name
	if t.conflict != "":
		txt += "\n与「%s」互斥" % tree.def(slot.id, t.conflict).name
	_detail_label.text = txt

func _on_close_pressed() -> void:
	_main.close_talent()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_main.close_talent()
