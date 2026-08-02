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
var _bullet_count := 1      # 每次开火连射弹数（弹匣扩容）
var _homing_deg := 0.0      # 每帧子弹转向角度（枪斗术 / 智能制导）
var _has_spinner := false   # 转盘枪手

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

## 从本武器天赋树 + 人物天赋重算终值。
func _apply_talents() -> void:
	var tree: TalentTree = talent_tree if talent_tree != null else TalentTree.new()
	var owned_ids: Array = tree.owned_ids("revolver")
	var dmg_mult := 1.0
	var cd_mult := 1.0
	_bullet_count = 1
	_homing_deg = 0.0
	_has_spinner = false
	# 弹头改良1~4：每级 +10% 攻击
	dmg_mult *= 1.0 + 0.1 * _count_owned(owned_ids, "rev_bullet_")
	# 快枪手1~4：每级攻速 +10%（冷却 ×0.9）
	cd_mult *= pow(0.9, _count_owned(owned_ids, "rev_quick_"))
	# 弹匣扩容1~4：每级额外连射一发子弹
	_bullet_count += _count_owned(owned_ids, "rev_mag_")
	# 转盘枪手 / 枪斗术 / 智能制导
	_has_spinner = "rev_spinner" in owned_ids
	if "rev_homing_1" in owned_ids:
		_homing_deg = 0.5  # 微弱追踪
	if "rev_homing_2" in owned_ids:
		_homing_deg = 2.0  # 追踪增强
	# 人物天赋（迅捷攻速 / 狂力伤害）叠加。
	var pt: PlayerTalent = _player().player_talent
	damage = maxi(1, int(round(base_damage * dmg_mult * pow(1.1, pt.owned_count("damage")))))
	cooldown = base_cooldown * cd_mult * pow(0.92, pt.owned_count("attack_speed"))

func _count_owned(owned_ids: Array, prefix: String) -> int:
	var count := 0
	for id in owned_ids:
		if id.begins_with(prefix):
			count += 1
	return count

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
	bullet.global_position = global_position  # 发射中心 = 玩家自身
	get_tree().current_scene.add_child(bullet)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("special_attack") and _has_spinner and not _spinner_active and _is_active():
		start_spinner()
		get_viewport().set_input_as_handled()

## 是否为当前激活的攻击方式。
func _is_active() -> bool:
	var wm := _player().get_node_or_null("WeaponManager")
	return wm != null and wm.active_attack_id == weapon_id

## 转盘枪手：扔出手枪到鼠标右键位置，手枪旋转攻击一周后收回。
func start_spinner() -> void:
	_spinner_active = true
	_spinner_ref = SPINNER_SCRIPT.new()
	get_tree().current_scene.add_child(_spinner_ref)
	# 一圈发射总数：攻速越快越密（冷却越短总数越多）；发射间隔随攻速变短。
	var total := int(round(24.0 / maxf(cooldown, 0.1)))
	_spinner_ref.setup(get_global_mouse_position(), damage, projectile_speed, total,
		maxf(cooldown * 0.4, 0.05), _homing_deg)

func _draw() -> void:
	if _texture == null:
		_texture = load("res://assets/weapons/revolver.svg")
	draw_texture_rect(_texture, Rect2(-18.0, -18.0, 36.0, 36.0), false)
