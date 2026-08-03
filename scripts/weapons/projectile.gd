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
const MAX_FRIENDLY := 260  # 友好弹幕总量上限（性能保护，防满级弹幕海拖垮物理）

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
var _hit_bodies := {}         # 已命中的敌人（防止同颗子弹重复命中同一怪）
var _visual_type := "default"  # 子弹贴图类型（staff/pistol/revolver/blade_air/splitter/splitter_child/black_hole_gun）
var _homing_deg := 0.0      # 追踪强度：每帧最大转向角度（0=不追踪，枪斗术弱/智能制导强）
var _crit_chance := 0.0     # 暴击率（%，命中时 roll）
var _crit_dmg := 0.0        # 暴击额外伤害（%）
var _lifesteal := 0.0       # 吸血比例（%，命中回复血量）
var _pierce := 0            # 剩余穿透数（>0 时命中后继续飞行）
var _explode := false       # 命中小范围爆炸（法杖爆裂）
var _explode_dmg := 1
var _poison := false        # 命中施毒（预留）
var _burn_tier := 0         # 命中点燃层数（左轮燃烧弹）
var _slow_tier := 0         # 命中减速层数（法杖冰霜）
var _freeze_tier := 0       # 命中冻结层级（法杖冰霜）
var _chain := 0             # 命中弹射次数（法杖闪电连锁）
var _child_homing := 0.0    # 分裂小弹追踪强度（分裂者制导分裂）
var _child_split := 0       # 分裂小弹再分裂数（分裂者二次分裂）

var _pull_target: Node2D = null
var _pull_speed := 0.0
var _twitch_time := 0.0
var _homing_tick := 0  # 追踪方向更新节流（每 3 物理帧重算一次，降低 O(弹×敌) 遍历）

var _child_scene: PackedScene
var _black_hole_scene: PackedScene

func _ready() -> void:
	# 弹幕总量性能保护：友好弹超过上限立即自毁（setup 已先加入 group，计数含自己）。
	if _friendly and get_tree().get_nodes_in_group("friendly_projectiles").size() >= MAX_FRIENDLY:
		queue_free()

# 黑洞枪额外参数（天赋：强吸 / 坍缩 / 持久 / 侵蚀 / 时间）。
var _bh_pull_strong := false
var _bh_duration_mult := 1.0
var _black_hole_collapse_dmg := 0
var _bh_erode_dps := 0
var _bh_slow_tier := 0
var _bh_freeze_tier := 0

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

## 设置暴击参数：命中时按 chance% 概率造成 (1 + dmg/100) 倍伤害。
func set_crit(chance: float, dmg: float) -> void:
	_crit_chance = maxf(chance, 0.0)
	_crit_dmg = maxf(dmg, 0.0)

## 设置吸血比例（%）：命中回复一定比例伤害的血量（人物血之渴望）。
func set_lifesteal(pct: float) -> void:
	_lifesteal = maxf(pct, 0.0)

## 设置穿透数：>0 时命中后继续飞行，可再命中 count 只敌人（法杖/回旋镖贯穿、人物贯穿）。
func set_pierce(count: int) -> void:
	_pierce = maxi(count, 0)

## 法杖爆裂：命中后对附近敌人造成 dmg 点二次伤害。
func set_explode(dmg: int) -> void:
	_explode = true
	_explode_dmg = maxi(dmg, 1)

## 分裂者剧毒：命中施加中毒叠加（每秒掉血）。
func set_poison() -> void:
	_poison = true

## 左轮燃烧弹：命中点燃（每秒掉血）。
func set_burn(tier: int) -> void:
	_burn_tier = maxi(tier, 0)

## 命中减速（法杖冰霜）。
func set_slow(tier: int) -> void:
	_slow_tier = maxi(tier, 0)

## 命中冻结（法杖冰霜）：短暂定身。
func set_freeze(tier: int) -> void:
	_freeze_tier = maxi(tier, 0)

## 命中弹射（法杖闪电连锁）：命中后对附近敌人造成部分伤害。
func set_chain(count: int) -> void:
	_chain = maxi(count, 0)

## 分裂小弹的追踪强度（分裂者制导分裂天赋）。
func set_split_child_homing(deg: float) -> void:
	_child_homing = maxf(deg, 0.0)

## 分裂小弹命中后再分裂出 count 枚小弹（分裂者二次分裂）。
func set_split_child_split(count: int) -> void:
	_child_split = maxi(count, 0)

## 黑洞枪：命中敌人在命中点生成黑洞。
func set_spawn_black_hole(radius: float) -> void:
	_spawn_black_hole = true
	_black_hole_radius = radius

## 黑洞枪额外参数（天赋）：强吸 / 坍缩伤害 / 持续时间倍率。
func set_black_hole_extra(strong_pull: bool, collapse_dmg: int, duration_mult: float) -> void:
	_bh_pull_strong = strong_pull
	_black_hole_collapse_dmg = maxi(collapse_dmg, 0)
	_bh_duration_mult = maxf(duration_mult, 1.0)

## 黑洞枪额外字段（天赋）：虚空侵蚀 / 时间停滞（减速/冻结）。
func set_black_hole_fields(erode: int, slow: int, freeze: int) -> void:
	_bh_erode_dps = maxi(erode, 0)
	_bh_slow_tier = maxi(slow, 0)
	_bh_freeze_tier = maxi(freeze, 0)

## 黑洞在本弹进入其吸引范围时调用。
func apply_pull(center: Node2D, speed: float) -> void:
	_pull_target = center
	_pull_speed = speed

func _physics_process(delta: float) -> void:
	rotation = _direction.angle()  # 贴图朝向飞行方向（月牙气刃尖端朝前）
	if _homing_deg > 0.0 and _friendly:
		# 追踪每 3 物理帧重算一次目标方向（中间帧沿用），降低弹幕海下的敌人遍历开销。
		_homing_tick += 1
		if _homing_tick >= 3:
			_homing_tick = 0
			_apply_homing(delta * 3.0)
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
			size = 34.0
		_:
			_draw_fallback_ball()
			return
	# 冰霜弹（冰霜射手）用代码绘制淡蓝渐变，不占贴图。
	if _visual_type == "frost":
		_draw_frost_ball()
		return
	_draw_texture_centered(tex, size)
	_draw_texture_centered(tex, size)

func _draw_texture_centered(tex: Texture2D, size: float) -> void:
	# 分裂小弹节点自带 0.65 缩放，这里画正常大小即可。
	draw_texture_rect(tex, Rect2(-size * 0.5, -size * 0.5, size, size), false)

func _draw_fallback_ball() -> void:
	var radius := 3.0 if _is_small else 5.0
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.8, 1.0))
	if not _is_small:
		draw_circle(Vector2.ZERO, radius * 0.4, Color(1.0, 1.0, 1.0, 0.9))

## 冰霜弹：淡蓝渐变球（冰霜射手）。
func _draw_frost_ball() -> void:
	draw_circle(Vector2.ZERO, 5.5, Color(0.4, 0.75, 1.0))
	draw_circle(Vector2.ZERO, 3.5, Color(0.75, 0.92, 1.0))
	draw_circle(Vector2.ZERO, 1.6, Color(1.0, 1.0, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	if _hit_bodies.has(body):
		return
	_hit_bodies[body] = true
	# 暴击：命中时按暴击率 roll，命中则按暴击伤害倍率加成。
	var crit_hit := false
	if _crit_chance > 0.0 and randf() * 100.0 < _crit_chance:
		crit_hit = true
	var real_dmg := _damage
	if crit_hit:
		real_dmg = maxi(1, int(round(_damage * (1.0 + _crit_dmg / 100.0))))
	# 特效：命中爆闪 + 伤害数字；暴击屏幕震动。
	Fx.hit(global_position, get_tree(), crit_hit)
	Fx.number(global_position, get_tree(), str(real_dmg), crit_hit)
	if crit_hit:
		Fx.shake(get_tree(), 5.0)
	body.take_damage(real_dmg)
	# 吸血：命中回复一定比例血量（人物血之渴望）。
	if _lifesteal > 0.0 and _friendly:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("heal"):
			player.heal(maxi(1, int(round(real_dmg * _lifesteal / 100.0))))
	if _friendly:
		# 剧毒（分裂者）。
		if _poison and body.has_method("add_poison"):
			body.add_poison(1)
		# 点燃（左轮燃烧弹）。
		if _burn_tier > 0 and body.has_method("add_burn"):
			body.add_burn(_burn_tier)
		# 减速。
		if _slow_tier > 0 and body.has_method("add_slow"):
			body.add_slow(_slow_tier)
		# 冻结（法杖冰霜）。
		if _freeze_tier > 0 and body.has_method("freeze"):
			body.freeze(0.6 * _freeze_tier)
		# 分裂（分裂者）。
		if _split_count > 0:
			_spawn_split_children()
		# 黑洞（黑洞枪）。
		if _spawn_black_hole:
			_spawn_black_hole_at(global_position)
		# 爆裂（法杖）。
		if _explode:
			_explode_area()
		# 闪电连锁：对附近敌人弹射部分伤害。
		if _chain > 0:
			_spawn_chain(body)
	# 穿透：命中后继续飞行而非消失，剩余穿透数耗尽才消失。
	if _pierce > 0:
		_pierce -= 1
		return
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
		if _child_homing > 0.0:
			child.set_homing(_child_homing)
		if _child_split > 0:
			child.set_split_on_hit(_child_split)  # 分裂小弹命中再分裂
		child.global_position = global_position
		get_tree().current_scene.add_child(child)

func _spawn_black_hole_at(pos: Vector2) -> void:
	if _black_hole_scene == null:
		_black_hole_scene = load(BLACK_HOLE_SCENE_PATH)
	var hole := _black_hole_scene.instantiate()
	hole.radius = _black_hole_radius
	if _bh_pull_strong:
		hole.enemy_pull_speed = 420.0  # 强吸：吸附更快
	if _bh_duration_mult > 1.0:
		hole.lifetime *= _bh_duration_mult  # 持久：持续时间延长
	if _black_hole_collapse_dmg > 0:
		hole.collapse_damage = _black_hole_collapse_dmg
		hole.collapse_radius = _black_hole_radius * 0.9  # 坍缩：消失时爆炸
	if _bh_erode_dps > 0:
		hole.erode_dps = _bh_erode_dps  # 虚空侵蚀
	if _bh_slow_tier > 0:
		hole.slow_tier = _bh_slow_tier  # 时间停滞：减速
	if _bh_freeze_tier > 0:
		hole.freeze_tier = _bh_freeze_tier  # 时间停滞：冻结
	get_tree().current_scene.add_child(hole)
	hole.global_position = pos

## 闪电连锁：命中后对附近至多 count 个敌人弹射部分伤害（法杖闪电）。
func _spawn_chain(hit_body: Node2D) -> void:
	var chain_dmg := maxi(1, _damage / 2)
	var hits := 0
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy == hit_body:
			continue
		if global_position.distance_to(enemy.global_position) < 130.0 and hits < _chain:
			enemy.take_damage(chain_dmg)
			Fx.hit(enemy.global_position, get_tree(), false)
			hits += 1

## 法杖爆裂：命中点附近敌人受一次额外伤害。
func _explode_area() -> void:
	var blast_r := 60.0
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < blast_r:
			enemy.take_damage(_explode_dmg)

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

## 敌方弹减速层（冰霜射手，玩家命中减速）。
func get_slow_tier() -> int:
	return _slow_tier

## 敌方弹中毒层（毒巫医，玩家命中中毒）。
func get_poison_tier() -> int:
	return 1 if _poison else 0
