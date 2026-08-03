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
@export var is_elite := false  # 精英怪：金色大怪，血厚/掉更多/带金冠
@export var body_scale := 1.0  # 体型倍率（BOSS 用，配合 is_elite 放大）
@export var shape: int = Shape.CIRCLE  # 身体形状（辨识度）

enum Shape { CIRCLE, TRIANGLE, DIAMOND, HEXAGON, SPIKY }

const PULL_TRAP_RADIUS := 26.0  # 距黑洞中心低于该距离时，敌人改为在中心翻搅而非叠成一团

const BLEED_DURATION := 5.0  # 流血持续时间（秒）

var hp: int
var _player: Node2D = null
var _flash_timer := 0.0  # 受击闪白剩余时间（>0 时 modulate 泛白）
var _redraw_timer := 0.0  # 低频重绘计时（约 8fps，降低大量敌人绘制开销）
var _pull_active := false
var _pull_center := Vector2.ZERO
var _pull_force := 0.0
var _pull_phase := 0.0
var _pull_jitter_radius := 6.0
var _pull_twitch_time := 0.0

# --- 流血（短刃致残天赋） ---
var bleed_stacks := 0    # 当前流血层数
var bleed_max := 30      # 流血上限（郁色创伤 → 50）
var _bleed_time := 0.0   # 距上次刷新流血的时间

# --- 中毒（分裂者剧毒天赋） ---
var poison_stacks := 0   # 当前中毒层数
var poison_max := 5      # 中毒叠加上限
var _poison_tick := 0.0  # 中毒掉血计时

# --- 燃烧（左轮燃烧弹等） ---
var burn_stacks := 0   # 当前燃烧层数
var burn_max := 5      # 燃烧叠加上限
var _burn_tick := 0.0  # 燃烧掉血计时

# --- 减速（短刃斩击等） ---
var slow_stacks := 0      # 当前减速层数
var slow_max := 5         # 减速叠加上限
var _slow_refresh := 0.0  # 减速刷新计时（3s 未叠加清空）

# --- 冻结（法杖冰霜等） ---
var freeze_timer := 0.0  # 冻结剩余时间（>0 时定身）

# --- 破甲（回旋镖破甲等） ---
var vulnerable_stacks := 0  # 破甲层数：受击额外增伤
var vulnerable_max := 5

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player") as Node2D

func _process(delta: float) -> void:
	# 流血计时：超过 5 秒未再次叠加则清空。
	if bleed_stacks > 0:
		_bleed_time += delta
		if _bleed_time >= BLEED_DURATION:
			bleed_stacks = 0
			_bleed_time = 0.0
	# 中毒：每秒掉 poison_stacks 点血（分裂者剧毒天赋）。
	if poison_stacks > 0:
		_poison_tick += delta
		if _poison_tick >= 1.0:
			_poison_tick = 0.0
			take_damage(poison_stacks)
	# 燃烧：每秒掉 burn_stacks 点血（左轮燃烧弹等）。
	if burn_stacks > 0:
		_burn_tick += delta
		if _burn_tick >= 1.0:
			_burn_tick = 0.0
			take_damage(burn_stacks)
	# 减速刷新：超过 3 秒未叠加则清空。
	if slow_stacks > 0:
		_slow_refresh += delta
		if _slow_refresh >= 3.0:
			slow_stacks = 0
			_slow_refresh = 0.0
	# 冻结计时。
	if freeze_timer > 0.0:
		freeze_timer -= delta
	# 受击闪白计时恢复。
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color(1, 1, 1)
	# 低频重绘（约 8fps）降低大量敌人的绘制开销；受击闪白在 take_damage 即时重绘。
	_redraw_timer += delta
	if _redraw_timer >= 0.12:
		_redraw_timer = 0.0
		queue_redraw()

## 叠加流血（短刃致残命中调用）；刷新持续时间，叠加上限由 bleed_max 限制。
func add_bleed(amount: int) -> void:
	bleed_stacks = mini(bleed_stacks + amount, bleed_max)
	_bleed_time = 0.0

## 叠加中毒（分裂者剧毒天赋命中调用）；每秒掉一层血，叠加上限 poison_max。
func add_poison(amount: int) -> void:
	poison_stacks = mini(poison_stacks + amount, poison_max)

## 叠加燃烧（左轮燃烧弹等命中调用）；每秒掉一层血，叠加上限 burn_max。
func add_burn(amount: int) -> void:
	burn_stacks = mini(burn_stacks + amount, burn_max)

## 叠加减速（短刃斩击等命中调用）；移速下降，3 秒未叠加清空。
func add_slow(amount: int) -> void:
	slow_stacks = mini(slow_stacks + amount, slow_max)
	_slow_refresh = 0.0

## 冻结：短暂定身（法杖冰霜等）。
func freeze(seconds: float) -> void:
	freeze_timer = maxf(freeze_timer, seconds)

## 叠加破甲（回旋镖破甲等命中调用）；受击额外增伤。
func add_vulnerable(amount: int) -> void:
	vulnerable_stacks = mini(vulnerable_stacks + amount, vulnerable_max)

## 随波次变强（在 add_child 之前调用）。
func apply_wave_scale(wave: int) -> void:
	max_hp += maxi(0, (wave - 1) * 2)
	xp_value += (wave - 1) / 2
	gold_value += (wave - 1) / 2

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
	# 受击闪白：短暂泛白提示打击。
	modulate = Color(2.4, 2.4, 2.4)
	_flash_timer = 0.12
	queue_redraw()  # 闪白即时生效
	# 流血/破甲：受到攻击时额外伤害（致残 / 破甲效果）。
	var total := amount
	if bleed_stacks > 0:
		total += bleed_stacks
	if vulnerable_stacks > 0:
		total += vulnerable_stacks
	hp -= total
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
		velocity = desired * _control_factor()
	move_and_slide()

## 冻结/减速控制：冻结时不动，减速按层数下降（最低保留 20% 速度）。
func _control_factor() -> float:
	if freeze_timer > 0.0:
		return 0.0
	return maxf(1.0 - 0.15 * slow_stacks, 0.2)

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
	# 死亡粒子（用本体色）。
	Fx.death(global_position, get_tree(), color)
	queue_free()

## 玩家受击盒检测到该敌人重叠时调用。
func get_contact_damage_value() -> int:
	return contact_damage

func _draw() -> void:
	# 渐变身体 + 描边 + 眼睛 + 朝向；流血偏红、中毒偏绿提示；精英金色放大 + 金冠。
	var body := color
	if is_elite:
		body = Color(1.0, 0.8, 0.25)  # 精英金色
	if bleed_stacks > 0:
		body = body.lerp(Color(0.9, 0.2, 0.2), 0.55)
	if poison_stacks > 0:
		body = body.lerp(Color(0.25, 0.9, 0.35), 0.55)
	if burn_stacks > 0:
		body = body.lerp(Color(1.0, 0.5, 0.1), 0.55)
	if slow_stacks > 0:
		body = body.lerp(Color(0.4, 0.7, 1.0), 0.45)
	if freeze_timer > 0.0:
		body = body.lerp(Color(0.85, 0.95, 1.0), 0.5)
	if vulnerable_stacks > 0:
		body = body.lerp(Color(0.7, 0.4, 1.0), 0.4)
	# idle 浮动动画：轻微呼吸缩放（提升辨识度）。
	var breath := 1.0 + 0.05 * sin(Time.get_ticks_msec() / 400.0 + global_position.x * 0.02)
	var k := (1.45 if is_elite else 1.0) * body_scale * breath  # 精英/BOSS 体型放大
	var r := 15.0 * k
	# 外圈描边。
	draw_circle(Vector2.ZERO, r + 1.0, body.darkened(0.6))
	# 按形状绘制身体（不同怪种不同形状，提升辨识度）。
	match shape:
		Shape.TRIANGLE:
			_draw_poly_shape(_shape_points(Shape.TRIANGLE, r), body)
		Shape.DIAMOND:
			_draw_poly_shape(_shape_points(Shape.DIAMOND, r), body)
		Shape.HEXAGON:
			_draw_poly_shape(_shape_points(Shape.HEXAGON, r), body)
		Shape.SPIKY:
			_draw_spiky(r, body)
		_:
			# 圆形渐变（默认）。
			draw_circle(Vector2.ZERO, r, body.darkened(0.4))
			draw_circle(Vector2.ZERO, r * 0.83, body)
			draw_circle(Vector2.ZERO, r * 0.63, body.lightened(0.3))
	# 顶部白色高光。
	draw_circle(Vector2(-4.0, -5.0) * k, 3.5 * k, Color(1, 1, 1, 0.7))
	draw_circle(Vector2(-3.0, -4.0) * k, 1.5 * k, Color(1, 1, 1, 0.9))
	# 精英金冠（三个小三角）。
	if is_elite:
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -15), Vector2(-4, -22), Vector2(-1, -15)]), Color(1.0, 0.85, 0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -15), Vector2(1, -24), Vector2(4, -15)]), Color(1.0, 0.9, 0.55))
		draw_colored_polygon(PackedVector2Array([Vector2(3, -15), Vector2(6, -21), Vector2(9, -15)]), Color(1.0, 0.85, 0.4))
	# 朝向指示：朝玩家的独眼。
	var dir := direction_to_player()
	if dir != Vector2.ZERO:
		var eye := dir * 6.0 * k
		draw_circle(eye, 3.2 * k, Color(0.08, 0.08, 0.12))
		draw_circle(eye + dir * 1.2, 1.3 * k, Color(1, 1, 1, 0.95))

## 绘制多边形身体：外圈 + 内层亮色（三角/菱形/六角）。
func _draw_poly_shape(points: PackedVector2Array, body: Color) -> void:
	draw_colored_polygon(points, body)
	var inner := PackedVector2Array()
	for p in points:
		inner.append(p * 0.7)
	draw_colored_polygon(inner, body.lightened(0.3))

## 形状顶点（正多边形，半径 r）。
func _shape_points(shp: int, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shp:
		Shape.TRIANGLE:
			pts.append(Vector2(0, -r))
			pts.append(Vector2(r * 0.95, r * 0.7))
			pts.append(Vector2(-r * 0.95, r * 0.7))
		Shape.DIAMOND:
			pts.append(Vector2(0, -r))
			pts.append(Vector2(r * 0.8, 0))
			pts.append(Vector2(0, r))
			pts.append(Vector2(-r * 0.8, 0))
		Shape.HEXAGON:
			for i in 6:
				pts.append(Vector2.from_angle(TAU * float(i) / 6.0) * r)
	return pts

## 尖刺形状（多角星，爆炸/孢子怪用）。
func _draw_spiky(r: float, body: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var rad := r if i % 2 == 0 else r * 0.5
		pts.append(Vector2.from_angle(TAU * float(i) / 12.0) * rad)
	draw_colored_polygon(pts, body)
	var inner := PackedVector2Array()
	for i in 12:
		var rad := r * 0.62 if i % 2 == 0 else r * 0.4
		inner.append(Vector2.from_angle(TAU * float(i) / 12.0) * rad)
	draw_colored_polygon(inner, body.lightened(0.3))
