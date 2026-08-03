extends Node2D
## 远程武器：黑洞枪。发射子弹，命中敌人后在命中点产生黑洞，吸附子弹与怪物。
## 天赋分支：奇点（伤害）/ 脉冲（攻速）/ 引力场（半径）/ 强吸 / 坍缩 / 持久。
## 等级 = N 点武器天赋点，由天赋树驱动终值（每帧从本武器树 + 人物天赋 + 道具重算）。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
var _texture: Texture2D  # 本体贴图（懒加载）

var weapon_id := "black_hole_gun"
var talent_tree: TalentTree  # 该武器独立天赋树（由 WeaponManager 注入）

@export var base_damage: int = 1
@export var base_cooldown: float = 2.2
@export var base_projectile_speed: float = 380.0
@export var base_range: float = 0.0  # 远程用弹道寿命表达距离
@export var base_radius: float = 130.0  # 1 级时的黑洞半径

var is_melee := false

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _bh_radius := 130.0   # 黑洞半径（引力场天赋）
var _pull_strong := false # 强吸：吸附更快
var _collapse := false    # 坍缩：黑洞消失爆炸
var _duration := false    # 持久：持续时间延长
var _crit_chance := 0.0   # 暴击率（%）
var _crit_dmg := 0.0      # 暴击额外伤害（%）
var _lifesteal := 0.0     # 吸血比例（%）

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
	_timer += delta
	if _firing and _aim_dir != Vector2.ZERO and _timer >= cooldown:
		_timer = 0.0
		fire()

## 当前武器所属玩家节点。
func _player() -> Node2D:
	return get_parent().get_parent() as Node2D

## 从本武器天赋树 + 人物天赋 + 道具重算终值（每帧调用）。
func _apply_talents() -> void:
	var tree: TalentTree = talent_tree if talent_tree != null else TalentTree.new()
	var agg: Dictionary = tree.aggregate("black_hole_gun")
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(false)
	var dmg_mult: float = agg.dmg_mult * person.dmg_mult * item.dmg_mult
	var cd_mult: float = agg.cd_mult * person.cd_mult * item.cd_mult
	# 引力场：每点黑洞半径 ×1.2（累计）。
	_bh_radius = base_radius * pow(1.2, int(agg.counts.get("bhg_radius", 0)))
	_pull_strong = bool(agg.flags.get("pull_strong", false))
	_collapse = bool(agg.flags.get("collapse", false))
	_duration = bool(agg.flags.get("duration", false))
	_crit_chance = person.crit_chance
	_crit_dmg = person.crit_dmg
	_lifesteal = person.lifesteal
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	projectile_speed = base_projectile_speed + item.speed_bonus

func fire() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.setup(_aim_dir, projectile_speed, damage, true)
	projectile.set_spawn_black_hole(_bh_radius)
	# 天赋参数：强吸 / 坍缩（消失爆炸伤害 = 本弹伤害）/ 持久（×1.3）。
	var collapse_dmg := damage if _collapse else 0
	var duration_mult := 1.3 if _duration else 1.0
	projectile.set_black_hole_extra(_pull_strong, collapse_dmg, duration_mult)
	projectile.set_crit(_crit_chance, _crit_dmg)
	projectile.set_lifesteal(_lifesteal)
	projectile.set_visual_type("black_hole_gun")
	projectile.global_position = global_position + _aim_dir * 30.0  # 从武器枪口处发射
	get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/black_hole_gun.svg")
	draw_texture_rect(_texture, Rect2(-22.0, -22.0, 44.0, 44.0), false)
