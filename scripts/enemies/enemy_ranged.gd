extends "res://scripts/enemies/enemy_base.gd"
## 远程敌人：保持射程距离，周期向玩家发射弹幕。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")

@export var preferred_range: float = 180.0
@export var fire_cooldown: float = 2.0
@export var projectile_speed: float = 350.0

var _fire_timer := 0.0

func _physics_process(delta: float) -> void:
	queue_redraw()  # 让瞄准指示点始终指向玩家
	var target := get_player()
	if not is_instance_valid(target):
		_apply_movement(Vector2.ZERO)
		return

	var to_target := target.global_position - global_position
	var dist := to_target.length()

	var desired := Vector2.ZERO
	if dist > preferred_range + 20.0:
		desired = to_target.normalized() * speed
	elif dist < preferred_range - 20.0:
		desired = -to_target.normalized() * speed * 0.5
	_apply_movement(desired)

	_fire_timer += delta
	if dist <= preferred_range and _fire_timer >= fire_cooldown:
		_fire_timer = 0.0
		fire(target.global_position)

func fire(target_pos: Vector2) -> void:
	var dir := (target_pos - global_position).normalized()
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.setup(dir, projectile_speed, 1, false)
	projectile.global_position = global_position + dir * 16.0
	get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	super._draw()
	# 标记瞄准玩家方向的小点。
	var target := get_player()
	if is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		draw_circle(dir * 10.0, 3.0, Color(0.3, 0.9, 0.4))
