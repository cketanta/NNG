extends Node2D
## 近战武器：周期沿瞄准方向挥出一串扇形命中区。
## 等级 N = 每次冷却内 N 段挥砍，按时间先后、带轻微扇面依次出刀，让叠加效果看得见。

const LAYER_WEAPON := 6  # 武器命中区所在的碰撞层（1 基）
const LAYER_ENEMY := 3   # 敌人所在的碰撞层（1 基）
var _texture: Texture2D  # 武器本体贴图（懒加载：仅装备 level>=1 首次绘制时加载）

var weapon_id := "whip"

@export var base_damage: int = 1
@export var base_cooldown: float = 0.7
@export var base_projectile_speed: float = 0.0  # 近战无弹速
@export var base_range: float = 70.0
@export var arc_degrees: float = 100.0
@export var swing_lifetime: float = 0.1
@export var fan_degrees: float = 40.0
@export var combo_step_time: float = 0.06

var is_melee := true

var level := 1
# 由 WeaponManager 每帧传入的最终属性（含道具加成）。
var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _cooldown_timer := 0.0
var _combo_remaining := 0
var _combo_timer := 0.0

func set_aim_direction(dir: Vector2) -> void:
	_aim_dir = dir.normalized()

func set_firing(value: bool) -> void:
	_firing = value

func set_level(value: int) -> void:
	level = maxi(0, value)

## 接收最终属性：攻击力 / 冷却 / 弹速（远程用）/ 攻击距离（近战用）。
func set_stats(final_damage: int, final_cooldown: float, final_speed: float, final_range: float) -> void:
	damage = final_damage
	cooldown = final_cooldown
	projectile_speed = final_speed
	melee_range = final_range

func _ready() -> void:
	# 初始隐藏：避免开局（难度/选武暂停）时未装备武器贴图渲染；由 _process 按等级显示。
	visible = false

func _process(delta: float) -> void:
	if level < 1:
		visible = false
		return
	visible = true
	if _aim_dir != Vector2.ZERO:
		rotation = _aim_dir.angle()
	queue_redraw()
	if _combo_remaining > 0:
		_combo_timer += delta
		if _combo_timer >= combo_step_time:
			_combo_timer = 0.0
			_spawn_swing(level - _combo_remaining)  # 索引 0..level-1，从前往后
			_combo_remaining -= 1
	else:
		_cooldown_timer += delta
		if _firing and _aim_dir != Vector2.ZERO and _cooldown_timer >= cooldown:
			_cooldown_timer = 0.0
			_combo_remaining = level

func _spawn_swing(index: int) -> void:
	var count := level
	var offset := 0.0
	if count > 1:
		offset = (index - (count - 1) / 2.0) * deg_to_rad(fan_degrees / float(count - 1))
	var dir := _aim_dir.rotated(offset)
	var swing_range := melee_range

	var zone := Area2D.new()
	zone.collision_layer = 1 << (LAYER_WEAPON - 1)
	zone.collision_mask = 1 << (LAYER_ENEMY - 1)
	zone.monitorable = false

	var polygon := _sector_points(8.0, swing_range, deg_to_rad(arc_degrees))  # 以武器为出发点的扇环

	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon
	zone.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = polygon
	visual.color = Color(1.0, 1.0, 1.0, 0.35)
	zone.add_child(visual)

	zone.body_entered.connect(_on_zone_body_entered.bind(damage))

	get_tree().current_scene.add_child(zone)
	zone.global_position = global_position  # 以武器位置为扇环起点
	zone.rotation = dir.angle()

	var timer := get_tree().create_timer(swing_lifetime)
	timer.timeout.connect(zone.queue_free)

func _on_zone_body_entered(body: Node2D, dmg: int) -> void:
	if body.has_method("take_damage"):
		body.take_damage(dmg)

## 凸扇环多边形（弧角必须 < 180°），朝 +X 方向，用于命中区与视觉。
func _sector_points(inner_radius: float, outer_radius: float, arc: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 12
	# 外弧（-arc/2 到 +arc/2）
	for i in range(steps + 1):
		var a := -arc / 2.0 + arc * float(i) / float(steps)
		points.append(Vector2.from_angle(a) * outer_radius)
	# 内弧（+arc/2 回到 -arc/2），闭合形成环带
	for i in range(steps + 1):
		var a := arc / 2.0 - arc * float(i) / float(steps)
		points.append(Vector2.from_angle(a) * inner_radius)
	return points

func _draw() -> void:
	# 武器本体贴图：朝瞄准方向居中绘制；首次可见时再加载，未装备武器不加载贴图。
	if _texture == null:
		_texture = load("res://assets/weapons/whip.svg")
	draw_texture_rect(_texture, Rect2(-22.0, -22.0, 44.0, 44.0), false)
