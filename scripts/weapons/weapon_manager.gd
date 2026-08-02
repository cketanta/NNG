extends Node2D
## 多武器管理器：按玩家武器槽位动态实例化武器节点，环绕玩家缓慢旋转。
## 每把武器独立瞄准（从自身位置指向目标），AUTO/MANUAL 切换、halt 停火。
## 武器终值由攻击节点自身每帧按「本武器天赋树 + 人物天赋」重算。

enum AttackMode { AUTO, MANUAL }

signal attack_mode_changed(mode: int)

@export var attack_mode: AttackMode = AttackMode.AUTO

const RING_RADIUS := 34.0  # 武器环绕玩家的半径
const ROTATE_SPEED := 0.5  # 武器环自转角速度（rad/s）
const WEAPON_SCENES := {
	"pistol": preload("res://scenes/weapons/pistol.tscn"),
	"blade": preload("res://scenes/weapons/blade.tscn"),
	"revolver": preload("res://scenes/weapons/revolver.tscn"),
}

var _weapons: Array[Node2D] = []
var _ring_angle := 0.0

## 按玩家武器槽位重建武器节点（购买/合成/出售后调用）。
func rebuild(slots: Array) -> void:
	for w in _weapons:
		if is_instance_valid(w):
			w.free()  # 立即释放，避免 queue_free 延迟造成新旧节点混合
	_weapons.clear()
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if not WEAPON_SCENES.has(slot.id):
			continue
		var inst: Node2D = WEAPON_SCENES[slot.id].instantiate()
		if inst.has_method("set_talent_tree"):
			inst.set_talent_tree(slot.tree)
		if inst.has_method("set_level"):
			inst.set_level(slot.level)
		add_child(inst)
		_weapons.append(inst)

func _process(_delta: float) -> void:
	var player := get_parent() as CharacterBody2D
	if not is_instance_valid(player):
		return
	# 武器均匀分布在玩家周围的圆周上，缓慢自转。
	_ring_angle += _delta * ROTATE_SPEED
	for i in range(_weapons.size()):
		_weapons[i].position = Vector2.from_angle(_ring_angle + TAU * float(i) / float(_weapons.size())) * RING_RADIUS

	var target_pos: Vector2
	if attack_mode == AttackMode.AUTO:
		target_pos = _nearest_enemy_pos(player)
	else:
		target_pos = get_global_mouse_position()

	for weapon in _weapons:
		# 每把武器独立瞄准：从武器自身位置指向目标，避免各武器子弹平行。
		var to_target := target_pos - weapon.global_position
		var wdir := Vector2.ZERO
		if to_target.is_finite() and to_target.length_squared() > 0.0001:
			wdir = to_target.normalized()
		weapon.set_aim_direction(wdir)
		var firing := wdir != Vector2.ZERO
		if attack_mode == AttackMode.MANUAL:
			firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		weapon.set_firing(firing)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_attack_mode"):
		toggle_mode()
		get_viewport().set_input_as_handled()

func toggle_mode() -> void:
	attack_mode = AttackMode.MANUAL if attack_mode == AttackMode.AUTO else AttackMode.AUTO
	attack_mode_changed.emit(attack_mode)

## 停止整条武器链：停掉 WeaponManager 与所有武器节点。
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
