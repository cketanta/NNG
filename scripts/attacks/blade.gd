extends Node2D
## 攻击方式：短刃（近战，由旧鞭子改来）。攻击力中等、攻速中等，初始一次挥砍。
## 天赋分支：范围扩大 / 利刃出鞘（伤害）/ 拔刀术（攻速）/ 气刃斩+专精+大回旋 / 狂战+多刀流+流血。
## 天赋终值每帧从 player.talent_tree.owned["blade"] 重算。

const LAYER_WEAPON := 6  # 武器命中区所在的碰撞层（1 基）
const LAYER_ENEMY := 3   # 敌人所在的碰撞层（1 基）
const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
const RING_WAVE_SCRIPT := preload("res://scripts/effects/ring_wave.gd")
const SWING_DURATION := 0.12  # 挥动动画时长（秒）
const SWING_START_DEG := 50.0  # 挥动起始角度（相对瞄准方向）
const SWING_END_DEG := -50.0   # 挥动结束角度
var _texture: Texture2D  # 本体贴图（懒加载）

var weapon_id := "blade"
var talent_tree: TalentTree  # 该武器独立天赋树（由 WeaponManager 注入）

@export var base_damage: int = 2
@export var base_cooldown: float = 0.5
@export var base_projectile_speed: float = 420.0  # 气刃弹速
@export var base_range: float = 70.0
@export var arc_degrees: float = 100.0  # 挥砍扇角
@export var swing_lifetime: float = 0.1
@export var combo_step_time: float = 0.06  # 多刀流时两刀之间的间隔

var is_melee := true

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _cooldown_timer := 0.0
var _combo_remaining := 0  # 本次攻击剩余挥砍刀数
var _combo_timer := 0.0
var _swing_timer := 0.0  # 挥动动画剩余时间

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _combo_count := 1      # 一次攻击挥砍次数（双/三/四刀流）
var _air_blade_count := 0  # 弧形气刃数量（气刃斩 + 气刃专精1~4）
var _grand_slash := false  # 气刃大回旋：额外环形气刃波
var _bleed_on_hit := false # 致残：命中附加流血
var _bleed_max := 0        # 流血上限（致残 30 / 郁色创伤 50；0 表示不触发流血）
var _crit_chance := 0.0    # 暴击率（%，人物锐眼）
var _crit_dmg := 0.0       # 暴击额外伤害（%，人物致命一击）
var _lifesteal := 0.0      # 吸血比例（%，人物血之渴望）

func set_aim_direction(dir: Vector2) -> void:
	_aim_dir = dir.normalized()

func set_firing(value: bool) -> void:
	_firing = value

func set_level(_value: int) -> void:
	pass  # 攻击方式等级固定为 1

func set_stats(final_damage: int, final_cooldown: float, final_speed: float, final_range: float) -> void:
	damage = final_damage
	cooldown = final_cooldown
	projectile_speed = final_speed
	melee_range = final_range

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	visible = _player().visible  # 跟随玩家可见性（菜单阶段玩家隐藏时攻击也不渲染）
	if _aim_dir != Vector2.ZERO:
		var base_angle := _aim_dir.angle()
		if _swing_timer > 0.0:
			_swing_timer -= delta
			# 挥动动画：从 +50° 摆到 -50°，呈现挥砍姿态。
			var t := 1.0 - _swing_timer / SWING_DURATION
			rotation = base_angle + deg_to_rad(lerpf(SWING_START_DEG, SWING_END_DEG, t))
		else:
			rotation = base_angle
	queue_redraw()
	_apply_talents()
	if _combo_remaining > 0:
		_combo_timer += delta
		if _combo_timer >= combo_step_time:
			_combo_timer = 0.0
			_spawn_swing()
			_combo_remaining -= 1
	else:
		_cooldown_timer += delta
		if _firing and _aim_dir != Vector2.ZERO and _cooldown_timer >= cooldown:
			_cooldown_timer = 0.0
			_launch_air_blades()  # 气刃随一次攻击同时发射
			_combo_remaining = _combo_count
			_swing_timer = SWING_DURATION  # 触发挥动动画

## 当前攻击方式所属玩家节点。
func _player() -> Node2D:
	return get_parent().get_parent() as Node2D

## 注入本武器独立天赋树（WeaponManager 建槽位时传入）。
func set_talent_tree(tree: TalentTree) -> void:
	talent_tree = tree

## 从本武器天赋树 + 人物天赋 + 道具重算终值（每帧调用，量小可接受）。
func _apply_talents() -> void:
	var tree: TalentTree = talent_tree if talent_tree != null else TalentTree.new()
	var agg: Dictionary = tree.aggregate("blade")
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(true)
	# 倍率 = 武器树 × 人物树 × 道具（近战组）。
	var range_mult: float = agg.range_mult * person.range_mult * item.range_mult
	var dmg_mult: float = agg.dmg_mult * person.dmg_mult * item.dmg_mult
	var cd_mult: float = agg.cd_mult * person.cd_mult * item.cd_mult
	_combo_count = 1
	_air_blade_count = 0
	_grand_slash = false
	_bleed_on_hit = false
	_bleed_max = 0
	# 人物暴击/吸血（作用于挥砍与气刃）。
	_crit_chance = person.crit_chance
	_crit_dmg = person.crit_dmg
	_lifesteal = person.lifesteal
	# 气刃斩本身 +1；气刃专精1~4 每项再 +1（聚合 counts）。
	_air_blade_count = int(agg.counts.get("air_blade", 0))
	# 气刃大回旋。
	_grand_slash = bool(agg.flags.get("grand_slash", false))
	# 狂战：伤害+20%、攻速+20%、移速+30%、体型+50%（与气刃斩互斥，已由可选集合保证）。
	# 移速/体型上报到玩家（多把武器取最大），不再覆盖人物移速倍率。
	if bool(agg.flags.get("berserk", false)):
		_player().apply_weapon_speed_mult(agg.speed_mult)
		_player().apply_weapon_body_scale(1.5)
	# 多刀流：双/三/四刀流（flag 取最高级覆盖挥砍次数）。
	if bool(agg.flags.get("combo_4", false)): _combo_count = 4
	elif bool(agg.flags.get("combo_3", false)): _combo_count = 3
	elif bool(agg.flags.get("combo_2", false)): _combo_count = 2
	# 致残：命中附加流血（上限 30）；郁色创伤：上限再 +20 → 50。
	if bool(agg.flags.get("bleed", false)):
		_bleed_on_hit = true
		_bleed_max = int(agg.counts.get("bleed_max", 0))
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	melee_range = base_range * range_mult

## 发射一次攻击的弧形气刃：气刃斩在挥砍扇角内均匀分布；气刃大回旋额外沿整圈发射。
func _launch_air_blades() -> void:
	if _air_blade_count <= 0 and not _grand_slash:
		return
	var air_dmg := maxi(1, int(round(damage * 0.8)))  # 气刃伤害为挥砍的 80%
	if _air_blade_count > 0:
		for i in _air_blade_count:
			var offset := 0.0
			if _air_blade_count > 1:
				offset = (i - (_air_blade_count - 1) / 2.0) * deg_to_rad(arc_degrees / float(_air_blade_count))
			_fire_air_blade(_aim_dir.rotated(offset), air_dmg)
	if _grand_slash:
		_spawn_ring_wave(damage * 2)  # 环形气刃波：二倍挥砍伤害

## 气刃大回旋：生成一个从玩家中心扩散的白色环形震荡波。
func _spawn_ring_wave(dmg: int) -> void:
	var wave := RING_WAVE_SCRIPT.new()
	wave.setup(dmg, 350.0, 420.0)
	get_tree().current_scene.add_child(wave)
	wave.global_position = global_position  # 从玩家中心扩散

func _fire_air_blade(dir: Vector2, dmg: int) -> void:
	var blade := PROJECTILE_SCENE.instantiate()
	blade.setup(dir, projectile_speed, dmg, true)
	blade.set_visual_type("blade_air")
	blade.set_crit(_crit_chance, _crit_dmg)
	blade.set_lifesteal(_lifesteal)
	blade.global_position = global_position  # 从玩家中心发射
	get_tree().current_scene.add_child(blade)

func _spawn_swing() -> void:
	var swing_range := melee_range
	var zone := Area2D.new()
	zone.collision_layer = 1 << (LAYER_WEAPON - 1)
	zone.collision_mask = 1 << (LAYER_ENEMY - 1)
	zone.monitorable = false

	var polygon := _sector_points(8.0, swing_range, deg_to_rad(arc_degrees))

	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon
	zone.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = polygon
	visual.color = Color(1.0, 1.0, 1.0, 0.35)
	zone.add_child(visual)

	zone.body_entered.connect(_on_zone_body_entered.bind(damage))

	get_tree().current_scene.add_child(zone)
	zone.global_position = global_position  # 挥砍扇环从玩家中心展开
	zone.rotation = _aim_dir.angle()

	var timer := get_tree().create_timer(swing_lifetime)
	timer.timeout.connect(zone.queue_free)

func _on_zone_body_entered(body: Node2D, dmg: int) -> void:
	if body.has_method("take_damage"):
		# 暴击：命中时按暴击率 roll，命中则按暴击伤害倍率加成。
		var crit_hit := false
		if _crit_chance > 0.0 and randf() * 100.0 < _crit_chance:
			crit_hit = true
		var real_dmg := dmg
		if crit_hit:
			real_dmg = maxi(1, int(round(dmg * (1.0 + _crit_dmg / 100.0))))
		# 特效：命中爆闪 + 伤害数字；暴击屏幕震动。
		Fx.hit(body.global_position, get_tree(), crit_hit)
		Fx.number(body.global_position, get_tree(), str(real_dmg), crit_hit)
		if crit_hit:
			Fx.shake(get_tree(), 5.0)
		body.take_damage(real_dmg)
		# 吸血：命中回复一定比例血量。
		if _lifesteal > 0.0:
			_player().heal(maxi(1, int(round(real_dmg * _lifesteal / 100.0))))
		if _bleed_on_hit and body.has_method("add_bleed"):
			body.add_bleed(1)  # 致残：命中叠加流血

## 凸扇环多边形（弧角必须 < 180°），朝 +X 方向，用于命中区与视觉。
func _sector_points(inner_radius: float, outer_radius: float, arc: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 12
	for i in range(steps + 1):
		var a := -arc / 2.0 + arc * float(i) / float(steps)
		points.append(Vector2.from_angle(a) * outer_radius)
	for i in range(steps + 1):
		var a := arc / 2.0 - arc * float(i) / float(steps)
		points.append(Vector2.from_angle(a) * inner_radius)
	return points

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/blade.svg")
	draw_texture_rect(_texture, Rect2(-18.0, -18.0, 36.0, 36.0), false)
