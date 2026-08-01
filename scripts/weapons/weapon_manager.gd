extends Node2D
## 选择瞄准目标（AUTO：最近敌人；MANUAL：鼠标）并驱动子武器。
## 挂在玩家的 Node2D 子节点上，武器是它的子节点。

enum AttackMode { AUTO, MANUAL }

signal attack_mode_changed(mode: int)

@export var attack_mode: AttackMode = AttackMode.AUTO

const RING_RADIUS := 34.0  # 武器环绕玩家的半径，避免贴图堆叠

var _weapons: Array[Node2D] = []
var _ring_angle := 0.0  # 武器环自转角（缓慢旋转）

func _ready() -> void:
	for child in get_children():
		if child.has_method("set_aim_direction") and child.has_method("set_firing"):
			_weapons.append(child as Node2D)

func _process(_delta: float) -> void:
	var player := get_parent() as CharacterBody2D
	if not is_instance_valid(player):
		return

	# 武器均匀分布在玩家周围的圆周上，缓慢自转，避免贴图堆在一起。
	_ring_angle += _delta * 0.5
	for i in range(_weapons.size()):
		_weapons[i].position = Vector2.from_angle(_ring_angle + TAU * float(i) / float(_weapons.size())) * RING_RADIUS

	var target_pos: Vector2
	if attack_mode == AttackMode.AUTO:
		target_pos = _nearest_enemy_pos(player)
	else:
		target_pos = get_global_mouse_position()

	for weapon in _weapons:
		# 每把武器单独瞄准：从武器自身位置指向目标，避免各武器子弹平行。
		var to_target := target_pos - weapon.global_position
		var wdir := Vector2.ZERO
		if to_target.is_finite() and to_target.length_squared() > 0.0001:
			wdir = to_target.normalized()
		weapon.set_aim_direction(wdir)
		var firing := wdir != Vector2.ZERO
		if attack_mode == AttackMode.MANUAL:
			firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		weapon.set_firing(firing)
		weapon.set_level(player.weapon_levels.get(weapon.weapon_id, 1))
		# 按道具加成计算武器最终属性并下发：攻击力 / 冷却 / 弹速 / 攻击距离。
		var stats: Dictionary = ItemDefs.weapon_final_stats(weapon, player.item_counts)
		weapon.set_stats(stats.damage, stats.cooldown, stats.speed, stats.range)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_attack_mode"):
		toggle_mode()
		get_viewport().set_input_as_handled()

func toggle_mode() -> void:
	attack_mode = AttackMode.MANUAL if attack_mode == AttackMode.AUTO else AttackMode.AUTO
	attack_mode_changed.emit(attack_mode)

## 停止整条武器链：停掉 WeaponManager 与所有子武器。
## 仅停 WeaponManager 不够——子武器自己的 _process 会保留最后的 _firing 继续开火。
func halt() -> void:
	for weapon in _weapons:
		weapon.set_process(false)
	set_process(false)

func _nearest_enemy_pos(player: Node2D) -> Vector2:
	var best_pos := Vector2.INF  # 无敌人时保持无穷，调用方据此不开火
	var best_dist_sq := INF
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dist_sq := enemy.global_position.distance_squared_to(player.global_position)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_pos = enemy.global_position
	return best_pos
