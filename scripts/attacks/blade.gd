extends Node2D
## 攻击方式：短刃（近战，由旧鞭子改来）。攻击力中等、攻速中等，初始一次挥砍。
## 天赋分支：范围扩大 / 利刃出鞘（伤害）/ 拔刀术（攻速）/ 气刃斩+专精+大回旋 / 狂战+多刀流+流血。
## 天赋终值每帧从 player.talent_tree.owned["blade"] 重算。

const LAYER_WEAPON := 6  # 武器命中区所在的碰撞层（1 基）
const LAYER_ENEMY := 3   # 敌人所在的碰撞层（1 基）
const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
var _texture: Texture2D  # 本体贴图（懒加载）

var weapon_id := "blade"

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

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _combo_count := 1      # 一次攻击挥砍次数（双/三/四刀流）
var _air_blade_count := 0  # 弧形气刃数量（气刃斩 + 气刃专精1~4）
var _grand_slash := false  # 气刃大回旋：额外环形气刃波
var _bleed_on_hit := false # 致残：命中附加流血
var _bleed_max := 0        # 流血上限（致残 30 / 郁色创伤 50；0 表示不触发流血）

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
		rotation = _aim_dir.angle()
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

## 当前攻击方式所属玩家节点。
func _player() -> Node2D:
	return get_parent().get_parent() as Node2D

## 从玩家天赋树重算终值（每帧调用，量小可接受）。
func _apply_talents() -> void:
	var owned_ids: Array = _player().talent_tree.owned_ids("blade")
	var range_mult := 1.0
	var dmg_mult := 1.0
	var cd_mult := 1.0
	_combo_count = 1
	_air_blade_count = 0
	_grand_slash = false
	_bleed_on_hit = false
	_bleed_max = 0
	# 范围扩大1~4：×1.1 · ×1.2 · ×1.2 · ×1.2（累计）
	if "blade_range_1" in owned_ids: range_mult *= 1.1
	if "blade_range_2" in owned_ids: range_mult *= 1.2
	if "blade_range_3" in owned_ids: range_mult *= 1.2
	if "blade_range_4" in owned_ids: range_mult *= 1.2
	# 利刃出鞘1~4：每级 +10% 攻击
	dmg_mult *= 1.0 + 0.1 * _count_owned(owned_ids, "blade_sharp_")
	# 拔刀术1~3：每级攻速 +10%（冷却 ×0.9）
	cd_mult *= pow(0.9, _count_owned(owned_ids, "blade_swift_"))
	# 气刃斩本身 +1；气刃专精1~4 每项再 +1（注意 blade_air_blade 不能按前缀计入专精）。
	_air_blade_count += 1 if "blade_air_blade" in owned_ids else 0
	for i in range(1, 5):
		if "blade_air_%d" % i in owned_ids:
			_air_blade_count += 1
	# 气刃大回旋
	_grand_slash = "blade_grand_slash" in owned_ids
	# 狂战：挥砍伤害+20%、攻速+20%、移速+30%、体型+50%（与气刃斩互斥，已由可选集合保证）
	if "blade_berserk" in owned_ids:
		dmg_mult *= 1.2
		cd_mult *= 0.8
		_player().move_speed_mult = 1.3
		_player().body_scale = 1.5
	else:
		_player().move_speed_mult = 1.0
		_player().body_scale = 1.0
	# 多刀流：双/三/四刀流覆盖挥砍次数
	if "blade_dual" in owned_ids: _combo_count = 2
	if "blade_triple" in owned_ids: _combo_count = 3
	if "blade_quad" in owned_ids: _combo_count = 4
	# 致残：命中附加流血（上限 30）；郁色创伤：上限 50
	if "blade_maim" in owned_ids:
		_bleed_on_hit = true
		_bleed_max = 30
	if "blade_grief" in owned_ids:
		_bleed_max = 50
	damage = maxi(1, int(round(base_damage * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	melee_range = base_range * range_mult

## 统计已拥有天赋中 id 以 prefix 开头（且是 1~N 编号）的数量。
func _count_owned(owned_ids: Array, prefix: String) -> int:
	var count := 0
	for id in owned_ids:
		if id.begins_with(prefix):
			count += 1
	return count

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
		var grand_dmg := damage * 2  # 环形气刃波：二倍挥砍伤害
		for i in range(16):
			_fire_air_blade(Vector2.from_angle(TAU * float(i) / 16.0), grand_dmg)

func _fire_air_blade(dir: Vector2, dmg: int) -> void:
	var blade := PROJECTILE_SCENE.instantiate()
	blade.setup(dir, projectile_speed, dmg, true)
	blade.set_visual_type("blade_air")
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
		body.take_damage(dmg)
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
