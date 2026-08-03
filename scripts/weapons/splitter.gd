extends Node2D
## 远程武器：分裂者。发射一颗子弹，命中敌人后向全方向分裂成若干略小的子弹。
## 天赋分支：爆破弹头（伤害）/ 快膛（攻速）/ 分裂（弹数）/ 制导分裂（小弹追踪）/ 剧毒。
## 等级 = N 点武器天赋点，由天赋树驱动终值（每帧从本武器树 + 人物天赋 + 道具重算）。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
var _texture: Texture2D  # 本体贴图（懒加载）

var weapon_id := "splitter"
var talent_tree: TalentTree  # 该武器独立天赋树（由 WeaponManager 注入）

@export var base_damage: int = 1
@export var base_cooldown: float = 1.1
@export var base_projectile_speed: float = 420.0
@export var base_range: float = 0.0  # 远程用弹道寿命表达距离
@export var base_split_count: int = 2  # 1 级时的分裂数量

var is_melee := false

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _split_count := 2      # 命中分裂弹数
var _split_tier := 0       # 分裂代数（分裂小弹命中再分裂）
var _shard := 0            # 破片层数（命中小范围溅射）
var _homing_deg := 0.0     # 分裂小弹追踪强度（制导分裂）
var _crit_chance := 0.0    # 暴击率（%）
var _crit_dmg := 0.0       # 暴击额外伤害（%）
var _lifesteal := 0.0      # 吸血比例（%）

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
	var agg: Dictionary = tree.aggregate("splitter")
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(false)
	var dmg_mult: float = agg.dmg_mult * person.dmg_mult * item.dmg_mult
	var cd_mult: float = agg.cd_mult * person.cd_mult * item.cd_mult
	_split_count = base_split_count + int(agg.counts.get("split", 0))
	_split_tier = int(agg.counts.get("split_tier", 0))
	_shard = int(agg.counts.get("shard", 0))
	_homing_deg = (0.5 + 0.5 * int(agg.counts.get("homing", 0))) if bool(agg.flags.get("homing_weak", false)) else 0.0
	_crit_chance = agg.crit_chance + person.crit_chance + item.crit_chance
	_crit_dmg = agg.crit_dmg + person.crit_dmg + item.crit_dmg
	_lifesteal = person.lifesteal + item.lifesteal
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	projectile_speed = base_projectile_speed + item.speed_bonus

func fire() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.setup(_aim_dir, projectile_speed, damage, true)
	projectile.set_split_on_hit(_split_count)
	if _homing_deg > 0.0:
		projectile.set_split_child_homing(_homing_deg)  # 制导分裂：分裂小弹带追踪
	if _split_tier > 0:
		projectile.set_split_child_split(2 + _split_tier)  # 二次分裂：分裂小弹命中再分裂
	if _shard > 0:
		projectile.set_explode(maxi(1, damage))  # 破片：命中小范围溅射
	projectile.set_crit(_crit_chance, _crit_dmg)
	projectile.set_lifesteal(_lifesteal)
	projectile.set_visual_type("splitter")
	projectile.global_position = global_position + _aim_dir * 30.0  # 从武器枪口处发射
	get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/splitter.svg")
	draw_texture_rect(_texture, Rect2(-22.0, -22.0, 44.0, 44.0), false)
