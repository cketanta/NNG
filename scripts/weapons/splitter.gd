extends Node2D
## 分裂者：发射一颗子弹，命中敌人后向全方向分裂成若干略小的子弹。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
const TEXTURE := preload("res://assets/weapons/splitter.svg")  # 武器本体贴图

var weapon_id := "splitter"

@export var base_cooldown: float = 1.1
@export var damage: int = 1
@export var base_projectile_speed: float = 420.0
@export var base_split_count: int = 2  # 1 级时的分裂数量

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

func _process(delta: float) -> void:
	if level < 1:
		visible = false
		return
	visible = true
	if _aim_dir != Vector2.ZERO:
		rotation = _aim_dir.angle()
	queue_redraw()
	_timer += delta
	var cd := base_cooldown / maxf(attack_speed_mult, 0.1)
	if _firing and _aim_dir != Vector2.ZERO and _timer >= cd:
		_timer = 0.0
		fire()

## 某等级下的分裂数量（UI 用它显示实时数值）。
func split_count_for_level(lv: int) -> int:
	return base_split_count + maxi(0, lv - 1)

func current_split_count() -> int:
	return split_count_for_level(level)

func fire() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.setup(_aim_dir, base_projectile_speed, int(round(damage * damage_mult)), true)
	projectile.set_range_mult(attack_range_mult)
	projectile.set_split_on_hit(current_split_count())
	projectile.set_visual_type("splitter")
	projectile.global_position = global_position + _aim_dir * 30.0  # 从武器枪口处发射
	get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	# 武器本体贴图：朝瞄准方向居中绘制。
	draw_texture_rect(TEXTURE, Rect2(-22.0, -22.0, 44.0, 44.0), false)
