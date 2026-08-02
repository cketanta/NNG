extends Node2D
## 气刃大回旋：白色环形震荡波，从玩家处扩散，越扩散越细越淡直至消失。
## 伤害不依赖物理碰撞（环宽可能小于每帧位移导致 Area2D 跳过敌人），改用每帧手动距离检测：
## 敌人位于当前环带（内径~外径）内且未命中过则造成一次伤害。

var _damage := 1
var _speed := 300.0      # 扩散速度（px/s）
var _max_radius := 400.0 # 扩散到该半径后消失
var _radius := 8.0       # 当前内径
var _thickness := 14.0   # 初始环宽（随扩散变细）

var _hit_enemies := {}   # 已命中敌人，防重复

func setup(damage: int, speed: float, max_radius: float) -> void:
	_damage = damage
	_speed = speed
	_max_radius = max_radius

func _process(delta: float) -> void:
	_radius += _speed * delta
	if _radius >= _max_radius:
		queue_free()
		return
	_check_hits()
	queue_redraw()

## 当前环宽（随半径扩大而变细）。
func _current_thickness() -> float:
	return maxf(_thickness * (1.0 - _radius / _max_radius), 2.0)

## 每帧距离检测：处于环带内的敌人受到一次伤害。
func _check_hits() -> void:
	var outer := _radius + _current_thickness()
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if _hit_enemies.has(enemy) or not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist >= _radius and dist <= outer:
			_hit_enemies[enemy] = true
			if enemy.has_method("take_damage"):
				enemy.take_damage(_damage)

func _draw() -> void:
	# 白色圆环：宽度随扩散变细，透明度随扩散降低（越远越淡直至消失）。
	var thickness := _current_thickness()
	var alpha: float = 0.9 * (1.0 - _radius / _max_radius)
	draw_arc(Vector2.ZERO, _radius + thickness * 0.5, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, alpha), thickness, true)
