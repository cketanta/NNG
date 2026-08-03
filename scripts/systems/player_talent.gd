class_name PlayerTalent
extends RefCounted
## 人物天赋（树状多维）：内部持有一个 TalentTree 实例，固定用 "player" 树。
## 与经验系统挂钩：升级 +1 人物天赋点。解锁走树状节点（含前置/互斥/三选一）。
## 效果通过 effects() 聚合，作用于所有武器与玩家自身。

const TREE_ID := "player"

## 内部天赋树实例（owned / 树状节点由它管理）。
var tree := TalentTree.new()

## 当前可用人物天赋点（升级 +1）。setter 同步到内部树，保证 main 里 `points += 1` 直接生效。
var points: int = 0:
	set(value):
		points = maxi(value, 0)
		tree.points = points

func _init() -> void:
	tree.points = points

## 解锁一个人物天赋节点（需在可选集合内且点数充足）。
func unlock(talent_id: String) -> bool:
	if not tree.unlock(TREE_ID, talent_id):
		return false
	points = tree.points
	return true

## 已拥有的人物天赋节点 id 列表。
func owned_ids() -> Array:
	return tree.owned_ids(TREE_ID)

## 当前可选的人物天赋节点集合。
func selectable() -> Array:
	return tree.selectable(TREE_ID)

## 从可选集合随机抽 n 个（三选一加点用）。
func draw_choices(n: int = 3) -> Array:
	return tree.draw_choices(TREE_ID, n)

## 是否已点满人物树。
func is_fully_unlocked() -> bool:
	return tree.is_fully_unlocked(TREE_ID)

## 聚合人物树全部效果（结构见 TalentTree.aggregate）。
func effects() -> Dictionary:
	return tree.aggregate(TREE_ID)
