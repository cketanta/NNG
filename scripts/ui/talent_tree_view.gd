class_name TalentTreeView
extends Control
## 天赋树状图（真树布局）：按前置关系把节点排成多叉树——父子严格垂直对齐，
## 子树宽度按叶子数分配，连线为贝塞尔曲线，杜绝旧「每行独立居中」造成的交叉折返与超宽裁切。
## 配色：已点亮=亮金、可选=亮蓝、未解锁=暗灰、与已点亮天赋冲突=红框、根=绿。点击节点发信号查看效果。

signal node_clicked(talent_id: String)

const NODE_W := 104.0
const NODE_H := 40.0
const COL_GAP := 8.0
const ROW_GAP := 18.0
const PAD := 10.0

const COLOR_OWNED := Color(0.95, 0.78, 0.3)
const COLOR_OWNED_BG := Color(0.30, 0.26, 0.12, 0.95)
const COLOR_SELECTABLE := Color(0.5, 0.8, 1.0)
const COLOR_SELECTABLE_BG := Color(0.15, 0.24, 0.36, 0.95)
const COLOR_LOCKED := Color(0.42, 0.45, 0.5)
const COLOR_LOCKED_BG := Color(0.10, 0.11, 0.14, 0.95)
const COLOR_CONFLICT := Color(0.95, 0.4, 0.35)
const COLOR_ROOT := Color(0.6, 0.85, 0.6)
const COLOR_ROOT_BG := Color(0.13, 0.2, 0.13, 0.95)
const COLOR_LINE := Color(0.5, 0.58, 0.66, 0.7)

var _tree: TalentTree
var _tree_id := ""
var _root_name := ""
var _rects: Dictionary = {}  # talent_id -> Rect2
var _root_rect := Rect2()

# 真树布局缓存
var _children: Dictionary = {}  # parent_id -> [child_ids]
var _sub_w: Dictionary = {}     # id -> 子树宽度（叶子=1 格）

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
	# 建父子映射与根集合（prereq=="" 为根）。
	_children.clear()
	var roots: Array[String] = []
	var all_ids: Array[String] = []
	for t: Dictionary in TalentTree.TREES.get(_tree_id, []):
		all_ids.append(t.id)
		_children[t.id] = []
	for t: Dictionary in TalentTree.TREES.get(_tree_id, []):
		if t.prereq == "":
			roots.append(t.id)
		else:
			_children[t.prereq].append(t.id)
	# 递归计算每个节点的子树宽度（叶子 = 1 格）。
	_sub_w.clear()
	for id in all_ids:
		_calc_sub_width(id)
	var step := NODE_W + COL_GAP
	var row_h := NODE_H + ROW_GAP
	# 总宽度 = 所有根子树宽度之和（叶子数 × step）。
	var total_leaves := 0
	for id in roots:
		total_leaves += _sub_w[id]
	# 根节点们放在第 1 行（虚拟根在第 0 行，显示武器名）。
	var x_cursor := 0.0
	for id in roots:
		_layout_node(id, x_cursor, 1)
		x_cursor += _sub_w[id] * step
	# 虚拟根：顶部水平居中（宽度占满整树）。
	_root_rect = Rect2((total_leaves - 1) * 0.5 * step, PAD, NODE_W, NODE_H)
	var max_depth := _max_depth()
	custom_minimum_size = Vector2(maxf(total_leaves * step, NODE_W * 1.4) + PAD * 2.0,
		(max_depth + 2) * row_h + PAD * 2.0)

## 递归计算子树宽度（单位：格）。
func _calc_sub_width(id: String) -> int:
	if _sub_w.has(id):
		return _sub_w[id]
	var w := 0
	if _children[id].is_empty():
		w = 1  # 叶子占 1 格
	else:
		for c: String in _children[id]:
			w += _calc_sub_width(c)
	_sub_w[id] = w
	return w

## 递归布局：节点中心放在其子树宽度的中间，子节点依次水平铺开（父子同列）。
func _layout_node(id: String, x_offset: float, depth: int) -> void:
	var w: int = _sub_w[id]
	var step := NODE_W + COL_GAP
	_rects[id] = Rect2(x_offset + (w - 1) * 0.5 * step, PAD + depth * (NODE_H + ROW_GAP), NODE_W, NODE_H)
	var cx := x_offset
	for c: String in _children[id]:
		_layout_node(c, cx, depth + 1)
		cx += _sub_w[c] * step

## 整树最大深度（按前置链长度）。
func _max_depth() -> int:
	var d := 0
	for id: String in _rects.keys():
		var cur: String = id
		var dd := 0
		while true:
			var t: Dictionary = _tree.def(_tree_id, cur)
			if t.prereq == "":
				break
			cur = t.prereq
			dd += 1
		d = maxi(d, dd)
	return d

func _draw() -> void:
	if _tree == null or _tree_id == "" or _tree_id == "pistol":
		draw_string(get_theme_default_font(), Vector2(0, 24), "尚未选择攻击方式（首次升级时选择短刃 / 左轮）",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.7, 0.7, 0.7))
		return
	# 连线：前置节点（或虚拟根）底部中心 → 本节点顶部中心，二次贝塞尔弯曲。
	for id: String in _rects.keys():
		var t: Dictionary = _tree.def(_tree_id, id)
		var child_rect: Rect2 = _rects[id]
		var parent_pos: Vector2
		if t.prereq == "":
			parent_pos = _root_rect.position + Vector2(_root_rect.size.x * 0.5, _root_rect.size.y)
		else:
			parent_pos = _rects[t.prereq].position + Vector2(_rects[t.prereq].size.x * 0.5, _rects[t.prereq].size.y)
		_draw_bezier(parent_pos, child_rect.position + Vector2(child_rect.size.x * 0.5, 0.0))
	# 虚拟根与各天赋节点。
	_draw_node(_root_rect, _root_name, COLOR_ROOT, COLOR_ROOT_BG)
	for id: String in _rects.keys():
		var t: Dictionary = _tree.def(_tree_id, id)
		var owned: bool = _tree.is_owned(_tree_id, id)
		var selectable_now: bool = _tree.selectable(_tree_id).has(id)
		var color := COLOR_LOCKED
		var bg := COLOR_LOCKED_BG
		if owned:
			color = COLOR_OWNED
			bg = COLOR_OWNED_BG
		elif selectable_now:
			color = COLOR_SELECTABLE
			bg = COLOR_SELECTABLE_BG
		if not owned and t.conflict != "" and _tree.is_owned(_tree_id, t.conflict):
			color = COLOR_CONFLICT  # 与已点亮天赋互斥，标红提示
		_draw_node(_rects[id], t.name, color, bg)

## 二次贝塞尔连线：控制点在父/子中点高度，使曲线平滑竖直过渡。
func _draw_bezier(from: Vector2, to: Vector2) -> void:
	var control := Vector2(from.x, (from.y + to.y) * 0.5)
	var points := PackedVector2Array()
	for i in range(17):
		var t := float(i) / 16.0
		var u := 1.0 - t
		points.append(u * u * from + 2.0 * u * t * control + t * t * to)
	draw_polyline(points, COLOR_LINE, 2.0, true)

## 圆角节点：底色 + 描边 + 居中名称（用主题字体，替代 fallback_font）。
func _draw_node(rect: Rect2, text: String, border: Color, bg: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1.5)
	style.set_corner_radius_all(7)
	draw_style_box(style, rect)
	var fsize := 15
	draw_string(get_theme_default_font(), rect.position + Vector2(0.0, rect.size.y * 0.5 + fsize * 0.38),
		text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fsize, Color(0.95, 0.95, 0.95))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos: Vector2 = event.position
		for id: String in _rects.keys():
			if _rects[id].has_point(pos):
				node_clicked.emit(id)
				accept_event()
				return
