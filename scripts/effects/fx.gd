class_name Fx
extends RefCounted
## 战斗特效静态工厂：在指定位置实例化特效节点（命中爆闪 / 伤害数字 / 死亡粒子 / 屏幕震动）。
## 纯视觉并行，不影响伤害数值与状态；无头测试下特效自毁不影响断言。

## 命中爆闪。
static func hit(pos: Vector2, tree: SceneTree, crit := false) -> void:
	if tree.current_scene == null:
		return
	var fx := HitFx.new()
	fx.setup(Color(1.0, 0.9, 0.55) if crit else Color(0.9, 0.95, 1.0))
	tree.current_scene.add_child(fx)
	fx.global_position = pos

## 上飘伤害数字（普通 / 暴击橙黄大号）。
static func number(pos: Vector2, tree: SceneTree, text: String, crit := false) -> void:
	if tree.current_scene == null:
		return
	var dn := DamageNumber.new()
	dn.setup(text, crit)
	tree.current_scene.add_child(dn)
	dn.global_position = pos

## 死亡粒子。
static func death(pos: Vector2, tree: SceneTree, color: Color) -> void:
	if tree.current_scene == null:
		return
	var df := DeathFx.new()
	df.setup(color)
	tree.current_scene.add_child(df)
	df.global_position = pos

## 屏幕震动（玩家 Camera2D）。
static func shake(tree: SceneTree, amount: float) -> void:
	var player := tree.get_first_node_in_group("player")
	if player != null and player.has_method("shake"):
		player.shake(amount)
