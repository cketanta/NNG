extends Node2D
## 转盘枪手特殊攻击体：被扔到目标位置，旋转攻击一周后自毁。
## 由 revolver.gd 的 start_spinner() 实例化并传入子弹参数。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")

var _damage := 1
var _speed := 520.0
var _total := 8    # 一圈发射子弹总数
var _fired := 0
var _interval := 0.1  # 每发间隔（攻速越快越短）
var _timer := 0.0
var _homing := 0.0

## 初始化：center 为目标位置（鼠标右键位置），total 与 interval 由攻速决定。
func setup(center: Vector2, damage: int, speed: float, total: int, interval: float, homing: float) -> void:
	global_position = center
	_damage = damage
	_speed = speed
	_total = maxi(total, 4)
	_interval = maxf(interval, 0.02)
	_homing = homing
	_fired = 0
	_timer = 0.0

func _process(delta: float) -> void:
	_timer += delta
	while _timer >= _interval:
		_timer -= _interval
		_fire()
		_fired += 1
		if _fired >= _total:
			queue_free()
			return

func _fire() -> void:
	var dir := Vector2.from_angle(TAU * float(_fired) / float(_total))
	var bullet := PROJECTILE_SCENE.instantiate()
	bullet.setup(dir, _speed, _damage, true)
	bullet.set_visual_type("revolver")
	if _homing > 0.0:
		bullet.set_homing(_homing)
	bullet.global_position = global_position  # 从转盘位置发射
	get_tree().current_scene.add_child(bullet)

func _draw() -> void:
	# 转盘视觉：旋转的金色圆环 + 中心亮白点。
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.4, 0.9), 2.0)
	draw_circle(Vector2.ZERO, 6.0, Color(0.9, 0.95, 1.0, 0.9))
