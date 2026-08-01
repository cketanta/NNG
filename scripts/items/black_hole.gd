extends Node2D
## 黑洞枪命中产生的黑洞：把范围内所有子弹与怪物吸向中心。
## 子弹与怪物在核心附近抽搐（不消失、不叠成一团），双方子弹仍可造成伤害，
## 黑洞本身 0 伤害。一圈旋转粒子指示吸引范围（随武器等级扩大）。

const ENEMY_GROUP := "enemies"
const BULLET_GROUPS := ["enemy_projectiles", "friendly_projectiles"]
const RING_DOTS := 14

@export var radius: float = 130.0
@export var bullet_pull_speed: float = 560.0
@export var enemy_pull_speed: float = 260.0
@export var lifetime: float = 4.0

var _life := 0.0
var _rotate_angle := 0.0

func _process(delta: float) -> void:
	_life += delta
	if _life >= lifetime:
		get_tree().call_group(ENEMY_GROUP, "clear_pull")
		queue_free()
		return

	_rotate_angle += delta * 1.5
	queue_redraw()

	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < radius:
			enemy.set_pull(global_position, enemy_pull_speed)

	for group_name in BULLET_GROUPS:
		for bullet in get_tree().get_nodes_in_group(group_name):
			if is_instance_valid(bullet) and global_position.distance_to(bullet.global_position) < radius:
				bullet.apply_pull(self, bullet_pull_speed)

func _draw() -> void:
	# 吸引范围指示：`radius` 上画一圈淡环 + 旋转粒子（该范围随黑洞枪等级扩大）。
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.7, 0.4, 1.0, 0.12), 1.0)
	for i in range(RING_DOTS):
		var a := _rotate_angle + TAU * float(i) / RING_DOTS
		draw_circle(Vector2.from_angle(a) * radius, 2.5, Color(0.75, 0.45, 1.0, 0.7))
	# 核心：深色本体 + 发光边缘。
	draw_circle(Vector2.ZERO, 12.0, Color(0.1, 0.0, 0.15, 1.0))
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(0.7, 0.4, 1.0, 0.8), 2.0)
