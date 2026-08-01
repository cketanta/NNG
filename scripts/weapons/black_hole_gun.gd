extends Node2D
## 黑洞枪：发射子弹，命中敌人后在命中点产生黑洞，吸附子弹与怪物。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
const TEXTURE := preload("res://assets/weapons/black_hole_gun.svg")  # 武器本体贴图

var weapon_id := "black_hole_gun"

@export var base_damage: int = 1
@export var base_cooldown: float = 2.2
@export var base_projectile_speed: float = 380.0
@export var base_range: float = 0.0  # 远程用弹道寿命表达距离
@export var base_radius: float = 130.0       # 1 级时的黑洞半径
@export var radius_per_level: float = 20.0   # 每级半径成长

var is_melee := false

var level := 1
# 由 WeaponManager 每帧传入的最终属性（含道具加成）。
var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0

func set_aim_direction(dir: Vector2) -> void:
	_aim_dir = dir.normalized()

func set_firing(value: bool) -> void:
	_firing = value

func set_level(value: int) -> void:
	level = maxi(0, value)

## 接收最终属性：攻击力 / 冷却 / 弹速 / 攻击距离（远程用弹速与寿命，距离暂未用）。
func set_stats(final_damage: int, final_cooldown: float, final_speed: float, final_range: float) -> void:
	damage = final_damage
	cooldown = final_cooldown
	projectile_speed = final_speed
	melee_range = final_range

func _process(delta: float) -> void:
	if level < 1:
		visible = false
		return
	visible = true
	if _aim_dir != Vector2.ZERO:
		rotation = _aim_dir.angle()
	queue_redraw()
	_timer += delta
	if _firing and _aim_dir != Vector2.ZERO and _timer >= cooldown:
		_timer = 0.0
		fire()

## 某等级下的黑洞半径（UI 用它显示实时数值）。
func black_hole_radius_for_level(lv: int) -> float:
	return base_radius + radius_per_level * maxi(0, lv - 1)

func current_black_hole_radius() -> float:
	return black_hole_radius_for_level(level)

func fire() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.setup(_aim_dir, projectile_speed, damage, true)
	projectile.set_spawn_black_hole(current_black_hole_radius())
	projectile.set_visual_type("black_hole_gun")
	projectile.global_position = global_position + _aim_dir * 30.0  # 从武器枪口处发射
	get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	# 武器本体贴图：朝瞄准方向居中绘制。
	draw_texture_rect(TEXTURE, Rect2(-22.0, -22.0, 44.0, 44.0), false)
