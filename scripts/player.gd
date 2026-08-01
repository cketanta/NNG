extends CharacterBody2D
## 玩家：WASD 移动，通过受击盒承受接触/弹幕伤害，并上报血量。
## 同时持有成长数据：经验、金币、武器等级与天赋驱动的属性倍率。

signal hp_changed(current: int, max_hp: int)
signal xp_changed(current: int, xp_max: int)
signal gold_changed(total: int)
signal level_up(level: int)
signal died

@export var speed: float = 240.0
@export var max_hp: int = 100

const CONTACT_TICK_INTERVAL := 0.5  # 接触伤害的跳动间隔（秒）

var hp: int
var _inside_enemies: Dictionary = {}  # 敌人身体 -> 上次造成伤害的时间

# --- 成长 ---
var gold := 0
var xp := 0
var xp_max := 5
var level := 1
# 武器初始 0 级；开局选中的武器变为 1，其余可在商店购买。
var weapon_levels: Dictionary = { "whip": 0, "staff": 0, "splitter": 0, "black_hole_gun": 0 }

# --- 战斗属性 ---
# 天赋树已停用，以下倍率恒为 1.0（不再被更新），道具改用加算/乘算作用于基础值。
var move_speed_mult := 1.0
var attack_speed_mult := 1.0
var attack_range_mult := 1.0
var damage_mult := 1.0

# --- 道具与人物属性（道具驱动，见 buy_item） ---
var item_counts: Dictionary = {}   # 道具 id -> 已获得数量
var defense := 0                   # 防御力（劣质盔甲累计，每点减 1 伤害）
var luck := 0                      # 幸运值（幸运草累计，提高红心掉率）
var move_speed_bonus := 0          # 移速加算（跑鞋累计，基础 240）

@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	# 初始隐藏：开局（难度/选武暂停）不渲染玩家，进入战斗后由 main 显示。
	visible = false
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	hurtbox.body_exited.connect(_on_hurtbox_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 移速 = 基础速度 + 跑鞋加算（天赋停用，不再乘 move_speed_mult）。
	velocity = input_dir * (speed + move_speed_bonus)
	move_and_slide()
	_apply_contact_damage()

# --- 成长辅助 ---

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_max:
		xp -= xp_max
		level += 1
		xp_max = 5 * level
		level_up.emit(level)
	xp_changed.emit(xp, xp_max)

func gain_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

# --- 调试用 setter（测试模式调试面板调用，各自发信号刷 HUD） ---

func set_gold(value: int) -> void:
	gold = maxi(value, 0)
	gold_changed.emit(gold)

func set_level(value: int) -> void:
	level = maxi(value, 1)
	xp = 0
	xp_max = 5 * level
	xp_changed.emit(xp, xp_max)

func set_max_hp(value: int) -> void:
	max_hp = maxi(value, 1)
	hp = mini(hp, max_hp)
	hp_changed.emit(hp, max_hp)

func set_defense(value: int) -> void:
	defense = maxi(value, 0)

func set_speed(value: float) -> void:
	speed = maxf(value, 0.0)

func set_luck(value: int) -> void:
	luck = maxi(value, 0)

func set_weapon_level(weapon_id: String, value: int) -> void:
	weapon_levels[weapon_id] = maxi(value, 0)  # 武器节点由 WeaponManager 每帧同步

## 调试：移除道具（减计数并撤销玩家侧效果；武器侧效果由 WeaponManager 每帧按 item_counts 重算）。
func remove_item(item_id: String) -> void:
	var count: int = item_counts.get(item_id, 0)
	if count <= 0:
		return
	item_counts[item_id] = count - 1
	match ItemDefs.kind(item_id):
		"move_speed":
			move_speed_bonus = maxi(move_speed_bonus - 10, 0)
		"armor":
			defense = maxi(defense - 1, 0)
		"luck":
			luck = maxi(luck - 1, 0)
		"max_hp":
			max_hp = maxi(max_hp - 10, 1)
			hp = mini(hp, max_hp)
			hp_changed.emit(hp, max_hp)
		"heal":
			pass  # 已回的血不扣回，仅减计数

func add_weapon_level(weapon_id: String) -> void:
	weapon_levels[weapon_id] = weapon_levels.get(weapon_id, 1) + 1

## 根据天赋树已点层级重新计算玩家的各项属性倍率。
func apply_talent_stats(tree) -> void:
	move_speed_mult = 1.0 + 0.10 * tree.owned_count("move_speed")
	attack_speed_mult = 1.0 + 0.08 * tree.owned_count("attack_speed")
	attack_range_mult = 1.0 + 0.12 * tree.owned_count("attack_range")
	damage_mult = 1.0 + 0.10 * tree.owned_count("damage")

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	# 防御力：每点减 1 点伤害，最低受到 1 点（避免完全免伤）。
	var reduced := maxi(1, amount - defense)
	hp = maxi(0, hp - reduced)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		die()

## 回复血量（不超出上限）。红心、绷带等道具调用。
func heal(amount: int) -> void:
	if hp <= 0:
		return
	hp = mini(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)

## 购买道具：累计计数并立即应用玩家侧效果。
## 武器侧效果（攻击/冷却/弹速/距离）由 WeaponManager 每帧读取 item_counts 计算，不在此生效。
func buy_item(item_id: String) -> void:
	item_counts[item_id] = item_counts.get(item_id, 0) + 1
	match ItemDefs.kind(item_id):
		"move_speed":
			move_speed_bonus += 10
		"armor":
			defense += 1
		"luck":
			luck += 1
		"max_hp":
			max_hp += 10
			hp = mini(max_hp, hp + 10)  # 立即回满新增的上限部分
			hp_changed.emit(hp, max_hp)
		"heal":
			heal(10)

func die() -> void:
	died.emit()
	set_physics_process(false)
	visible = false
	hurtbox.set_deferred("monitoring", false)
	# 死亡后停止整条武器链（WeaponManager + 子武器），否则武器会保留 _firing 继续开火。
	var weapon_manager_node := get_node_or_null("WeaponManager")
	if weapon_manager_node != null:
		weapon_manager_node.call("halt")

func _draw() -> void:
	# 占位蓝色圆；以后换成贴图。
	draw_circle(Vector2.ZERO, 15.0, Color(0.2, 0.35, 0.7))
	draw_circle(Vector2.ZERO, 14.0, Color(0.4, 0.65, 1.0))
	draw_circle(Vector2.ZERO, 5.0, Color(0.85, 0.92, 1.0))

func _apply_contact_damage() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for body in _inside_enemies.keys():
		if not is_instance_valid(body) or not body.is_inside_tree():
			_inside_enemies.erase(body)
			continue
		if body.has_method("get_contact_damage_value"):
			var last_hit := _inside_enemies[body] as float
			if now - last_hit >= CONTACT_TICK_INTERVAL:
				_inside_enemies[body] = now
				take_damage(body.get_contact_damage_value())

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		# 把跳动计时设为过去，让首击在下一物理帧立即生效，而不是等满一个间隔。
		_inside_enemies[body] = Time.get_ticks_msec() / 1000.0 - CONTACT_TICK_INTERVAL

func _on_hurtbox_body_exited(body: Node2D) -> void:
	_inside_enemies.erase(body)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage_value"):
		take_damage(area.get_damage_value())
		area.queue_free()
