class_name PlayerTalent
extends RefCounted
## 人物天赋：v1.0 原方案 4 分支线性树，与经验系统挂钩（升级 +1 人物天赋点）。
## 分支：疾跑（移速）/ 迅捷（攻速）/ 延伸（范围）/ 狂力（伤害），各 5 级。

const BRANCHES := [
	{ "id": "move_speed", "name": "疾跑", "desc": "移动速度 +10%/级", "tiers": 5 },
	{ "id": "attack_speed", "name": "迅捷", "desc": "攻击速度 +8%/级", "tiers": 5 },
	{ "id": "attack_range", "name": "延伸", "desc": "攻击范围 +12%/级", "tiers": 5 },
	{ "id": "damage", "name": "狂力", "desc": "伤害 +10%/级", "tiers": 5 },
]

var points := 0
var owned := {}  # 分支 id -> 已点层级（0 = 未点）

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

func is_fully_unlocked() -> bool:
	for b in BRANCHES:
		if owned_count(b.id) < int(b.tiers):
			return false
	return true
