extends Node2D
## 敌人掉落的经验宝石。进入磁吸范围后飞向玩家并计分。
## 用纯距离判断而非物理，因此无需碰撞配置。

signal collected(value: int)

@export var value: int = 1

const MAGNET_RADIUS := 300.0
const PICKUP_DISTANCE := 18.0
const MAX_SPEED := 500.0

var _age := 0.0
var _magnet_speed := 0.0

func _ready() -> void:
	# 随机初始延迟，避免一簇宝石同时移动。
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
	if dist < MAGNET_RADIUS:
		_magnet_speed = lerpf(_magnet_speed, MAX_SPEED, delta * 8.0)
		var step := _magnet_speed * delta
		if dist <= maxf(step, PICKUP_DISTANCE):
			collected.emit(value)
			queue_free()
		else:
			global_position += to_player.normalized() * step

func _draw() -> void:
	# 经验宝石：光晕 + 渐变主体 + 旋转高光。
	var t := Time.get_ticks_msec() / 1000.0
	draw_circle(Vector2.ZERO, 11.0, Color(0.2, 0.9, 0.7, 0.18))
	draw_circle(Vector2.ZERO, 6.5, Color(0.1, 0.6, 0.45))
	draw_circle(Vector2.ZERO, 5.5, Color(0.2, 0.9, 0.7))
	draw_circle(Vector2.ZERO, 3.5, Color(0.5, 1.0, 0.85))
	var a := t * 3.0
	draw_circle(Vector2(cos(a), sin(a)) * 2.6, 1.3, Color(0.95, 1.0, 0.95, 0.9))
