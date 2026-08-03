extends Node2D
## 远程武器：法杖。朝瞄准方向发射一排散射弹幕。
## 天赋分支：星弹（弹数）/ 法纹（伤害）/ 咏唱（攻速）/ 贯穿 / 爆裂 / 凝光（收窄散射）。
## 等级 = N 点武器天赋点，由天赋树驱动终值（每帧从本武器树 + 人物天赋 + 道具重算）。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
var _texture: Texture2D  # 本体贴图（懒加载）
const MAX_ARC_DEGREES := 360.0  # 散射总扇角封顶

var weapon_id := "staff"
var talent_tree: TalentTree  # 该武器独立天赋树（由 WeaponManager 注入）

@export var base_damage: int = 1
@export var base_cooldown: float = 0.8
@export var base_projectile_speed: float = 500.0
@export var base_range: float = 0.0  # 远程用弹道寿命表达距离
@export var spread_degrees: float = 12.0  # 相邻子弹之间的夹角

var is_melee := false

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _bullet_count := 1      # 一次开火散射弹数（星弹 + 人物连珠）
var _pierce := 0            # 弹幕穿透数（贯穿天赋）
var _explode := false       # 爆裂天赋
var _focus := false         # 凝光天赋：散射更集中
var _crit_chance := 0.0     # 暴击率（%）
var _crit_dmg := 0.0        # 暴击额外伤害（%）
var _lifesteal := 0.0       # 吸血比例（%）

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
	var agg: Dictionary = tree.aggregate("staff")
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(false)
	var dmg_mult: float = agg.dmg_mult * person.dmg_mult * item.dmg_mult
	var cd_mult: float = agg.cd_mult * person.cd_mult * item.cd_mult
	_bullet_count = 1 + int(agg.counts.get("projectile", 0)) + int(person.counts.get("extra_projectile", 0))
	_pierce = int(agg.counts.get("pierce", 0)) + int(person.counts.get("pierce", 0))
	_explode = bool(agg.flags.get("explode", false))
	_focus = bool(agg.flags.get("focus", false))
	_crit_chance = person.crit_chance
	_crit_dmg = person.crit_dmg
	_lifesteal = person.lifesteal
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	projectile_speed = base_projectile_speed + item.speed_bonus

## 某弹数下的相邻子弹夹角：未满一圈保持 spread（凝光减半），满圈后封顶均匀分布。
func arc_step_degrees(count: int) -> float:
	if count <= 1:
		return 0.0
	var spread := spread_degrees * (0.5 if _focus else 1.0)
	return minf(spread, MAX_ARC_DEGREES / float(count))

func fire() -> void:
	var count := _bullet_count
	var step := deg_to_rad(arc_step_degrees(count))
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (i - (count - 1) / 2.0) * step
		var dir := _aim_dir.rotated(offset)
		var projectile := PROJECTILE_SCENE.instantiate()
		projectile.setup(dir, projectile_speed, damage, true)
		projectile.set_visual_type("staff")
		projectile.set_crit(_crit_chance, _crit_dmg)
		projectile.set_lifesteal(_lifesteal)
		if _pierce > 0:
			projectile.set_pierce(_pierce)
		if _explode:
			projectile.set_explode(maxi(1, damage))  # 爆裂：命中爆炸伤害 = 本弹伤害
		projectile.global_position = global_position + dir * 30.0  # 从武器枪口处发射
		get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/staff.svg")
	draw_texture_rect(_texture, Rect2(-22.0, -22.0, 44.0, 44.0), false)
