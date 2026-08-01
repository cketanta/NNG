extends Node2D
## 近战武器：周期沿瞄准方向挥出一串扇形命中区。
## 等级 N = 每次冷却内 N 段挥砍，按时间先后、带轻微扇面依次出刀，让叠加效果看得见。

const LAYER_WEAPON := 6  # 武器命中区所在的碰撞层（1 基）
const LAYER_ENEMY := 3   # 敌人所在的碰撞层（1 基）

var weapon_id := "whip"

@export var base_cooldown: float = 0.7
@export var base_range: float = 70.0
@export var arc_degrees: float = 100.0
@export var damage: int = 1
@export var swing_lifetime: float = 0.1
@export var fan_degrees: float = 40.0
@export var combo_step_time: float = 0.06

var level := 1
var attack_speed_mult := 1.0
var attack_range_mult := 1.0
var damage_mult := 1.0

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

func set_stats(attack_speed: float, attack_range: float, dmg_mult: float) -> void:
	attack_speed_mult = attack_speed
	attack_range_mult = attack_range
	damage_mult = dmg_mult

func _process(delta: float) -> void:
	if level < 1:
		return
	if _combo_remaining > 0:
		_combo_timer += delta
		if _combo_timer >= combo_step_time:
			_combo_timer = 0.0
			_spawn_swing(level - _combo_remaining)  # 索引 0..level-1，从前往后
			_combo_remaining -= 1
	else:
		_cooldown_timer += delta
		var cd := base_cooldown / maxf(attack_speed_mult, 0.1)
		if _firing and _aim_dir != Vector2.ZERO and _cooldown_timer >= cd:
			_cooldown_timer = 0.0
			_combo_remaining = level

func _spawn_swing(index: int) -> void:
	var count := level
	var offset := 0.0
	if count > 1:
		offset = (index - (count - 1) / 2.0) * deg_to_rad(fan_degrees / float(count - 1))
	var dir := _aim_dir.rotated(offset)
	var swing_range := base_range * attack_range_mult

	var zone := Area2D.new()
	zone.collision_layer = 1 << (LAYER_WEAPON - 1)
	zone.collision_mask = 1 << (LAYER_ENEMY - 1)
	zone.monitorable = false

	var polygon := _sector_points(swing_range, deg_to_rad(arc_degrees))

	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon
	zone.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = polygon
	visual.color = Color(1.0, 1.0, 1.0, 0.35)
	zone.add_child(visual)

	zone.body_entered.connect(_on_zone_body_entered.bind(int(round(damage * damage_mult))))

	get_tree().current_scene.add_child(zone)
	zone.global_position = global_position
	zone.rotation = dir.angle()

	var timer := get_tree().create_timer(swing_lifetime)
	timer.timeout.connect(zone.queue_free)

func _on_zone_body_entered(body: Node2D, dmg: int) -> void:
	if body.has_method("take_damage"):
		body.take_damage(dmg)

## 凸扇形多边形（弧角必须 < 180°），朝 +X 方向，用于命中区与视觉。
func _sector_points(radius: float, arc: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var steps := 12
	for i in range(steps + 1):
		var a := -arc / 2.0 + arc * float(i) / float(steps)
		points.append(Vector2.from_angle(a) * radius)
	return points
