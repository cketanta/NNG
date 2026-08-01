extends Node2D
## 远程武器：朝瞄准方向发射一排散射弹幕。
## 每级 +1 枚子弹（散射）。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
var _texture: Texture2D  # 武器本体贴图（懒加载：仅装备 level>=1 首次绘制时加载）
const MAX_ARC_DEGREES := 360.0  # 散射总扇角封顶：超过一圈后子弹在圈内均匀变密，不再与旧弹重叠

var weapon_id := "staff"

@export var base_damage: int = 1
@export var base_cooldown: float = 0.8
@export var base_projectile_speed: float = 500.0
@export var base_range: float = 0.0  # 远程用弹道寿命表达距离
@export var spread_degrees: float = 12.0  # 相邻子弹之间的夹角

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

func current_bullet_count() -> int:
	return level

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
	_timer += delta
	if _firing and _aim_dir != Vector2.ZERO and _timer >= cooldown:
		_timer = 0.0
		fire()

## 某弹数下的相邻子弹夹角：总扇角未满一圈时保持 spread_degrees，满圈后封顶均匀分布。
## 用 360/count（而非 360/(count-1)）保证最外侧 offset 落在 (-180°, 180°) 开区间，永不与对侧重叠。
func arc_step_degrees(count: int) -> float:
	if count <= 1:
		return 0.0
	return minf(spread_degrees, MAX_ARC_DEGREES / float(count))

func fire() -> void:
	var count := level
	var step := deg_to_rad(arc_step_degrees(count))
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (i - (count - 1) / 2.0) * step
		var dir := _aim_dir.rotated(offset)
		var projectile := PROJECTILE_SCENE.instantiate()
		projectile.setup(dir, projectile_speed, damage, true)
		projectile.set_visual_type("staff")
		projectile.global_position = global_position + dir * 30.0  # 从武器枪口处发射
		get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	# 武器本体贴图：朝瞄准方向居中绘制；首次可见时再加载，未装备武器不加载贴图。
	if _texture == null:
		_texture = load("res://assets/weapons/staff.svg")
	draw_texture_rect(_texture, Rect2(-22.0, -22.0, 44.0, 44.0), false)
