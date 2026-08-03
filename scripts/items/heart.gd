extends Node2D
## 敌人掉落的红心。进入磁吸范围后飞向玩家并回复 1 点血量。
## 磁吸/拾取行为与经验宝石、金币一致。

signal collected(value: int)

@export var value: int = 1

const MAGNET_RADIUS := 300.0
const PICKUP_DISTANCE := 18.0
const MAX_SPEED := 500.0

var _age := 0.0
var _magnet_speed := 0.0

func _ready() -> void:
	# 随机初始延迟，避免一簇红心同时移动。
	_age = randf() * 0.5

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()  # 旋转高光动画
	if _age < 0.3:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	# 磁吸范围随玩家等级提升（每级 +10，越强拾取越轻松）。
	if dist < MAGNET_RADIUS + player.level * 10.0:
		_magnet_speed = lerpf(_magnet_speed, MAX_SPEED, delta * 8.0)
		var step := _magnet_speed * delta
		if dist <= maxf(step, PICKUP_DISTANCE):
			collected.emit(value)
			queue_free()
		else:
			global_position += to_player.normalized() * step

func _draw() -> void:
	# 红心：光晕 + 红心 + 旋转高光。
	var t := Time.get_ticks_msec() / 1000.0
	draw_circle(Vector2.ZERO, 11.0, Color(0.9, 0.25, 0.3, 0.16))
	draw_circle(Vector2(-2.5, -1.5), 3.4, Color(0.95, 0.2, 0.28))
	draw_circle(Vector2(2.5, -1.5), 3.4, Color(0.95, 0.2, 0.28))
	var tri := PackedVector2Array([
		Vector2(-4.5, -1.0),
		Vector2(4.5, -1.0),
		Vector2(0.0, 4.5),
	])
	draw_colored_polygon(tri, Color(0.95, 0.2, 0.28))
	var a := t * 2.5
	draw_circle(Vector2(cos(a), sin(a)) * 2.0, 1.0, Color(1.0, 0.85, 0.85, 0.85))
