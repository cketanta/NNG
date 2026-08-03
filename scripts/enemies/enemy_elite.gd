extends "res://scripts/enemies/enemy_base.gd"
## 独立精英：第 3 波起概率出现，5 种专属机制（非普通怪放大版）。
## BERSERKER 狂战士（高速近战）/ NECROMANCER 死灵法师（召唤小怪）/ WARDEN 巨盾者（高血慢速）/
## ASSASSIN 疾风刺客（瞬移贴近）/ VENOMANCER 毒巫医（远程毒弹）。

enum Kind { BERSERKER, NECROMANCER, WARDEN, ASSASSIN, VENOMANCER }

const PROJECTILE := preload("res://scenes/weapons/projectile.tscn")
const MINI_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

var kind: int = Kind.BERSERKER
var _action_timer := 0.0

## 按波次配置精英（在 add_child 前调用）。
func setup(k: int, wave: int) -> void:
	kind = k
	is_elite = true
	body_scale = 1.3
	shape = _kind_shape(k)
	max_hp = (25 + 8 * wave) * (3 if k == Kind.WARDEN else 1)  # 巨盾者血厚
	xp_value = 8 + 3 * wave
	gold_value = 6 + 2 * wave
	speed = _kind_speed(k)
	contact_damage = _kind_contact(k)
	color = _kind_color(k)

func _kind_speed(k: int) -> float:
	match k:
		Kind.BERSERKER:
			return 150.0
		Kind.NECROMANCER:
			return 80.0
		Kind.WARDEN:
			return 50.0
		Kind.ASSASSIN:
			return 200.0
		Kind.VENOMANCER:
			return 90.0
	return 100.0

func _kind_contact(k: int) -> int:
	match k:
		Kind.BERSERKER:
			return 4
		Kind.WARDEN:
			return 2
		_:
			return 3
	return 3

func _kind_shape(k: int) -> int:
	match k:
		Kind.BERSERKER:
			return 1  # 三角（近战）
		Kind.NECROMANCER:
			return 2  # 菱形（施法）
		Kind.VENOMANCER:
			return 2  # 菱形（远程）
		Kind.WARDEN:
			return 3  # 六角（重装）
		Kind.ASSASSIN:
			return 3  # 六角（迅捷）
	return 0

func _kind_color(k: int) -> Color:
	match k:
		Kind.BERSERKER:
			return Color(1.0, 0.35, 0.3)
		Kind.NECROMANCER:
			return Color(0.65, 0.4, 0.95)
		Kind.WARDEN:
			return Color(0.4, 0.6, 1.0)
		Kind.ASSASSIN:
			return Color(0.9, 0.9, 0.95)
		Kind.VENOMANCER:
			return Color(0.3, 0.9, 0.4)
	return Color(1, 1, 1)

func _physics_process(delta: float) -> void:
	_action_timer += delta
	match kind:
		Kind.NECROMANCER:
			_necromancer(delta)
		Kind.ASSASSIN:
			_assassin(delta)
		Kind.VENOMANCER:
			_venomancer(delta)
		_:
			_apply_movement(direction_to_player() * speed)  # BERSERKER/WARDEN 近战

func _necromancer(delta: float) -> void:
	# 缓慢追进 + 周期召唤小怪。
	_apply_movement(direction_to_player() * speed * 0.5)
	if _action_timer >= 3.5:
		_action_timer = 0.0
		for i in 2:
			var mini := MINI_SCENE.instantiate()
			mini.global_position = global_position + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
			mini.xp_value = 0
			mini.gold_value = 0
			get_tree().current_scene.add_child(mini)
			mini.died.connect(_on_mini_died)

func _assassin(delta: float) -> void:
	# 周期性瞬移贴近玩家。
	var player := get_player()
	if not is_instance_valid(player):
		return
	if _action_timer >= 2.2:
		_action_timer = 0.0
		global_position = player.global_position + Vector2.from_angle(randf() * TAU) * 60.0
		Fx.hit(global_position, get_tree(), false)
	else:
		_apply_movement(direction_to_player() * speed)

func _venomancer(delta: float) -> void:
	# 远程 3 向毒弹（命中玩家中毒）。
	_apply_movement(direction_to_player() * speed * 0.3)
	if _action_timer >= 2.0:
		_action_timer = 0.0
		_fire_venom()

func _fire_venom() -> void:
	var dir := direction_to_player()
	for i in 3:
		var off := (float(i) - 1.0) * deg_to_rad(14.0)
		var p := PROJECTILE.instantiate()
		p.setup(dir.rotated(off), 300.0, 1, false)
		p.set_poison()  # 命中玩家中毒
		p.global_position = global_position
		get_tree().current_scene.add_child(p)

func _on_mini_died(_global_pos: Vector2, _xp: int, _gold: int) -> void:
	pass  # 召唤小怪不额外掉落/不计击杀
