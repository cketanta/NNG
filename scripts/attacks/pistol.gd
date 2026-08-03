extends Node2D
## 初始攻击方式：破旧手枪，朝瞄准方向发射一枚子弹（类似改前法杖的单弹形态）。
## 无天赋树，首次升级后会被替换为短刃或左轮。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
var _texture: Texture2D  # 本体贴图（懒加载：首次绘制时才加载）

var weapon_id := "pistol"

@export var base_damage: int = 2
@export var base_cooldown: float = 0.6
@export var base_projectile_speed: float = 480.0
@export var base_range: float = 0.0

var is_melee := false

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0
var _crit_chance := 0.0  # 暴击率（%，人物+道具）
var _crit_dmg := 0.0     # 暴击额外伤害（%）
var _lifesteal := 0.0    # 吸血比例（%，人物+道具）
var _pierce := 0         # 子弹穿透数（穿甲弹道具）
var _burn_tier := 0      # 燃烧层（燃烧弹道具）

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
	# 初始隐藏：开局菜单阶段不渲染；由 WeaponManager 按激活状态控制显示。
	visible = false

## 当前攻击方式所属玩家节点。
func _player() -> Node2D:
	return get_parent().get_parent() as Node2D

## 人物天赋 + 道具应用到初始手枪（无武器天赋树）。
func _apply_talents() -> void:
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(false)
	_crit_chance = person.crit_chance + item.crit_chance
	_crit_dmg = person.crit_dmg + item.crit_dmg
	_lifesteal = person.lifesteal + item.lifesteal
	_pierce = int(item.pierce)
	_burn_tier = int(item.burn_tier)
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * person.dmg_mult * item.dmg_mult)))
	cooldown = base_cooldown * person.cd_mult * item.cd_mult
	projectile_speed = base_projectile_speed + item.speed_bonus

func _process(delta: float) -> void:
	visible = _player().visible  # 跟随玩家可见性（菜单阶段玩家隐藏时攻击也不渲染）
	if _aim_dir != Vector2.ZERO:
		rotation = _aim_dir.angle()
	queue_redraw()
	_apply_talents()  # 人物天赋倍率
	_timer += delta
	if _firing and _aim_dir != Vector2.ZERO and _timer >= cooldown:
		_timer = 0.0
		fire()

func fire() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.setup(_aim_dir, projectile_speed, damage, true)
	projectile.set_visual_type("pistol")
	projectile.set_crit(_crit_chance, _crit_dmg)
	projectile.set_lifesteal(_lifesteal)
	if _pierce > 0:
		projectile.set_pierce(_pierce)
	if _burn_tier > 0:
		projectile.set_burn(_burn_tier)
	projectile.global_position = global_position  # 发射中心 = 玩家自身
	get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/pistol.svg")
	draw_texture_rect(_texture, Rect2(-18.0, -18.0, 36.0, 36.0), false)
