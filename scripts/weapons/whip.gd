extends Node2D
## 近战武器：鞭子。一次冷却内沿瞄准方向连抽多段扇形命中区。
## 天赋分支：鞭梢（范围）/ 破风（伤害）/ 甩鞭术（攻速）/ 连抽（多段）/ 血鞭（流血）/ 致命抽击（暴击）。
## 等级 = N 点武器天赋点，由天赋树驱动终值（每帧从本武器树 + 人物天赋 + 道具重算）。

const LAYER_WEAPON := 6  # 武器命中区所在的碰撞层（1 基）
const LAYER_ENEMY := 3   # 敌人所在的碰撞层（1 基）
var _texture: Texture2D  # 本体贴图（懒加载）

var weapon_id := "whip"
var talent_tree: TalentTree  # 该武器独立天赋树（由 WeaponManager 注入）

@export var base_damage: int = 1
@export var base_cooldown: float = 0.7
@export var base_projectile_speed: float = 0.0  # 近战无弹速
@export var base_range: float = 70.0
@export var arc_degrees: float = 100.0
@export var swing_lifetime: float = 0.1
@export var fan_degrees: float = 40.0
@export var combo_step_time: float = 0.06

var is_melee := true

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _cooldown_timer := 0.0
var _combo_remaining := 0
var _combo_timer := 0.0

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _sweep_count := 1      # 一次攻击连抽段数（连抽天赋）
var _bleed_on_hit := false # 血鞭：命中附加流血
var _bleed_max := 0        # 流血上限（血鞭 20）
var _crit_chance := 0.0    # 暴击率（%，人物锐眼/致命抽击）
var _crit_dmg := 0.0       # 暴击额外伤害（%）
var _lifesteal := 0.0      # 吸血比例（%，人物血之渴望）

func set_aim_direction(dir: Vector2) -> void:
	_aim_dir = dir.normalized()

func set_firing(value: bool) -> void:
	_firing = value

func set_level(_value: int) -> void:
	pass  # 等级已转化为天赋点

## 注入本武器独立天赋树（WeaponManager 建槽位时传入）。
func set_talent_tree(tree: TalentTree) -> void:
	talent_tree = tree

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	visible = _player().visible  # 跟随玩家可见性
	if _aim_dir != Vector2.ZERO:
		rotation = _aim_dir.angle()
	queue_redraw()
	_apply_talents()
	if _combo_remaining > 0:
		_combo_timer += delta
		if _combo_timer >= combo_step_time:
			_combo_timer = 0.0
			_spawn_swing(_sweep_count - _combo_remaining)  # 索引从前往后
			_combo_remaining -= 1
	else:
		_cooldown_timer += delta
		if _firing and _aim_dir != Vector2.ZERO and _cooldown_timer >= cooldown:
			_cooldown_timer = 0.0
			_combo_remaining = _sweep_count

## 当前武器所属玩家节点。
func _player() -> Node2D:
	return get_parent().get_parent() as Node2D

## 从本武器天赋树 + 人物天赋 + 道具重算终值（每帧调用）。
func _apply_talents() -> void:
	var tree: TalentTree = talent_tree if talent_tree != null else TalentTree.new()
	var agg: Dictionary = tree.aggregate("whip")
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(true)
	var range_mult: float = agg.range_mult * person.range_mult * item.range_mult
	var dmg_mult: float = agg.dmg_mult * person.dmg_mult * item.dmg_mult
	var cd_mult: float = agg.cd_mult * person.cd_mult * item.cd_mult
	_sweep_count = 1 + int(agg.counts.get("sweep", 0))
	_bleed_on_hit = bool(agg.flags.get("bleed", false))
	_bleed_max = int(agg.counts.get("bleed_max", 0))
	_crit_chance = agg.crit_chance + person.crit_chance
	_crit_dmg = agg.crit_dmg + person.crit_dmg
	_lifesteal = person.lifesteal
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	melee_range = base_range * range_mult

## 生成一段抽击扇环命中区（带轻微扇面偏移，让多段抽击看得见）。
func _spawn_swing(index: int) -> void:
	var count := _sweep_count
	var offset := 0.0
	if count > 1:
		offset = (index - (count - 1) / 2.0) * deg_to_rad(fan_degrees / float(count - 1))
	var dir := _aim_dir.rotated(offset)
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
	visual.color = Color(1.0, 0.85, 0.5, 0.35)
	zone.add_child(visual)

	zone.body_entered.connect(_on_zone_body_entered.bind(damage))

	get_tree().current_scene.add_child(zone)
	zone.global_position = global_position
	zone.rotation = dir.angle()

	var timer := get_tree().create_timer(swing_lifetime)
	timer.timeout.connect(zone.queue_free)

func _on_zone_body_entered(body: Node2D, dmg: int) -> void:
	if body.has_method("take_damage"):
		# 暴击 / 吸血 / 流血。
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
		if _lifesteal > 0.0:
			_player().heal(maxi(1, int(round(real_dmg * _lifesteal / 100.0))))
		if _bleed_on_hit and body.has_method("add_bleed"):
			body.add_bleed(1)  # 血鞭：命中叠加流血

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
		_texture = load("res://assets/weapons/whip.svg")
	draw_texture_rect(_texture, Rect2(-22.0, -22.0, 44.0, 44.0), false)
