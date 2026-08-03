extends Node2D
## 攻击方式：回旋镖（远程，往返穿透）。攻击力中等、攻速中等，初始一枚往返镖。
## 天赋分支：开刃（伤害）/ 腕力（攻速）/ 贯穿刃（穿透数）/ 二段往返 / 双镖 / 绞杀旋涡。
## 天赋终值每帧从本武器独立天赋树 + 人物天赋 + 道具重算。

const BOOMERANG_SCRIPT := preload("res://scripts/weapons/boomerang_projectile.gd")
var _texture: Texture2D  # 本体贴图（懒加载）

var weapon_id := "boomerang"
var talent_tree: TalentTree  # 该武器独立天赋树（由 WeaponManager 注入）

@export var base_damage: int = 2
@export var base_cooldown: float = 0.9
@export var base_projectile_speed: float = 460.0
@export var base_range: float = 0.0
@export var base_out_distance: float = 300.0  # 镖飞出的距离后折返

var is_melee := false

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _pierce := 0            # 每趟额外穿透数（贯穿刃 + 人物贯穿）
var _max_trips := 1         # 往返趟数（二段往返 +1）
var _extra_boomerang := 0   # 额外镖数（双镖/多镖）
var _whirlwind := false     # 绞杀旋涡：折返时命中数翻倍
var _whirl_tier := 0        # 旋涡强化：额外命中数
var _magnet := 0            # 磁吸：飞行吸附附近敌人
var _armor_break := false   # 破甲：命中削弱敌人防御
var _crit_chance := 0.0     # 暴击率（%）
var _crit_dmg := 0.0        # 暴击额外伤害（%）
var _lifesteal := 0.0       # 吸血比例（%）

func set_aim_direction(dir: Vector2) -> void:
	_aim_dir = dir.normalized()

func set_firing(value: bool) -> void:
	_firing = value

func set_level(_value: int) -> void:
	pass  # 等级已转化为天赋点

func set_stats(final_damage: int, final_cooldown: float, final_speed: float, final_range: float) -> void:
	damage = final_damage
	cooldown = final_cooldown
	projectile_speed = final_speed
	melee_range = final_range

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

## 当前攻击方式所属玩家节点。
func _player() -> Node2D:
	return get_parent().get_parent() as Node2D

## 从本武器天赋树 + 人物天赋 + 道具重算终值。
func _apply_talents() -> void:
	var tree: TalentTree = talent_tree if talent_tree != null else TalentTree.new()
	var agg: Dictionary = tree.aggregate("boomerang")
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(false)
	var dmg_mult: float = agg.dmg_mult * person.dmg_mult * item.dmg_mult
	var cd_mult: float = agg.cd_mult * person.cd_mult * item.cd_mult
	_pierce = int(agg.counts.get("pierce", 0)) + int(person.counts.get("pierce", 0))
	_max_trips = 1 + int(agg.counts.get("return", 0))
	_extra_boomerang = int(agg.counts.get("boomerang", 0))
	_whirlwind = bool(agg.flags.get("whirlwind", false))
	_whirl_tier = int(agg.counts.get("whirl", 0))
	_magnet = int(agg.counts.get("magnet", 0)) + (1 if agg.flags.get("magnet", false) else 0)
	_armor_break = bool(agg.flags.get("armor_break", false))
	_crit_chance = agg.crit_chance + person.crit_chance + item.crit_chance
	_crit_dmg = agg.crit_dmg + person.crit_dmg + item.crit_dmg
	_lifesteal = person.lifesteal + item.lifesteal
	# 刃舞身法：闪避/移速上报玩家。
	if agg.dodge > 0:
		_player().apply_weapon_dodge(agg.dodge)
	if agg.speed_mult > 1.0:
		_player().apply_weapon_speed_mult(agg.speed_mult)
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	projectile_speed = base_projectile_speed + item.speed_bonus

func fire() -> void:
	# 双镖：额外发射（略微错开角度）。
	var total := 1 + _extra_boomerang
	for i in range(total):
		var offset := 0.0
		if total > 1:
			offset = (i - (total - 1) / 2.0) * deg_to_rad(10.0)
		var dir := _aim_dir.rotated(offset)
		var boom := BOOMERANG_SCRIPT.new()
		get_tree().current_scene.add_child(boom)
		boom.global_position = global_position
		boom.setup(dir, projectile_speed, damage, base_out_distance, _max_trips,
			_pierce, _whirlwind, _crit_chance, _crit_dmg, _lifesteal,
			_whirl_tier, _magnet, _armor_break)

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/boomerang.svg")
	draw_texture_rect(_texture, Rect2(-20.0, -20.0, 40.0, 40.0), false)
