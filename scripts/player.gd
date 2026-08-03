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
# --- 武器库存（商店购买，最多 8 把，环绕玩家） ---
const MAX_WEAPON_SLOTS := 8
var weapon_slots: Array[Dictionary] = []  # 每项 { id, level, tree }；tree = 该武器独立天赋树

# --- 战斗属性 ---
var player_talent := PlayerTalent.new()  # 人物天赋（树状，经验升级发点）
var move_speed_mult := 1.0   # 移速倍率（人物天赋疾跑）
var body_scale := 1.0        # 体型倍率（基础，默认为 1）
# 武器天赋带来的每帧倍率（多把武器取最大，由攻击节点上报、玩家每物理帧重置）。
var weapon_speed_mult := 1.0
var weapon_body_scale := 1.0
var weapon_defense_bonus := 0    # 武器天赋提供的防御（每帧取最大）
var weapon_dodge_bonus := 0.0    # 武器天赋提供的闪避
# 人物天赋效果缓存（由 apply_personal_talents 更新）。
var dodge_chance := 0.0          # 闪避概率（0~100，闪避天赋）
var _person_max_hp_bonus := 0    # 人物天赋提供的生命上限加值
var _person_defense_bonus := 0   # 人物天赋提供的防御加值
var _regen_per_sec := 0          # 每秒回复血量（再生天赋）
var _regen_timer := 0.0

# --- 道具与人物属性（道具驱动，见 buy_item） ---
var item_counts: Dictionary = {}   # 道具 id -> 已获得数量
var defense := 0                   # 防御力（盔甲/人物天赋累计，每点减 1 伤害）
var luck := 0                      # 幸运值（幸运草累计，提高红心掉率）
var move_speed_bonus := 0          # 移速加算（跑鞋累计，基础 240）
# 新道具效果（50 种道具扩展）
var all_cd_mult := 1.0             # 所有武器冷却（能量饮料/战鼓/天使之翼）
var all_dmg_mult := 1.0            # 所有武器伤害（战旗/恶魔契约）
var all_dmg_flat := 0              # 所有武器伤害加算（军团徽记）
var item_crit_chance := 0.0        # 暴击率（精密瞄准等）
var item_crit_dmg := 0.0           # 暴击伤害（暴击透镜等）
var item_lifesteal := 0.0          # 吸血（吸血獠牙/血珠）
var item_dodge := 0.0              # 闪避（闪避靴/影披风）
var item_regen := 0                # 每秒回血（再生符文/凤凰之心）
var item_xp_gain := 0.0            # 经验加成（%）
var item_gold_gain := 0.0          # 金币加成（%）
var item_ranged_pierce := 0        # 远程穿透（穿甲弹）
var item_ranged_burn := 0          # 远程点燃（燃烧弹）
var item_melee_bleed := 0          # 近战流血（链锯）
var item_melee_bleed_max := 0      # 近战流血上限（锯齿刃）
var item_devil_dps := 0            # 恶魔契约：每秒自损
var item_speed_mult := 1.0         # 移速乘算（天使之翼）

@onready var hurtbox: Area2D = $Hurtbox

var _camera: Camera2D = null  # 屏幕震动用（懒获取）
var _shake_amount := 0.0
var slow_timer := 0.0        # 敌人减速：移速减半
var poison_timer := 0.0      # 敌人中毒：每秒掉血
var poison_dps := 0
var _poison_tick := 0.0
var _devil_timer := 0.0      # 恶魔契约自损计时

func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	# 开局持有初始武器：破旧手枪 Lv.1。
	weapon_slots.append({ "id": "pistol", "level": 1, "tree": TalentTree.new() })
	# 初始隐藏：开局（难度/选武暂停）不渲染玩家，进入战斗后由 main 显示。
	visible = false
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	hurtbox.body_exited.connect(_on_hurtbox_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	# 每物理帧重置武器天赋倍率，由攻击节点在本帧内取最大上报。
	weapon_speed_mult = 1.0
	weapon_body_scale = 1.0
	weapon_defense_bonus = 0
	weapon_dodge_bonus = 0.0
	# 再生：每秒回复（人物再生天赋）。
	if _regen_per_sec + item_regen > 0 and hp < max_hp:
		_regen_timer += delta
		if _regen_timer >= 1.0:
			_regen_timer = 0.0
			heal(_regen_per_sec + item_regen)
	# 敌人减速：移速减半。
	var slow_factor := 0.5 if slow_timer > 0.0 else 1.0
	if slow_timer > 0.0:
		slow_timer -= delta
	# 敌人中毒：每秒掉血。
	if poison_timer > 0.0:
		poison_timer -= delta
		_poison_tick += delta
		if _poison_tick >= 1.0:
			_poison_tick = 0.0
			take_damage(poison_dps)
	# 恶魔契约：每秒自损。
	if item_devil_dps > 0:
		_devil_timer += delta
		if _devil_timer >= 1.0:
			_devil_timer = 0.0
			take_damage(item_devil_dps)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 移速 =（基础 × 人物 × 武器 × 天使之翼）+ 跑鞋加算；减速时减半。
	velocity = input_dir * (speed * move_speed_mult * weapon_speed_mult * item_speed_mult + move_speed_bonus) * slow_factor
	move_and_slide()
	_apply_contact_damage()

## 敌人减速：移速减半持续 seconds 秒（冰霜射手等）。
func apply_slow(seconds: float) -> void:
	slow_timer = maxf(slow_timer, seconds)

## 敌人中毒：每秒掉 dps 血持续 seconds 秒（毒巫医等）。
func apply_poison(dps: int, seconds: float) -> void:
	poison_dps = maxi(poison_dps, dps)
	poison_timer = maxf(poison_timer, seconds)

## 屏幕震动：暴击/敌人死亡时调用，camera offset 随机衰减。
func shake(amount: float) -> void:
	if _camera == null:
		_camera = get_node_or_null("Camera2D") as Camera2D
	if _camera == null:
		return
	_shake_amount = maxf(_shake_amount, amount)

func _process(delta: float) -> void:
	if _shake_amount > 0.0 and _camera != null:
		_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount
		_shake_amount = maxf(_shake_amount - delta * 40.0, 0.0)
	elif _camera != null:
		_camera.offset = Vector2.ZERO

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

## 商店购买武器：空槽入槽；槽满且已有同名 → 自动合成；槽满且无同名 → 返回 false。
func add_weapon(weapon_id: String, level: int = 1) -> bool:
	if weapon_slots.size() >= MAX_WEAPON_SLOTS:
		var idx := find_slot_by_id(weapon_id)
		if idx < 0:
			return false
		_merge_into_slot(idx, level)
		return true
	var tree := TalentTree.new()
	tree.points = level  # 武器等级 N = N 点武器天赋点
	weapon_slots.append({ "id": weapon_id, "level": level, "tree": tree })
	return true

## 把 level 级同名武器合并进已有槽位：等级相加，点数按新等级减去已点天赋数重算。
func _merge_into_slot(idx: int, add_level: int) -> void:
	var slot: Dictionary = weapon_slots[idx]
	slot.level += add_level
	var owned_count: int = slot.tree.owned_ids(slot.id).size()
	slot.tree.points = maxi(slot.level - owned_count, 0)

## 商店手动合成：点选两把同名武器槽位，等级相加，保留等级高者的天赋树与已点天赋。
func combine_slots(a: int, b: int) -> bool:
	if a == b or a < 0 or b < 0 or a >= weapon_slots.size() or b >= weapon_slots.size():
		return false
	var sa: Dictionary = weapon_slots[a]
	var sb: Dictionary = weapon_slots[b]
	if sa.id != sb.id:
		return false
	var keep_idx := a if sa.level >= sb.level else b
	var drop_idx := a if sa.level < sb.level else b
	var keep: Dictionary = weapon_slots[keep_idx]
	keep.level = sa.level + sb.level
	var owned_count: int = keep.tree.owned_ids(sa.id).size()
	keep.tree.points = maxi(keep.level - owned_count, 0)
	weapon_slots.remove_at(drop_idx)
	return true

## 移除槽位（出售用），返回该武器 id。
func remove_slot(idx: int) -> String:
	if idx < 0 or idx >= weapon_slots.size():
		return ""
	var slot: Dictionary = weapon_slots[idx]
	weapon_slots.remove_at(idx)
	return slot.id

## 同名武器的第一个槽位索引（无则 -1）。
func find_slot_by_id(weapon_id: String) -> int:
	for i in range(weapon_slots.size()):
		if weapon_slots[i].id == weapon_id:
			return i
	return -1

## 同名武器的最高等级（成本/展示用）。
func weapon_level(weapon_id: String) -> int:
	var best := 0
	for slot in weapon_slots:
		if slot.id == weapon_id:
			best = maxi(best, slot.level)
	return best

## 空槽数量。
func available_slot_count() -> int:
	return MAX_WEAPON_SLOTS - weapon_slots.size()

## 按人物天赋效果应用玩家侧属性（移速/闪避/生命上限/防御/回血）。
## 攻速/范围/伤害/暴击等由攻击节点每帧读 player_talent.effects() 计算。
func apply_personal_talents() -> void:
	var fx: Dictionary = player_talent.effects()
	move_speed_mult = fx.speed_mult
	dodge_chance = fx.dodge
	_regen_per_sec = int(fx.counts.get("regen", 0)) + item_regen
	# 人物天赋生命上限：按相对差调整（与试剂等基础值互不干扰）。
	var wanted_hp_bonus := int(fx.max_hp)
	if wanted_hp_bonus != _person_max_hp_bonus:
		max_hp += wanted_hp_bonus - _person_max_hp_bonus
		_person_max_hp_bonus = wanted_hp_bonus
		hp = mini(hp, max_hp)
		hp_changed.emit(hp, max_hp)
	# 人物天赋防御：同样按相对差叠加（与盔甲等基础值互不干扰）。
	var wanted_def_bonus := int(fx.defense)
	if wanted_def_bonus != _person_defense_bonus:
		defense += wanted_def_bonus - _person_defense_bonus
		_person_defense_bonus = wanted_def_bonus

## 武器天赋每帧上报额外移速倍率（多把武器取最大，由各武器节点调用）。
func apply_weapon_speed_mult(m: float) -> void:
	weapon_speed_mult = maxf(weapon_speed_mult, m)

## 武器天赋每帧上报额外体型倍率（多把武器取最大，由各武器节点调用）。
func apply_weapon_body_scale(s: float) -> void:
	weapon_body_scale = maxf(weapon_body_scale, s)

## 武器天赋每帧上报额外防御（多把武器取最大）。
func apply_weapon_defense(n: int) -> void:
	weapon_defense_bonus = maxi(weapon_defense_bonus, n)

## 武器天赋每帧上报额外闪避（多把武器取最大）。
func apply_weapon_dodge(pct: float) -> void:
	weapon_dodge_bonus = maxf(weapon_dodge_bonus, pct)

## 道具对武器侧的最终加成（50 种道具）。
## is_melee 区分近战/远程道具组；返回 { dmg_flat, dmg_mult, cd_mult, speed_bonus, range_mult,
## pierce, burn_tier, bleed, bleed_max, crit_chance, crit_dmg, lifesteal }。
func weapon_item_effects(is_melee: bool) -> Dictionary:
	var dmg_flat := 0
	var mult := 1.0
	var cd_mult := 1.0
	var speed_bonus := 0.0
	var range_mult := 1.0
	if is_melee:
		dmg_flat += int(item_counts.get("good_steel", 0)) + 2 * int(item_counts.get("sharpener", 0))
		mult *= pow(1.1, item_counts.get("whetstone", 0))
		if item_counts.get("heavy_blade", 0) > 0:
			mult *= 1.15
		if item_counts.get("tempered_steel", 0) > 0:
			mult *= 1.1
			range_mult *= 1.1
		cd_mult *= pow(0.9, item_counts.get("handle", 0) + item_counts.get("grip_tape", 0))
		range_mult *= pow(1.1, item_counts.get("hammer", 0))
	else:
		dmg_flat += int(item_counts.get("blast_shot", 0)) + 2 * int(item_counts.get("tracer_round", 0))
		mult *= pow(1.1, item_counts.get("gunpowder", 0))
		if item_counts.get("heavy_barrel", 0) > 0:
			mult *= 1.15
		cd_mult *= pow(0.9, item_counts.get("gun_oil", 0) + item_counts.get("quick_chamber", 0))
		speed_bonus = 50.0 * item_counts.get("scope", 0) + 60.0 * item_counts.get("long_barrel", 0)
	# 全武器 / 唯一特殊。
	mult *= all_dmg_mult
	dmg_flat += all_dmg_flat
	cd_mult *= all_cd_mult
	if item_counts.get("ring", 0) > 0:
		mult *= 1.5  # 咒戒：全武器攻击 ×1.5
	return {
		"dmg_flat": dmg_flat, "dmg_mult": mult, "cd_mult": cd_mult,
		"speed_bonus": speed_bonus, "range_mult": range_mult,
		"pierce": item_ranged_pierce, "burn_tier": item_ranged_burn,
		"bleed": item_melee_bleed, "bleed_max": item_melee_bleed_max,
		"crit_chance": item_crit_chance, "crit_dmg": item_crit_dmg,
		"lifesteal": item_lifesteal,
	}

## 调试：移除道具（减计数并撤销玩家侧效果；武器侧效果由 WeaponManager 每帧按 item_counts 重算）。
func remove_item(item_id: String) -> void:
	var count: int = item_counts.get(item_id, 0)
	if count <= 0:
		return
	item_counts[item_id] = count - 1
	match ItemDefs.kind(item_id):
		"move_speed":
			move_speed_bonus = maxi(move_speed_bonus - (10 if item_id == "shoes" else 15), 0)
		"armor":
			defense = maxi(defense - (1 if item_id == "armor" else 2), 0)
		"luck":
			luck = maxi(luck - (1 if item_id == "clover" else 2), 0)
		"max_hp":
			max_hp = maxi(max_hp - (10 if item_id == "reagent" else 25), 1)
			hp = mini(hp, max_hp)
			hp_changed.emit(hp, max_hp)
		"heal":
			pass  # 已回的血不扣回，仅减计数
		"all_cd":
			all_cd_mult /= 0.93
		"all_dmg":
			all_dmg_mult /= 1.1
		"all_dmg2":
			all_dmg_flat = maxi(all_dmg_flat - 2, 0)
		"crit_chance":
			item_crit_chance = maxf(item_crit_chance - 10.0, 0.0)
		"crit_dmg":
			item_crit_dmg = maxf(item_crit_dmg - 30.0, 0.0)
		"lifesteal":
			item_lifesteal = maxf(item_lifesteal - (3.0 if item_id == "vampiric_fang" else 5.0), 0.0)
		"dodge":
			item_dodge = maxf(item_dodge - (8.0 if item_id == "dodge_boots" else 12.0), 0.0)
		"regen":
			item_regen = maxi(item_regen - (1 if item_id == "regen_rune" else 2), 0)
			if item_id == "phoenix_heart":
				max_hp = maxi(max_hp - 20, 1)
				hp = mini(hp, max_hp)
				hp_changed.emit(hp, max_hp)
		"xp_gain":
			item_xp_gain = maxf(item_xp_gain - (15.0 if item_id == "xp_tome" else 25.0), 0.0)
		"gold_gain":
			item_gold_gain = maxf(item_gold_gain - (15.0 if item_id == "gold_pouch" else 30.0), 0.0)
		"ranged_pierce":
			item_ranged_pierce = maxi(item_ranged_pierce - 1, 0)
		"ranged_burn":
			item_ranged_burn = maxi(item_ranged_burn - 1, 0)
		"melee_bleed":
			item_melee_bleed = maxi(item_melee_bleed - 1, 0)
		"melee_bleed2":
			item_melee_bleed_max = maxi(item_melee_bleed_max - 10, 0)
		"devil_contract":
			all_dmg_mult /= 1.8
			item_devil_dps = maxi(item_devil_dps - 1, 0)
		"angel_wing":
			all_cd_mult /= 0.8
			item_speed_mult /= 1.2

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	# 闪避：人物 + 武器天赋 + 道具闪避概率完全免伤。
	if dodge_chance + weapon_dodge_bonus + item_dodge > 0.0 and randf() * 100.0 < dodge_chance + weapon_dodge_bonus + item_dodge:
		return
	# 防御力：人物 + 武器天赋，每点减 1 点伤害，最低受到 1 点（避免完全免伤）。
	var reduced := maxi(1, amount - defense - weapon_defense_bonus)
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
			move_speed_bonus += 10 if item_id == "shoes" else 15
		"armor":
			defense += 1 if item_id == "armor" else 2
		"luck":
			luck += 1 if item_id == "clover" else 2
		"max_hp":
			var add_hp := 10 if item_id == "reagent" else 25
			max_hp += add_hp
			hp = mini(max_hp, hp + add_hp)  # 立即回满新增的上限部分
			hp_changed.emit(hp, max_hp)
		"heal":
			heal(10 if item_id == "bandage" else 25)
		"all_cd":
			all_cd_mult *= 0.93
		"all_dmg":
			all_dmg_mult *= 1.1
		"all_dmg2":
			all_dmg_flat += 2
		"crit_chance":
			item_crit_chance += 10.0
		"crit_dmg":
			item_crit_dmg += 30.0
		"lifesteal":
			item_lifesteal += 3.0 if item_id == "vampiric_fang" else 5.0
		"dodge":
			item_dodge += 8.0 if item_id == "dodge_boots" else 12.0
		"regen":
			item_regen += 1 if item_id == "regen_rune" else 2
			if item_id == "phoenix_heart":
				max_hp += 20
				hp = mini(max_hp, hp + 20)
				hp_changed.emit(hp, max_hp)
		"xp_gain":
			item_xp_gain += 15.0 if item_id == "xp_tome" else 25.0
		"gold_gain":
			item_gold_gain += 15.0 if item_id == "gold_pouch" else 30.0
		"ranged_pierce":
			item_ranged_pierce += 1
		"ranged_burn":
			item_ranged_burn += 1
		"melee_bleed":
			item_melee_bleed += 1
		"melee_bleed2":
			item_melee_bleed_max += 10
		"devil_contract":
			all_dmg_mult *= 1.8
			item_devil_dps += 1
		"angel_wing":
			all_cd_mult *= 0.8
			item_speed_mult *= 1.2

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
	# 渐变蓝色角色 + 光晕 + 核心 + 移动朝向小三角；体型倍率 = 基础 × 武器天赋倍率。
	var scale_total := body_scale * weapon_body_scale
	# 外圈光晕。
	draw_circle(Vector2.ZERO, 20.0 * scale_total, Color(0.4, 0.65, 1.0, 0.22))
	# 身体渐变（外深内亮）。
	draw_circle(Vector2.ZERO, 15.0 * scale_total, Color(0.2, 0.35, 0.7))
	draw_circle(Vector2.ZERO, 13.0 * scale_total, Color(0.4, 0.65, 1.0))
	draw_circle(Vector2.ZERO, 9.0 * scale_total, Color(0.65, 0.82, 1.0))
	# 白色核心。
	draw_circle(Vector2.ZERO, 4.0 * scale_total, Color(0.9, 0.96, 1.0))
	# 移动朝向小三角。
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		var d := input_dir.normalized()
		var tip: Vector2 = d * 16.0 * scale_total
		var side: Vector2 = d.orthogonal() * 5.0 * scale_total
		draw_colored_polygon(PackedVector2Array([
			tip, tip - d * 7.0 * scale_total + side, tip - d * 7.0 * scale_total - side,
		]), Color(1, 1, 1, 0.9))

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
		# 敌方弹特殊效果：减速（冰霜射手）/ 中毒（毒巫医）。
		if area.has_method("get_slow_tier") and area.get_slow_tier() > 0:
			apply_slow(0.8 * area.get_slow_tier())
		if area.has_method("get_poison_tier") and area.get_poison_tier() > 0:
			apply_poison(1, 3.0)
		area.queue_free()
