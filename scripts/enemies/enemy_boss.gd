extends "res://scripts/enemies/enemy_base.gd"
## BOSS 单位：每 5 波生成一个，巨型多机制敌人。kind 决定行为与配色。
## GIANT 巨魔（近战冲撞）/ HYDRA 多头蛇（扇形弹幕）/ THORN 荆棘兽（范围脉冲）/
## LICH 巫妖（召唤小怪）/ WORM 蠕虫王（死亡分裂）/ ARCHFIEND 恶魔领主（烈焰范围）/
## ICEQUEEN 寒冰女皇（冻结弹+冰霜领域）。

enum Kind { GIANT, HYDRA, THORN, LICH, WORM, ARCHFIEND, ICEQUEEN }

const PROJECTILE := preload("res://scenes/weapons/projectile.tscn")
const MINI_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

var kind: int = Kind.GIANT
var _action_timer := 0.0

## 按波次配置 BOSS（在 add_child 前调用）。
func setup(k: int, wave: int) -> void:
	kind = k
	is_elite = false  # BOSS 用专属配色（金冠由 _draw 绘制），不套精英金色
	body_scale = 2.0
	max_hp = 120 + 30 * wave
	xp_value = 30 + 10 * wave
	gold_value = 25 + 8 * wave
	speed = _kind_speed(k)
	contact_damage = _kind_contact(k)
	color = _kind_color(k)

func _kind_speed(k: int) -> float:
	match k:
		Kind.GIANT:
			return 55.0
		Kind.HYDRA:
			return 95.0
		Kind.THORN:
			return 75.0
		Kind.LICH:
			return 68.0
		Kind.WORM:
			return 85.0
		Kind.ARCHFIEND:
			return 70.0
		Kind.ICEQUEEN:
			return 80.0
	return 70.0

func _kind_contact(k: int) -> int:
	match k:
		Kind.GIANT:
			return 6
		Kind.ARCHFIEND:
			return 5
		_:
			return 3
	return 3

func _kind_color(k: int) -> Color:
	match k:
		Kind.GIANT:
			return Color(0.3, 0.85, 0.45)   # 绿
		Kind.HYDRA:
			return Color(0.3, 0.8, 0.9)     # 青
		Kind.THORN:
			return Color(0.95, 0.55, 0.25)  # 橙
		Kind.LICH:
			return Color(0.75, 0.4, 0.95)   # 紫
		Kind.WORM:
			return Color(0.9, 0.35, 0.35)   # 红
		Kind.ARCHFIEND:
			return Color(0.95, 0.4, 0.2)    # 火红
		Kind.ICEQUEEN:
			return Color(0.55, 0.82, 1.0)   # 冰蓝
	return Color(1, 1, 1)

func _physics_process(delta: float) -> void:
	_action_timer += delta
	match kind:
		Kind.GIANT:
			_giant(delta)
		Kind.HYDRA:
			_hydra(delta)
		Kind.THORN:
			_thorn(delta)
		Kind.LICH:
			_lich(delta)
		Kind.ARCHFIEND:
			_archfiend(delta)
		Kind.ICEQUEEN:
			_icequeen(delta)
		_:
			# WORM：近战追进。
			_apply_movement(direction_to_player() * speed)

var _giant_charge := 0.0  # 巨魔冲锋剩余时间

## 巨魔：近战 + 周期高速冲锋（专属技能）。
func _giant(delta: float) -> void:
	if _action_timer >= 3.0:
		_action_timer = 0.0
		_giant_charge = 0.8
	if _giant_charge > 0.0:
		_giant_charge -= delta
		_apply_movement(direction_to_player() * speed * 3.2)  # 高速冲锋
	else:
		_apply_movement(direction_to_player() * speed)

## 恶魔领主：追进 + 周期烈焰范围伤害 + 火弹扇形。
func _archfiend(delta: float) -> void:
	_apply_movement(direction_to_player() * speed)
	if _action_timer >= 1.6:
		_action_timer = 0.0
		var player := get_player()
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 140.0:
			player.take_damage(5)
		_fire_fan(4)  # 恶魔领主：更多火弹
		Fx.hit(global_position, get_tree(), true)

## 寒冰女皇：冰霜领域（周围敌人减速）+ 周期发射冻结弹。
func _icequeen(delta: float) -> void:
	_apply_movement(direction_to_player() * speed * 0.6)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 180.0:
			enemy.add_slow(1)
	if _action_timer >= 1.5:
		_action_timer = 0.0
		_fire_frost()

func _fire_frost() -> void:
	var dir := direction_to_player()
	for i in 3:
		var off := (float(i) - 1.0) * deg_to_rad(16.0)
		var p := PROJECTILE.instantiate()
		p.setup(dir.rotated(off), 320.0, 2, false)
		p.set_slow(1)  # 命中玩家减速
		p.set_visual_type("frost")
		p.global_position = global_position
		get_tree().current_scene.add_child(p)

func _hydra(delta: float) -> void:
	# 保持中距离，周期扇形弹幕。
	var player := get_player()
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist > 240.0:
		_apply_movement(direction_to_player() * speed)
	elif dist < 160.0:
		_apply_movement(-direction_to_player() * speed * 0.5)
	if _action_timer >= 1.2:
		_action_timer = 0.0
		_fire_fan(6)  # 多头蛇：更频繁更密集的扇形弹幕

func _fire_fan(count: int) -> void:
	var dir := direction_to_player()
	for i in count:
		var off := (float(i) - float(count - 1) / 2.0) * deg_to_rad(12.0)
		var p := PROJECTILE.instantiate()
		p.setup(dir.rotated(off), 320.0, 2, false)
		p.global_position = global_position
		get_tree().current_scene.add_child(p)

func _thorn(delta: float) -> void:
	# 追进 + 周期范围脉冲。
	_apply_movement(direction_to_player() * speed)
	if _action_timer >= 1.8:
		_action_timer = 0.0
		var player := get_player()
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 130.0:
			player.take_damage(5)
		Fx.hit(global_position, get_tree(), true)

func _lich(delta: float) -> void:
	# 缓慢追进 + 周期召唤小怪。
	_apply_movement(direction_to_player() * speed * 0.5)
	if _action_timer >= 3.0:
		_action_timer = 0.0
		for i in 3:  # 巫妖：召唤 3 只小怪
			var mini := MINI_SCENE.instantiate()
			mini.global_position = global_position + Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))
			mini.xp_value = 0
			mini.gold_value = 0
			get_tree().current_scene.add_child(mini)
			mini.died.connect(_on_mini_died)

## 蠕虫王：死亡时分裂成 3 个小型近战怪。
func die() -> void:
	if kind == Kind.WORM:
		for i in 4:  # 蠕虫王：分裂 4 只
			var mini := MINI_SCENE.instantiate()
			mini.global_position = global_position + Vector2(randf_range(-36.0, 36.0), randf_range(-36.0, 36.0))
			mini.xp_value = 0
			mini.gold_value = 0
			mini.max_hp = maxi(mini.max_hp, 1)
			mini.scale = Vector2(0.8, 0.8)
			get_tree().current_scene.add_child(mini)
			mini.died.connect(_on_mini_died)
	super.die()

func _on_mini_died(_global_pos: Vector2, _xp: int, _gold: int) -> void:
	pass  # 召唤/分裂小怪不额外掉落/不计击杀

## BOSS 多结构绘制：身体（super）+ 金冠 + 各 kind 专属部件（带旋转动画）。
func _draw() -> void:
	super._draw()
	var t := Time.get_ticks_msec() / 1000.0
	# 金冠（顶端三尖）。
	var cy := -24.0 * body_scale
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, cy), Vector2(-5, cy - 13), Vector2(0, cy),
		Vector2(5, cy - 13), Vector2(11, cy), Vector2(11, cy + 3), Vector2(-11, cy + 3),
	]), Color(1.0, 0.85, 0.35))
	# 各 kind 专属部件。
	match kind:
		Kind.GIANT:
			# 巨魔：两只大角。
			draw_colored_polygon(PackedVector2Array([Vector2(-15, -6), Vector2(-22, -26), Vector2(-5, -11)]), Color(0.5, 0.95, 0.65))
			draw_colored_polygon(PackedVector2Array([Vector2(15, -6), Vector2(22, -26), Vector2(5, -11)]), Color(0.5, 0.95, 0.65))
		Kind.HYDRA:
			# 多头蛇：三颗头环绕，缓缓摆动。
			for i in 3:
				var a := TAU * (0.35 + 0.15 * i) + sin(t * 1.5 + i) * 0.2
				var head := Vector2.from_angle(a) * 18.0 * body_scale
				draw_circle(head, 6.0 * body_scale, Color(0.3, 0.85, 0.95))
				draw_circle(head + Vector2.from_angle(a) * 2.0, 2.0 * body_scale, Color(1, 1, 1))
		Kind.THORN:
			# 荆棘兽：尖刺环旋转。
			for i in 8:
				var a := TAU * i / 8.0 + t * 0.6
				draw_line(Vector2.from_angle(a) * 12.0, Vector2.from_angle(a) * 24.0 * body_scale, Color(0.95, 0.65, 0.35), 3.0)
		Kind.LICH:
			# 巫妖：头顶法球。
			draw_circle(Vector2(0, -20.0 * body_scale), 6.0, Color(0.75, 0.4, 0.95, 0.4))
			draw_circle(Vector2(0, -20.0 * body_scale), 4.0, Color(0.95, 0.6, 0.95))
		Kind.WORM:
			# 蠕虫王：触角挥动。
			for i in 3:
				var a := TAU * i / 3.0 + t * 2.0
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * 21.0 * body_scale, Color(0.95, 0.45, 0.45), 3.0)
		Kind.ARCHFIEND:
			# 恶魔领主：三支火焰角。
			for i in 3:
				var a := TAU * i / 3.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(0, 0), Vector2.from_angle(a) * 19.0 * body_scale,
				]), Color(0.95, 0.5, 0.2))
		Kind.ICEQUEEN:
			# 寒冰女皇：冰晶环绕旋转。
			for i in 6:
				var a := TAU * i / 6.0 + t * 0.5
				draw_line(Vector2.from_angle(a) * 10.0, Vector2.from_angle(a) * 23.0 * body_scale, Color(0.7, 0.9, 1.0), 2.5)
