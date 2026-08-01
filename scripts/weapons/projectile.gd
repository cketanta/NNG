extends Area2D
## 通用弹幕。friendly=true 从玩家飞出命中敌人；friendly=false 是敌方弹，
## 由玩家受击盒检测并消耗。额外行为：命中分裂（分裂者）、命中生成黑洞（黑洞枪）、
## 被黑洞吸附（核心处抽搐不消失）、渲染成更小的分裂小弹。

const LAYER_FRIENDLY := 4           # 玩家弹幕所在的碰撞层（1 基）
const LAYER_ENEMY := 3              # 敌人所在的碰撞层（1 基）
const LAYER_ENEMY_PROJECTILE := 5   # 敌方弹幕所在的碰撞层（1 基）

const TRAP_RADIUS := 26.0             # 黑洞：低于此距离子弹开始抽搐
const CHILD_SCENE_PATH := "res://scenes/weapons/projectile.tscn"
const BLACK_HOLE_SCENE_PATH := "res://scenes/items/black_hole.tscn"

var _direction := Vector2.RIGHT
var _speed := 500.0
var _damage := 1
var _friendly := true
var _life := 3.0
var _split_count := 0
var _is_small := false
var _spawn_black_hole := false
var _black_hole_radius := 130.0
var _already_hit := false    # 每颗子弹只命中一只怪、命中即消失（不穿透存活、不累积）

var _pull_target: Node2D = null
var _pull_speed := 0.0
var _twitch_time := 0.0

var _child_scene: PackedScene
var _black_hole_scene: PackedScene

func setup(dir: Vector2, speed: float, damage: int, friendly: bool) -> void:
	_direction = dir.normalized()
	_speed = speed
	_damage = damage
	_friendly = friendly
	_life = 3.0
	if friendly:
		collision_layer = 1 << (LAYER_FRIENDLY - 1)
		collision_mask = 1 << (LAYER_ENEMY - 1)
		body_entered.connect(_on_body_entered)
		add_to_group("friendly_projectiles")
	else:
		collision_layer = 1 << (LAYER_ENEMY_PROJECTILE - 1)
		collision_mask = 0
		add_to_group("enemy_projectiles")

## 延长飞行距离（用于攻击范围天赋）。
func set_range_mult(multiplier: float) -> void:
	_life = 3.0 * maxf(multiplier, 0.1)

## 分裂者：命中敌人后向全方向分裂出这么多枚小弹。
func set_split_on_hit(count: int) -> void:
	_split_count = count

## 分裂小弹：更小、不再分裂。
func set_small_child() -> void:
	_is_small = true
	scale = Vector2(0.65, 0.65)

## 黑洞枪：命中敌人在命中点生成黑洞。
func set_spawn_black_hole(radius: float) -> void:
	_spawn_black_hole = true
	_black_hole_radius = radius

## 黑洞在本弹进入其吸引范围时调用。
func apply_pull(center: Node2D, speed: float) -> void:
	_pull_target = center
	_pull_speed = speed

func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	if is_instance_valid(_pull_target):
		var center := _pull_target.global_position
		var dist := global_position.distance_to(center)
		if dist > TRAP_RADIUS:
			global_position = global_position.move_toward(center, _pull_speed * delta)
		else:
			# 围绕核心抽搐而不消失；碰撞检测仍生效。
			_twitch_time += delta
			global_position = center + Vector2(sin(_twitch_time * 9.0), cos(_twitch_time * 13.0)) * 3.0
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _draw() -> void:
	var radius := 3.0 if _is_small else 5.0
	var color := Color(0.45, 0.8, 1.0) if _friendly else Color(0.35, 0.9, 0.45)
	draw_circle(Vector2.ZERO, radius, color)
	if not _is_small:
		draw_circle(Vector2.ZERO, radius * 0.4, Color(1.0, 1.0, 1.0, 0.9))

func _on_body_entered(body: Node2D) -> void:
	if _already_hit:
		return
	_already_hit = true
	if body.has_method("take_damage"):
		body.take_damage(_damage)
		if _friendly:
			if _split_count > 0:
				_spawn_split_children()
			if _spawn_black_hole:
				_spawn_black_hole_at(global_position)
	queue_free()

func _spawn_split_children() -> void:
	if _child_scene == null:
		_child_scene = load(CHILD_SCENE_PATH)
	for i in range(_split_count):
		var dir := _direction.rotated(TAU * float(i) / float(_split_count))
		var child := _child_scene.instantiate()
		child.setup(dir, _speed * 0.9, _damage, true)
		child.set_small_child()
		child.global_position = global_position
		get_tree().current_scene.add_child(child)

func _spawn_black_hole_at(pos: Vector2) -> void:
	if _black_hole_scene == null:
		_black_hole_scene = load(BLACK_HOLE_SCENE_PATH)
	var hole := _black_hole_scene.instantiate()
	hole.radius = _black_hole_radius
	get_tree().current_scene.add_child(hole)
	hole.global_position = pos

## 玩家受击盒与敌方弹重叠时调用。
func get_damage_value() -> int:
	return _damage
