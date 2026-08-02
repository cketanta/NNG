extends Node2D
## 选择瞄准目标（AUTO：最近敌人；MANUAL：鼠标）并驱动当前激活的攻击方式。
## 攻击方式节点挂在玩家中心（position=0），发射中心即玩家自身（不再环绕旋转）。
## 多武器环绕旋转框架保留（本文件重写为单攻击控制，原环绕逻辑移除但其它脚本未删）。

enum AttackMode { AUTO, MANUAL }

signal attack_mode_changed(mode: int)

@export var attack_mode: AttackMode = AttackMode.AUTO

var active_attack_id := "pistol"  # 当前激活的攻击方式 id

var _attacks: Array[Node2D] = []

func _ready() -> void:
	for child in get_children():
		if child.has_method("set_aim_direction") and child.has_method("set_firing"):
			_attacks.append(child as Node2D)
	set_active_attack(active_attack_id)

## 切换当前激活的攻击方式（首次升级选短刃/左轮时调用）。
func set_active_attack(id: String) -> void:
	active_attack_id = id
	for attack in _attacks:
		var is_active: bool = attack.weapon_id == id
		attack.set_process(is_active)
		if not is_active:
			attack.visible = false  # 非激活隐藏；激活的可见性由攻击节点每帧跟随玩家控制

func _process(_delta: float) -> void:
	var player := get_parent() as CharacterBody2D
	if not is_instance_valid(player):
		return

	var target_pos: Vector2
	if attack_mode == AttackMode.AUTO:
		target_pos = _nearest_enemy_pos(player)
	else:
		target_pos = get_global_mouse_position()

	for attack in _attacks:
		if attack.weapon_id != active_attack_id:
			continue
		# 发射中心 = 玩家自身：从玩家位置指向目标。
		var to_target := target_pos - player.global_position
		var wdir := Vector2.ZERO
		if to_target.is_finite() and to_target.length_squared() > 0.0001:
			wdir = to_target.normalized()
		attack.set_aim_direction(wdir)
		var firing := wdir != Vector2.ZERO
		if attack_mode == AttackMode.MANUAL:
			firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		attack.set_firing(firing)
		# 攻击方式终值由其自身每帧按玩家天赋树重算（见各攻击方式 _apply_talents）。

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_attack_mode"):
		toggle_mode()
		get_viewport().set_input_as_handled()

func toggle_mode() -> void:
	attack_mode = AttackMode.MANUAL if attack_mode == AttackMode.AUTO else AttackMode.AUTO
	attack_mode_changed.emit(attack_mode)

## 停止整条攻击链：停掉 WeaponManager 与所有攻击方式节点。
func halt() -> void:
	for attack in _attacks:
		attack.set_process(false)
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
