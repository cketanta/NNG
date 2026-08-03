class_name BestiaryPanel
extends Control
## 图鉴：主界面角落打开，展示 怪物 / 武器 / 道具 / 天赋树 四类信息。

const TREE_VIEW_SCRIPT := preload("res://scripts/ui/talent_tree_view.gd")

const MONSTERS := [
	{ "name": "近战怪", "desc": "直线冲向玩家的红色三角，接触伤害。", "color": "红" },
	{ "name": "远程怪", "desc": "保持距离发射子弹的黄色菱形。", "color": "黄" },
	{ "name": "爆炸怪", "desc": "接近后自爆的紫色尖刺怪，造成范围伤害。", "color": "紫" },
	{ "name": "冲锋怪", "desc": "高速低血的蓝色六角，接触伤害高。", "color": "蓝" },
	{ "name": "喷吐怪", "desc": "远程喷射三向弹的绿色菱形。", "color": "绿" },
	{ "name": "孵化怪", "desc": "死亡分裂成两只小怪的橙色圆形。", "color": "橙" },
	{ "name": "孢子怪", "desc": "死亡爆裂对附近造成范围伤害的粉色尖刺。", "color": "粉" },
	{ "name": "冰霜射手", "desc": "发射减速弹的淡蓝六角，命中玩家移速减半。", "color": "淡蓝" },
	{ "name": "精英·狂战士", "desc": "高速近战精英，接触伤害 4。", "color": "红金" },
	{ "name": "精英·死灵法师", "desc": "周期召唤小怪的精英。", "color": "紫金" },
	{ "name": "精英·巨盾者", "desc": "三倍血量的肉盾精英。", "color": "蓝金" },
	{ "name": "精英·疾风刺客", "desc": "每 2.2 秒瞬移贴近玩家的精英。", "color": "白金" },
	{ "name": "精英·毒巫医", "desc": "发射毒弹使玩家中毒的精英。", "color": "绿金" },
	{ "name": "BOSS·巨魔", "desc": "高血近战，周期高速冲锋。", "color": "绿" },
	{ "name": "BOSS·多头蛇", "desc": "频繁扇形弹幕。", "color": "青" },
	{ "name": "BOSS·荆棘兽", "desc": "范围脉冲伤害。", "color": "橙" },
	{ "name": "BOSS·巫妖", "desc": "周期召唤小怪。", "color": "紫" },
	{ "name": "BOSS·蠕虫王", "desc": "死亡分裂四只小蠕虫。", "color": "红" },
	{ "name": "BOSS·恶魔领主", "desc": "烈焰范围伤害 + 火弹扇形。", "color": "火红" },
	{ "name": "BOSS·寒冰女皇", "desc": "冰霜领域减速 + 冻结弹。", "color": "冰蓝" },
]

const WEAPONS := [
	{ "name": "破旧手枪", "desc": "初始远程武器，简单可靠。" },
	{ "name": "短刃", "desc": "近战连击+剑气，可叠流血与减速。" },
	{ "name": "左轮手枪", "desc": "连射+转盘，可点燃/穿透/锁定。" },
	{ "name": "鞭子", "desc": "范围连抽，可减速/吸血/藤蔓连抽。" },
	{ "name": "法杖", "desc": "散射法术，可冰霜冻结/闪电连锁。" },
	{ "name": "分裂者", "desc": "分裂弹 + 二次分裂/破片/制导。" },
	{ "name": "黑洞枪", "desc": "黑洞控场，虚空侵蚀/坍缩/时间停滞。" },
	{ "name": "回旋镖", "desc": "往返穿透，多镖/磁吸/破甲。" },
]

var _main: Main
var _content: VBoxContainer
var _tab_buttons: Dictionary = {}

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.add_child(UiStyle.fullscreen_bg())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	bg.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	vbox.add_child(UiStyle.big_title("图鉴"))
	# Tab 行。
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	vbox.add_child(tabs)
	for t in [["monsters", "怪物"], ["weapons", "武器"], ["items", "道具"], ["talents", "天赋树"]]:
		var btn := Button.new()
		btn.text = t[1]
		btn.pressed.connect(_on_tab.bind(t[0]))
		_tab_buttons[t[0]] = btn
		tabs.add_child(btn)
	# 内容区（滚动，图鉴信息量大允许）。
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.section(0))
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 4)
	panel.add_child(_content)
	scroll.add_child(panel)
	vbox.add_child(scroll)
	var close := Button.new()
	close.text = "关闭（Esc）"
	close.pressed.connect(_on_close)
	vbox.add_child(close)
	_on_tab("monsters")

func _on_tab(tab: String) -> void:
	for key in _tab_buttons:
		_tab_buttons[key].modulate = Color(0.6, 1.0, 0.6) if key == tab else Color(1, 1, 1)
	match tab:
		"monsters":
			_show_list(_monster_rows())
		"weapons":
			_show_list(_weapon_rows())
		"items":
			_show_items()
		"talents":
			_show_talents()

func _show_list(rows: Array) -> void:
	for child in _content.get_children():
		child.queue_free()
	for r in rows:
		var label := Label.new()
		label.text = r
		label.add_theme_font_size_override("font_size", 16)
		_content.add_child(label)

func _monster_rows() -> Array:
	var rows := []
	for m in MONSTERS:
		rows.append("[%s] %s —— %s" % [m.color, m.name, m.desc])
	return rows

func _weapon_rows() -> Array:
	var rows := []
	for w in WEAPONS:
		rows.append("%s：%s" % [w.name, w.desc])
	return rows

func _show_items() -> void:
	for child in _content.get_children():
		child.queue_free()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for item_id in ItemDefs.all_ids():
		var card := UiStyle.item_card()
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		card.add_child(v)
		v.add_child(UiStyle.item_icon(ItemDefs.icon(item_id), 30))
		var name_label := UiStyle.card_label("[%s] %s" % [ItemDefs.rarity_name(item_id), ItemDefs.name(item_id)], ItemDefs.rarity_color(item_id))
		name_label.add_theme_font_size_override("font_size", 12)
		v.add_child(name_label)
		var desc_label := UiStyle.card_label(ItemDefs.desc(item_id))
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(desc_label)
		grid.add_child(card)

func _show_talents() -> void:
	for child in _content.get_children():
		child.queue_free()
	var hint := Label.new()
	hint.text = "选择武器查看其天赋树"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(hint)
	var list := HBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	_content.add_child(list)
	for wid in ["blade", "revolver", "whip", "staff", "splitter", "black_hole_gun", "boomerang"]:
		var btn := Button.new()
		btn.text = _main.weapon_name(wid)
		btn.pressed.connect(_on_weapon_talent.bind(wid))
		list.add_child(btn)
	# 默认显示短刃。
	_show_weapon_tree("blade")

var _tree_view: Control

func _on_weapon_talent(wid: String) -> void:
	_show_weapon_tree(wid)

func _show_weapon_tree(wid: String) -> void:
	if _tree_view != null and is_instance_valid(_tree_view):
		_tree_view.queue_free()
	_tree_view = TREE_VIEW_SCRIPT.new()
	var tree := TalentTree.new()
	_content.add_child(_tree_view)
	_tree_view.refresh(tree, wid, _main.weapon_name(wid))

func _on_close() -> void:
	_main.close_bestiary()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_main.close_bestiary()
