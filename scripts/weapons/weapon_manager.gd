extends Node2D
## 选择瞄准目标（AUTO：最近敌人；MANUAL：鼠标）并驱动子武器。
## 挂在玩家的 Node2D 子节点上，武器是它的子节点。

enum AttackMode { AUTO, MANUAL }

signal attack_mode_changed(mode: int)

@export var attack_mode: AttackMode = AttackMode.AUTO

var _weapons: Array[Node] = []

func _ready() -> void:
	for child in get_children():
		if child.has_method("set_aim_direction") and child.has_method("set_firing"):
			_weapons.append(child)

func _process(_delta: float) -> void:
	var player := get_parent() as CharacterBody2D
	if not is_instance_valid(player):
		return

	var aim_dir: Vector2
	if attack_mode == AttackMode.AUTO:
		aim_dir = _nearest_enemy_dir(player)
	else:
		aim_dir = (get_global_mouse_position() - player.global_position).normalized()

	var firing := aim_dir != Vector2.ZERO
	if attack_mode == AttackMode.MANUAL:
		firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	for weapon in _weapons:
		weapon.set_aim_direction(aim_dir)
		weapon.set_firing(firing)
		weapon.set_level(player.weapon_levels.get(weapon.weapon_id, 1))
		weapon.set_stats(player.attack_speed_mult, player.attack_range_mult, player.damage_mult)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_attack_mode"):
		toggle_mode()
		get_viewport().set_input_as_handled()

func toggle_mode() -> void:
	attack_mode = AttackMode.MANUAL if attack_mode == AttackMode.AUTO else AttackMode.AUTO
	attack_mode_changed.emit(attack_mode)

func _nearest_enemy_dir(player: Node2D) -> Vector2:
	var best_dir := Vector2.ZERO
	var best_dist_sq := INF
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var delta_v := enemy.global_position - player.global_position
		var dist_sq := delta_v.length_squared()
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_dir = delta_v.normalized()
	return best_dir
