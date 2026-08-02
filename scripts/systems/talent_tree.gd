class_name TalentTree
extends RefCounted
## 攻击方式天赋树数据：两棵树（短刃 blade / 左轮 revolver）。
## 每个天赋：{ id, name, desc, prereq(前置天赋 id，空串=直接可点), conflict(互斥天赋 id，空串=无) }。
## 支持「可选集合」与「抽三选一」：selectable() 算当前可选，draw_choices() 随机抽 3。

const TREES := {
	"blade": [
		{ "id": "blade_range_1", "name": "范围扩大1", "desc": "攻击范围扩大10%", "prereq": "", "conflict": "" },
		{ "id": "blade_range_2", "name": "范围扩大2", "desc": "攻击范围扩大20%", "prereq": "blade_range_1", "conflict": "" },
		{ "id": "blade_range_3", "name": "范围扩大3", "desc": "攻击范围扩大20%", "prereq": "blade_range_2", "conflict": "" },
		{ "id": "blade_range_4", "name": "范围扩大4", "desc": "攻击范围扩大20%", "prereq": "blade_range_3", "conflict": "" },
		{ "id": "blade_sharp_1", "name": "利刃出鞘1", "desc": "攻击力加10%", "prereq": "", "conflict": "" },
		{ "id": "blade_sharp_2", "name": "利刃出鞘2", "desc": "攻击力加10%", "prereq": "blade_sharp_1", "conflict": "" },
		{ "id": "blade_sharp_3", "name": "利刃出鞘3", "desc": "攻击力加10%", "prereq": "blade_sharp_2", "conflict": "" },
		{ "id": "blade_sharp_4", "name": "利刃出鞘4", "desc": "攻击力加10%", "prereq": "blade_sharp_3", "conflict": "" },
		{ "id": "blade_swift_1", "name": "拔刀术1", "desc": "攻速加10%", "prereq": "", "conflict": "" },
		{ "id": "blade_swift_2", "name": "拔刀术2", "desc": "攻速加10%", "prereq": "blade_swift_1", "conflict": "" },
		{ "id": "blade_swift_3", "name": "拔刀术3", "desc": "攻速加10%", "prereq": "blade_swift_2", "conflict": "" },
		{ "id": "blade_air_blade", "name": "气刃斩", "desc": "攻击额外发射一枚弧形气刃（挥砍角度内均匀分布），伤害为挥砍的80%", "prereq": "", "conflict": "blade_berserk" },
		{ "id": "blade_air_1", "name": "气刃专精1", "desc": "发射的气刃数量加1", "prereq": "blade_air_blade", "conflict": "" },
		{ "id": "blade_air_2", "name": "气刃专精2", "desc": "发射的气刃数量加1", "prereq": "blade_air_1", "conflict": "" },
		{ "id": "blade_air_3", "name": "气刃专精3", "desc": "发射的气刃数量加1", "prereq": "blade_air_2", "conflict": "" },
		{ "id": "blade_air_4", "name": "气刃专精4", "desc": "发射的气刃数量加1", "prereq": "blade_air_3", "conflict": "" },
		{ "id": "blade_grand_slash", "name": "气刃大回旋", "desc": "挥砍额外产生一个环形气刃波，造成二倍于挥砍的伤害", "prereq": "blade_air_4", "conflict": "" },
		{ "id": "blade_berserk", "name": "狂战", "desc": "移速加30%，挥砍伤害加20%，攻速加20%，体型变大50%", "prereq": "", "conflict": "blade_air_blade" },
		{ "id": "blade_dual", "name": "双刀流", "desc": "快速产生两次挥砍", "prereq": "blade_berserk", "conflict": "" },
		{ "id": "blade_triple", "name": "三刀流", "desc": "快速产生三次挥砍", "prereq": "blade_dual", "conflict": "" },
		{ "id": "blade_quad", "name": "四刀流", "desc": "快速产生四次挥砍", "prereq": "blade_triple", "conflict": "" },
		{ "id": "blade_maim", "name": "致残", "desc": "攻击到的敌人获得5秒流血效果（最多叠加30层），期间受到攻击时额外受到流血层数点伤害", "prereq": "blade_berserk", "conflict": "" },
		{ "id": "blade_grief", "name": "郁色创伤", "desc": "流血效果最高可叠加至50层", "prereq": "blade_maim", "conflict": "" },
	],
	"revolver": [
		{ "id": "rev_bullet_1", "name": "弹头改良1", "desc": "攻击力加10%", "prereq": "", "conflict": "" },
		{ "id": "rev_bullet_2", "name": "弹头改良2", "desc": "攻击力加10%", "prereq": "rev_bullet_1", "conflict": "" },
		{ "id": "rev_bullet_3", "name": "弹头改良3", "desc": "攻击力加10%", "prereq": "rev_bullet_2", "conflict": "" },
		{ "id": "rev_bullet_4", "name": "弹头改良4", "desc": "攻击力加10%", "prereq": "rev_bullet_3", "conflict": "" },
		{ "id": "rev_mag_1", "name": "弹匣扩容1", "desc": "额外连射一发子弹", "prereq": "", "conflict": "" },
		{ "id": "rev_mag_2", "name": "弹匣扩容2", "desc": "额外连射一发子弹", "prereq": "rev_mag_1", "conflict": "" },
		{ "id": "rev_mag_3", "name": "弹匣扩容3", "desc": "额外连射一发子弹", "prereq": "rev_mag_2", "conflict": "" },
		{ "id": "rev_mag_4", "name": "弹匣扩容4", "desc": "额外连射一发子弹", "prereq": "rev_mag_3", "conflict": "" },
		{ "id": "rev_quick_1", "name": "快枪手1", "desc": "攻速加10%", "prereq": "", "conflict": "" },
		{ "id": "rev_quick_2", "name": "快枪手2", "desc": "攻速加10%", "prereq": "rev_quick_1", "conflict": "" },
		{ "id": "rev_quick_3", "name": "快枪手3", "desc": "攻速加10%", "prereq": "rev_quick_2", "conflict": "" },
		{ "id": "rev_quick_4", "name": "快枪手4", "desc": "攻速加10%", "prereq": "rev_quick_3", "conflict": "" },
		{ "id": "rev_spinner", "name": "转盘枪手", "desc": "右键特殊攻击：扔出手枪到鼠标右键位置，手枪旋转攻击一周（子弹密度由攻速决定），期间无法主动攻击", "prereq": "", "conflict": "" },
		{ "id": "rev_homing_1", "name": "枪斗术", "desc": "子弹添加微弱追踪效果", "prereq": "", "conflict": "" },
		{ "id": "rev_homing_2", "name": "智能制导", "desc": "子弹追踪效果增强", "prereq": "rev_homing_1", "conflict": "" },
	],
}

## 玩家持有的天赋点（升级 +1）。
var points := 0
## 已拥有天赋：tree_id -> { talent_id: bool }。
var owned := {}

func _init() -> void:
	for tree_id: String in TREES.keys():
		owned[tree_id] = {}

## 当前攻击方式 id（"blade" / "revolver"）。
var attack_id := ""

## 天赋定义查询。
func def(tree_id: String, talent_id: String) -> Dictionary:
	for t: Dictionary in TREES.get(tree_id, []):
		if t.id == talent_id:
			return t
	return {}

func is_owned(tree_id: String, talent_id: String) -> bool:
	return owned.get(tree_id, {}).get(talent_id, false)

## 当前可选天赋集合：前置已满足 && 未拥有 && 未与已拥有天赋互斥。
func selectable(tree_id: String) -> Array:
	var result: Array[String] = []
	for t: Dictionary in TREES.get(tree_id, []):
		if is_owned(tree_id, t.id):
			continue
		if t.prereq != "" and not is_owned(tree_id, t.prereq):
			continue
		if t.conflict != "" and is_owned(tree_id, t.conflict):
			continue
		result.append(t.id)
	return result

## 从可选集合随机抽 n 个（不足 n 个则全给）。
func draw_choices(tree_id: String, n: int = 3) -> Array:
	var pool: Array = selectable(tree_id).duplicate()
	pool.shuffle()
	return pool.slice(0, n)

## 解锁一个天赋（需在可选集合内且点数充足），返回是否成功。
func unlock(tree_id: String, talent_id: String) -> bool:
	if points <= 0:
		return false
	if not selectable(tree_id).has(talent_id):
		return false
	owned[tree_id][talent_id] = true
	points -= 1
	return true

## 某树已拥有天赋 id 列表。
func owned_ids(tree_id: String) -> Array:
	var tree_owned: Dictionary = owned.get(tree_id, {})
	return tree_owned.keys().filter(func(id: String) -> bool: return tree_owned[id])

## 某树是否已点满（没有可选项了）。
func is_fully_unlocked(tree_id: String) -> bool:
	return selectable(tree_id).is_empty()
