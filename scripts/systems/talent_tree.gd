class_name TalentTree
extends RefCounted
## 天赋树定义 + 已点状态（纯数据，无 UI）。
## 分支按层级前置：tier N 需要先点 tier N-1。

const BRANCH_DEFS: Array[Dictionary] = [
	{ "id": "move_speed", "name": "疾跑", "desc": "移动速度 +10%/级", "tiers": 5 },
	{ "id": "attack_speed", "name": "迅捷", "desc": "攻击速度 +8%/级", "tiers": 5 },
	{ "id": "attack_range", "name": "延伸", "desc": "攻击范围 +12%/级", "tiers": 5 },
	{ "id": "damage", "name": "狂力", "desc": "伤害 +10%/级", "tiers": 5 },
]

var points := 0
var owned: Dictionary = {}  # 分支 id -> 已点到的最高层级（0 = 未点）

func branches() -> Array[Dictionary]:
	return BRANCH_DEFS

func owned_count(branch_id: String) -> int:
	return owned.get(branch_id, 0)

func can_unlock(branch_id: String) -> bool:
	return points > 0 and owned_count(branch_id) < 5

func unlock(branch_id: String) -> bool:
	if not can_unlock(branch_id):
		return false
	owned[branch_id] = owned_count(branch_id) + 1
	points -= 1
	return true

## 所有分支都点满时返回 true（没有可花费的天赋了）。
func is_fully_unlocked() -> bool:
	for branch in branches():
		if owned_count(branch.id) < int(branch["tiers"]):
			return false
	return true
