class_name Fx
extends RefCounted
## 战斗特效静态工厂：在指定位置实例化特效节点（命中爆闪 / 伤害数字 / 死亡粒子 / 屏幕震动）。
## 纯视觉并行，不影响伤害数值与状态；无头测试下特效自毁不影响断言。
## 性能保护：全局特效节点存活上限 MAX_FX，满级弹幕海时超限直接跳过，避免节点爆炸。

const MAX_FX := 120
static var _alive := 0

static func _spawn(node: Node2D, pos: Vector2, tree: SceneTree) -> void:
	if tree == null or tree.current_scene == null:
		return
	if _alive >= MAX_FX:
		return
	_alive += 1
	node.tree_exited.connect(_on_fx_exited)
	tree.current_scene.add_child(node)
	node.global_position = pos

static func _on_fx_exited() -> void:
	_alive = maxi(_alive - 1, 0)

## 命中爆闪。
static func hit(pos: Vector2, tree: SceneTree, crit := false) -> void:
	var fx := HitFx.new()
	fx.setup(Color(1.0, 0.9, 0.55) if crit else Color(0.9, 0.95, 1.0))
	_spawn(fx, pos, tree)

## 上飘伤害数字（普通 / 暴击橙黄大号）。
static func number(pos: Vector2, tree: SceneTree, text: String, crit := false) -> void:
	var dn := DamageNumber.new()
	dn.setup(text, crit)
	_spawn(dn, pos, tree)

## 死亡粒子。
static func death(pos: Vector2, tree: SceneTree, color: Color) -> void:
	var df := DeathFx.new()
	df.setup(color)
	_spawn(df, pos, tree)

## 屏幕震动（玩家 Camera2D）。
static func shake(tree: SceneTree, amount: float) -> void:
	var player := tree.get_first_node_in_group("player")
	if player != null and player.has_method("shake"):
		player.shake(amount)
