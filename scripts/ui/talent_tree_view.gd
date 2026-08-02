class_name TalentTreeView
extends Control
## 天赋树状图：按前置关系分层绘制节点（列 = 层级深度），带连线与亮度区分——
## 已点亮=亮金、可选=亮蓝、未解锁=暗灰、与已点亮天赋冲突=红框。点击节点发信号查看效果。

signal node_clicked(talent_id: String)

const NODE_W := 120.0
const NODE_H := 44.0
const COL_GAP := 22.0
const ROW_GAP := 10.0

const COLOR_OWNED := Color(0.85, 0.7, 0.25)      # 已点亮：金
const COLOR_OWNED_BG := Color(0.30, 0.28, 0.14, 0.95)
const COLOR_SELECTABLE := Color(0.5, 0.8, 1.0)   # 可选：亮蓝
const COLOR_SELECTABLE_BG := Color(0.16, 0.24, 0.34, 0.95)
const COLOR_LOCKED := Color(0.42, 0.45, 0.5)     # 未解锁：暗灰
const COLOR_LOCKED_BG := Color(0.12, 0.13, 0.16, 0.95)
const COLOR_CONFLICT := Color(0.95, 0.4, 0.35)   # 与已点亮天赋互斥：红
const COLOR_ROOT := Color(0.6, 0.85, 0.6)        # 攻击方式根节点：绿
const COLOR_LINE := Color(0.5, 0.55, 0.62, 0.8)

var _tree: TalentTree
var _tree_id := ""
var _root_name := ""
var _rects: Dictionary = {}  # talent_id -> Rect2
var _root_rect := Rect2()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP  # 接收本控件的鼠标点击（用于点节点看效果）

## 传入天赋数据与根节点名称，重算布局并重绘。
func refresh(tree: TalentTree, tree_id: String, root_name: String) -> void:
	_tree = tree
	_tree_id = tree_id
	_root_name = root_name
	_rebuild_layout()
	queue_redraw()

func _rebuild_layout() -> void:
	_rects.clear()
	if _tree_id == "" or _tree_id == "pistol":
		custom_minimum_size = Vector2(420, 70)
		return
	# 每个天赋的深度（前置链长度；prereq="" 深度 0）。
	var depths := {}
	var ids: Array[String] = []
	for t: Dictionary in TalentTree.TREES.get(_tree_id, []):
		var d := 0
		var cur: Dictionary = t
		while cur.prereq != "":
			d += 1
			cur = _tree.def(_tree_id, cur.prereq)
		depths[t.id] = d
		ids.append(t.id)
	# 按深度分组为「行」（竖版：深度从上往下）；每行节点水平居中排列。
	var rows := {}
	var max_depth := 0
	var max_in_row := 0
	for id in ids:
		var d: int = depths[id]
		if not rows.has(d):
			rows[d] = []
		rows[d].append(id)
		max_depth = maxi(max_depth, d)
		max_in_row = maxi(max_in_row, rows[d].size())
	var step := NODE_W + COL_GAP
	var row_h := NODE_H + ROW_GAP
	# 深度 d 在行 (d+1)，第 0 行留给根节点。
	for d in rows.keys():
		var x_start: float = (max_in_row - rows[d].size()) * 0.5 * step
		for i in range(rows[d].size()):
			var id: String = rows[d][i]
			_rects[id] = Rect2(x_start + i * step, (d + 1) * row_h, NODE_W, NODE_H)
	# 根节点在第 0 行居中。
	_root_rect = Rect2((max_in_row - 1) * 0.5 * step, 0.0, NODE_W, NODE_H)
	custom_minimum_size = Vector2(max_in_row * step, (max_depth + 2) * row_h + 4.0)

func _draw() -> void:
	if _tree == null or _tree_id == "" or _tree_id == "pistol":
		draw_string(ThemeDB.fallback_font, Vector2(0, 22), "尚未选择攻击方式（首次升级时选择短刃 / 左轮）",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.7))
		return
	# 连线（竖版）：从前置节点（或根节点）底部中心连到本节点顶部中心。
	for id: String in _rects.keys():
		var t: Dictionary = _tree.def(_tree_id, id)
		var child_rect: Rect2 = _rects[id]
		var parent_pos := Vector2.ZERO
		if t.prereq == "":
			parent_pos = _root_rect.get_center() + Vector2(0, NODE_H * 0.5)
		else:
			parent_pos = _rects[t.prereq].get_center() + Vector2(0, NODE_H * 0.5)
		draw_line(parent_pos, child_rect.get_center() - Vector2(0, NODE_H * 0.5), COLOR_LINE, 2.0)
	# 根节点与各天赋节点。
	_draw_node(_root_rect, _root_name, COLOR_ROOT)
	for id: String in _rects.keys():
		var t: Dictionary = _tree.def(_tree_id, id)
		var owned: bool = _tree.is_owned(_tree_id, id)
		var selectable_now: bool = _tree.selectable(_tree_id).has(id)
		var color := COLOR_LOCKED
		if owned:
			color = COLOR_OWNED
		elif selectable_now:
			color = COLOR_SELECTABLE
		if not owned and t.conflict != "" and _tree.is_owned(_tree_id, t.conflict):
			color = COLOR_CONFLICT  # 与已点亮天赋互斥，标红提示
		_draw_node(_rects[id], t.name, color)

func _draw_node(rect: Rect2, text: String, border: Color) -> void:
	var bg := COLOR_LOCKED_BG
	if border == COLOR_OWNED:
		bg = COLOR_OWNED_BG
	elif border == COLOR_SELECTABLE:
		bg = COLOR_SELECTABLE_BG
	draw_rect(rect, bg, true)
	draw_rect(rect, border, false, 2.0)
	# 名称居中；略高于中线让文字视觉居中。
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.5 + 5), text,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color(0.95, 0.95, 0.95))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos: Vector2 = event.position
		for id: String in _rects.keys():
			if _rects[id].has_point(pos):
				node_clicked.emit(id)
				accept_event()
				return
