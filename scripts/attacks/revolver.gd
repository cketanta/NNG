extends Node2D
## 攻击方式：左轮手枪（远程，由旧法杖改来）。攻击力高、攻速慢，初始发射一枚子弹。
## 天赋分支：弹头改良（伤害）/ 弹匣扩容（连射弹数）/ 快枪手（攻速）/ 转盘枪手（右键特殊攻击）/ 枪斗术+智能制导（追踪）。
## 天赋终值每帧从 player.talent_tree.owned["revolver"] 重算。

const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
const SPINNER_SCRIPT := preload("res://scripts/attacks/spinner.gd")
var _texture: Texture2D  # 本体贴图（懒加载）

var weapon_id := "revolver"
var talent_tree: TalentTree  # 该武器独立天赋树（由 WeaponManager 注入）

@export var base_damage: int = 4
@export var base_cooldown: float = 0.9
@export var base_projectile_speed: float = 520.0
@export var base_range: float = 0.0

var is_melee := false

var damage := base_damage
var cooldown := base_cooldown
var projectile_speed := base_projectile_speed
var melee_range := base_range

var _aim_dir := Vector2.RIGHT
var _firing := true
var _timer := 0.0

# --- 天赋状态（由 _apply_talents 每帧重算） ---
var _bullet_count := 1      # 每次开火连射弹数（弹匣扩容 + 人物连珠）
var _homing_deg := 0.0      # 每帧子弹转向角度（枪斗术 / 智能制导）
var _has_spinner := false   # 转盘枪手
var _crit_chance := 0.0     # 暴击率（%，人物+武器天赋）
var _crit_dmg := 0.0        # 暴击额外伤害（%）
var _lifesteal := 0.0       # 吸血比例（%，人物血之渴望）
var _burn_tier := 0         # 燃烧层级（燃烧弹：0=不点燃）
var _pierce := 0            # 子弹穿透数（穿甲弹/狙击/人物贯穿）
var _spin_extra := 0        # 转盘额外弹数（转盘扩容）
var _spin_dmg := 0          # 转盘伤害层级（转盘重锤）
var _spin_dual := false     # 双转盘

# --- 转盘枪手特殊攻击状态 ---
var _spinner_active := false
var _spinner_ref: Node2D = null

# --- 连射状态（弹匣扩容：一次冷却内连续发射多枚） ---
var _burst_remaining := 0     # 本次连射剩余弹数
var _burst_timer := 0.0
const BURST_INTERVAL := 0.08  # 连续发射间隔（秒）

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
	visible = false

func _process(delta: float) -> void:
	visible = _player().visible  # 跟随玩家可见性（菜单阶段玩家隐藏时攻击也不渲染）
	if _aim_dir != Vector2.ZERO:
		rotation = _aim_dir.angle()
	queue_redraw()
	_apply_talents()
	# 转盘结束检测：转盘节点已自毁则恢复主动攻击。
	if _spinner_active and not is_instance_valid(_spinner_ref):
		_spinner_active = false
	if _spinner_active:
		return  # 转盘期间无法主动攻击
	_timer += delta
	if _burst_remaining > 0:
		# 连射：每隔固定间隔连续发射一枚，方向保持瞄准方向（非散射）。
		_burst_timer += delta
		if _burst_timer >= BURST_INTERVAL:
			_burst_timer = 0.0
			_fire_bullet(_aim_dir)
			_burst_remaining -= 1
	elif _firing and _aim_dir != Vector2.ZERO and _timer >= cooldown:
		_timer = 0.0
		_burst_remaining = _bullet_count  # 触发一次连射序列

## 当前攻击方式所属玩家节点。
func _player() -> Node2D:
	return get_parent().get_parent() as Node2D

## 注入本武器独立天赋树（WeaponManager 建槽位时传入）。
func set_talent_tree(tree: TalentTree) -> void:
	talent_tree = tree

## 从本武器天赋树 + 人物天赋 + 道具重算终值。
func _apply_talents() -> void:
	var tree: TalentTree = talent_tree if talent_tree != null else TalentTree.new()
	var agg: Dictionary = tree.aggregate("revolver")
	var person: Dictionary = _player().player_talent.effects()
	var item: Dictionary = _player().weapon_item_effects(false)
	# 倍率 = 武器树 × 人物树 × 道具（远程组）。
	var dmg_mult: float = agg.dmg_mult * person.dmg_mult * item.dmg_mult
	var cd_mult: float = agg.cd_mult * person.cd_mult * item.cd_mult
	# 弹匣扩容 + 人物连珠 + 武器双持（远程额外弹）。
	_bullet_count = 1 + int(agg.counts.get("bullet", 0)) + int(person.counts.get("extra_projectile", 0)) + int(agg.counts.get("extra_projectile", 0))
	# 转盘枪手 / 枪斗术 / 智能制导 + 锁定强化。
	_has_spinner = bool(agg.flags.get("spinner", false))
	_homing_deg = 0.0
	if bool(agg.flags.get("homing_strong", false)):
		_homing_deg = 2.0 + 1.0 * int(agg.counts.get("homing", 0))
	elif bool(agg.flags.get("homing_weak", false)):
		_homing_deg = 0.5 + 0.5 * int(agg.counts.get("homing", 0))
	# 暴击/吸血（人物 + 武器天赋）。
	_crit_chance = agg.crit_chance + person.crit_chance + item.crit_chance
	_crit_dmg = agg.crit_dmg + person.crit_dmg + item.crit_dmg
	_lifesteal = person.lifesteal + item.lifesteal
	# 燃烧弹 / 穿透 / 转盘强化 / 身法闪避（含道具）。
	_burn_tier = (1 if agg.flags.get("burn", false) else 0) + int(agg.counts.get("burn_tier", 0)) + int(item.burn_tier)
	_pierce = int(agg.counts.get("pierce", 0)) + int(person.counts.get("pierce", 0)) + int(item.pierce)
	_spin_extra = int(agg.counts.get("spin_extra", 0))
	_spin_dmg = int(agg.counts.get("spin_dmg", 0))
	_spin_dual = bool(agg.flags.get("spin_dual", false))
	if agg.dodge > 0:
		_player().apply_weapon_dodge(agg.dodge)
	damage = maxi(1, int(round((base_damage + item.dmg_flat) * dmg_mult)))
	cooldown = base_cooldown * cd_mult
	projectile_speed = base_projectile_speed + item.speed_bonus

func fire() -> void:
	# 触发一次连射序列（弹匣扩容决定连发弹数）。
	_burst_remaining = _bullet_count
	_burst_timer = 0.0

func _fire_bullet(dir: Vector2) -> void:
	var bullet := PROJECTILE_SCENE.instantiate()
	bullet.setup(dir, projectile_speed, damage, true)
	bullet.set_visual_type("revolver")
	if _homing_deg > 0.0:
		bullet.set_homing(_homing_deg)
	bullet.set_crit(_crit_chance, _crit_dmg)
	bullet.set_lifesteal(_lifesteal)
	if _pierce > 0:
		bullet.set_pierce(_pierce)  # 穿甲/狙击/人物贯穿
	if _burn_tier > 0:
		bullet.set_burn(_burn_tier)  # 燃烧弹
	bullet.global_position = global_position  # 发射中心 = 玩家自身
	get_tree().current_scene.add_child(bullet)

func _unhandled_input(event: InputEvent) -> void:
	# 转盘枪手：右键触发（AUTO/MANUAL 均生效）。修复 v1.3 依赖不存在的 active_attack_id 导致无法触发。
	if event.is_action_pressed("special_attack") and _has_spinner and not _spinner_active:
		start_spinner()
		get_viewport().set_input_as_handled()

## 转盘枪手：扔出手枪到鼠标右键位置，手枪旋转攻击一周后收回。
func start_spinner() -> void:
	_spinner_active = true
	_spinner_ref = SPINNER_SCRIPT.new()
	get_tree().current_scene.add_child(_spinner_ref)
	# 一圈发射总数：攻速越快越密；转盘扩容加弹；转盘重锤提伤。
	var spin_dmg := int(round(damage * (1.0 + 0.3 * _spin_dmg)))
	var total := int(round(24.0 / maxf(cooldown, 0.1))) + _spin_extra * 6
	_spinner_ref.setup(get_global_mouse_position(), spin_dmg, projectile_speed, total,
		maxf(cooldown * 0.4, 0.05), _homing_deg)
	# 双转盘：额外扔出一个（位置偏移）。
	if _spin_dual:
		var spin2 := SPINNER_SCRIPT.new()
		get_tree().current_scene.add_child(spin2)
		spin2.setup(get_global_mouse_position() + Vector2(34, 0), spin_dmg, projectile_speed, total,
			maxf(cooldown * 0.4, 0.05), _homing_deg)

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/revolver.svg")
	draw_texture_rect(_texture, Rect2(-18.0, -18.0, 36.0, 36.0), false)
