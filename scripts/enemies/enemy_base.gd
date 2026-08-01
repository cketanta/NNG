extends CharacterBody2D
## 所有敌人的基类：血量、受伤、死亡，以及经验/金币掉落值。

signal died(global_pos: Vector2, xp_value: int, gold_value: int)
signal hp_changed(current: int, max_hp: int)

@export var max_hp: int = 1
@export var speed: float = 100.0
@export var contact_damage: int = 1
@export var xp_value: int = 1
@export var gold_value: int = 2
@export var color := Color(1.0, 0.35, 0.35)  # 占位填充色

const PULL_TRAP_RADIUS := 26.0  # 距黑洞中心低于该距离时，敌人改为在中心翻搅而非叠成一团

var hp: int
var _player: Node2D = null
var _pull_active := false
var _pull_center := Vector2.ZERO
var _pull_force := 0.0
var _pull_phase := 0.0
var _pull_jitter_radius := 6.0
var _pull_twitch_time := 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player") as Node2D

## 随波次变强（在 add_child 之前调用）。
func apply_wave_scale(wave: int) -> void:
	max_hp += maxi(0, wave - 1)
	xp_value += (wave - 1) / 3
	gold_value += (wave - 1) / 3

## 应用难度调整（血量与攻击力，在 add_child 之前调用）。
func apply_difficulty(hp_mult: float, attack_mult: float) -> void:
	max_hp = maxi(1, int(round(max_hp * hp_mult)))
	contact_damage = maxi(1, int(ceil(contact_damage * attack_mult)))

func get_player() -> Node2D:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player

func direction_to_player() -> Vector2:
	var target := get_player()
	if not is_instance_valid(target):
		return Vector2.ZERO
	var to_target := target.global_position - global_position
	if to_target.length_squared() < 0.001:
		return Vector2.ZERO
	return to_target.normalized()

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		die()

## 移动驱动：黑洞拉拽生效时覆盖敌人自身的 AI；靠近核心时改为围绕中心翻搅（不叠成一团）。
func _apply_movement(desired: Vector2) -> void:
	if _pull_active:
		var to_center := _pull_center - global_position
		var dist := to_center.length()
		if dist <= PULL_TRAP_RADIUS:
			# 核心附近小幅翻搅，避免叠成一团。
			_pull_twitch_time += get_physics_process_delta_time()
			global_position = _pull_center + Vector2(
				sin(_pull_twitch_time * 7.0 + _pull_phase),
				cos(_pull_twitch_time * 9.0 + _pull_phase)) * _pull_jitter_radius
			velocity = Vector2.ZERO
			return
		velocity = to_center.normalized() * _pull_force
	else:
		velocity = desired
	move_and_slide()

func set_pull(center: Vector2, force: float) -> void:
	_pull_active = true
	_pull_center = center
	_pull_force = force
	# 随机化翻搅相位/幅度，让多只怪错开而不是叠在同一点。
	_pull_phase = randf() * TAU
	_pull_jitter_radius = randf_range(5.0, 12.0)

func clear_pull() -> void:
	_pull_active = false

func die() -> void:
	died.emit(global_position, xp_value, gold_value)
	queue_free()

## 玩家受击盒检测到该敌人重叠时调用。
func get_contact_damage_value() -> int:
	return contact_damage

func _draw() -> void:
	# 占位彩色圆 + 深色描边；以后换成贴图。
	draw_circle(Vector2.ZERO, 15.0, color.darkened(0.5))
	draw_circle(Vector2.ZERO, 14.0, color)
