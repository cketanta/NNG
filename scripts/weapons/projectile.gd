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

# 各武器子弹的贴图（占位 SVG，后续换正式美术只需替换文件）。
const TEX_STAFF := preload("res://assets/projectiles/staff_bullet.svg")
const TEX_SPLITTER := preload("res://assets/projectiles/splitter_bullet.svg")
const TEX_SPLITTER_CHILD := preload("res://assets/projectiles/splitter_child.svg")
const TEX_BLACK_HOLE := preload("res://assets/projectiles/black_hole_bullet.svg")
const TEX_ENEMY := preload("res://assets/projectiles/enemy_bullet.svg")
const TEX_PISTOL := preload("res://assets/projectiles/pistol_bullet.svg")
const TEX_REVOLVER := preload("res://assets/projectiles/revolver_bullet.svg")
const TEX_BLADE_AIR := preload("res://assets/projectiles/blade_air_wave.svg")

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
var _visual_type := "default"  # 子弹贴图类型（staff/pistol/revolver/blade_air/splitter/splitter_child/black_hole_gun）
var _homing_deg := 0.0      # 追踪强度：每帧最大转向角度（0=不追踪，枪斗术弱/智能制导强）

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

## 设置子弹贴图类型（不同武器的子弹视觉不同）。
func set_visual_type(type: String) -> void:
	_visual_type = type

## 设置追踪强度：每帧朝最近敌人最大转向角度（枪斗术弱 / 智能制导强）。
func set_homing(deg_per_frame: float) -> void:
	_homing_deg = maxf(deg_per_frame, 0.0)

## 黑洞枪：命中敌人在命中点生成黑洞。
func set_spawn_black_hole(radius: float) -> void:
	_spawn_black_hole = true
	_black_hole_radius = radius

## 黑洞在本弹进入其吸引范围时调用。
func apply_pull(center: Node2D, speed: float) -> void:
	_pull_target = center
	_pull_speed = speed

func _physics_process(delta: float) -> void:
	if _homing_deg > 0.0 and _friendly:
		_apply_homing(delta)
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
	# 敌方弹固定用敌方贴图；友方弹按武器类型选贴图，未设置类型则回退到原蓝色圆。
	if not _friendly:
		_draw_texture_centered(TEX_ENEMY, 16.0)
		return
	var tex := TEX_STAFF
	var size := 18.0
	match _visual_type:
		"splitter":
			tex = TEX_SPLITTER
		"splitter_child":
			tex = TEX_SPLITTER_CHILD
		"black_hole_gun":
			tex = TEX_BLACK_HOLE
			size = 16.0
		"staff":
			tex = TEX_STAFF
		"pistol":
			tex = TEX_PISTOL
			size = 12.0
		"revolver":
			tex = TEX_REVOLVER
			size = 14.0
		"blade_air":
			tex = TEX_BLADE_AIR
			size = 22.0
		_:
			_draw_fallback_ball()
			return
	_draw_texture_centered(tex, size)

func _draw_texture_centered(tex: Texture2D, size: float) -> void:
	# 分裂小弹节点自带 0.65 缩放，这里画正常大小即可。
	draw_texture_rect(tex, Rect2(-size * 0.5, -size * 0.5, size, size), false)

func _draw_fallback_ball() -> void:
	var radius := 3.0 if _is_small else 5.0
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.8, 1.0))
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
		child.set_visual_type("splitter_child")
		child.global_position = global_position
		get_tree().current_scene.add_child(child)

func _spawn_black_hole_at(pos: Vector2) -> void:
	if _black_hole_scene == null:
		_black_hole_scene = load(BLACK_HOLE_SCENE_PATH)
	var hole := _black_hole_scene.instantiate()
	hole.radius = _black_hole_radius
	get_tree().current_scene.add_child(hole)
	hole.global_position = pos

## 追踪：朝最近敌人逐步转向（幅度受 _homing_deg 限制）。
func _apply_homing(delta: float) -> void:
	var best: Node2D = null
	var best_dsq := INF
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dsq := global_position.distance_squared_to(enemy.global_position)
		if dsq < best_dsq:
			best_dsq = dsq
			best = enemy
	if best == null:
		return
	var to_target := best.global_position - global_position
	if to_target.length_squared() < 0.001:
		return
	var diff := wrapf(to_target.angle() - _direction.angle(), -PI, PI)
	var max_turn := deg_to_rad(_homing_deg) * delta * 60.0
	_direction = _direction.rotated(clampf(diff, -max_turn, max_turn))

## 玩家受击盒与敌方弹重叠时调用。
func get_damage_value() -> int:
	return _damage
