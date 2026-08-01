extends Node2D
## 远程武器：朝瞄准方向发射一排散射弹幕。
## 每级 +1 枚子弹（散射）；攻击范围天赋延长弹道距离。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")

var weapon_id := "staff"

@export var base_cooldown: float = 0.8
@export var damage: int = 1
@export var base_projectile_speed: float = 500.0
@export var spread_degrees: float = 12.0  # 相邻子弹之间的夹角

var level := 1
var attack_speed_mult := 1.0
var attack_range_mult := 1.0
var damage_mult := 1.0

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0

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

func current_bullet_count() -> int:
	return level

func _process(delta: float) -> void:
	if level < 1:
		return
	_timer += delta
	var cd := base_cooldown / maxf(attack_speed_mult, 0.1)
	if _firing and _aim_dir != Vector2.ZERO and _timer >= cd:
		_timer = 0.0
		fire()

func fire() -> void:
	var count := level
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (i - (count - 1) / 2.0) * deg_to_rad(spread_degrees)
		var dir := _aim_dir.rotated(offset)
		var projectile := PROJECTILE_SCENE.instantiate()
		projectile.setup(dir, base_projectile_speed, int(round(damage * damage_mult)), true)
		projectile.set_range_mult(attack_range_mult)
		projectile.global_position = global_position + dir * 20.0
		get_tree().current_scene.add_child(projectile)
