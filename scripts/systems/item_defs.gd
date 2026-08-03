class_name ItemDefs
extends RefCounted
## 道具定义表：id -> { name, rarity, cost, kind, desc, unique, icon }。共 50 种。
## kind 含义：
##   ranged_mult / ranged_flat / ranged_speed / ranged_cooldown / ranged_pierce / ranged_burn -> 远程武器
##   melee_mult / melee_flat / melee_cooldown / melee_range_mult / melee_bleed -> 近战武器
##   all_dmg / all_cd -> 全武器伤害/冷却
##   crit_chance / crit_dmg / lifesteal -> 全武器暴击/吸血
##   dodge / regen / xp_gain / gold_gain -> 玩家侧属性
##   move_speed / armor / max_hp / heal / luck -> 玩家侧即时生效
##   ring / devil_contract / angel_wing -> 唯一特殊道具

const ITEMS := {
	# ==== 武器侧：远程 ====
	"gunpowder": { "name": "动能火药", "rarity": "epic", "cost": 15, "kind": "ranged_mult", "desc": "远程武器攻击力 ×1.1", "unique": false, "icon": "res://assets/items/gunpowder.svg" },
	"blast_shot": { "name": "爆破弹", "rarity": "normal", "cost": 6, "kind": "ranged_flat", "desc": "远程武器攻击力 +1", "unique": false, "icon": "res://assets/items/blast_shot.svg" },
	"scope": { "name": "瞄准镜", "rarity": "quality", "cost": 12, "kind": "ranged_speed", "desc": "远程武器弹速 +50", "unique": false, "icon": "res://assets/items/scope.svg" },
	"gun_oil": { "name": "枪械润滑剂", "rarity": "quality", "cost": 12, "kind": "ranged_cooldown", "desc": "远程武器冷却 ×0.9", "unique": false, "icon": "res://assets/items/gun_oil.svg" },
	"heavy_barrel": { "name": "重型枪管", "rarity": "epic", "cost": 16, "kind": "ranged_mult", "desc": "远程武器攻击力 ×1.15", "unique": false, "icon": "res://assets/items/heavy_barrel.svg" },
	"tracer_round": { "name": "曳光弹", "rarity": "quality", "cost": 12, "kind": "ranged_flat", "desc": "远程武器攻击力 +2", "unique": false, "icon": "res://assets/items/tracer_round.svg" },
	"ap_round": { "name": "穿甲弹", "rarity": "epic", "cost": 16, "kind": "ranged_pierce", "desc": "远程子弹可穿透1名敌人", "unique": false, "icon": "res://assets/items/ap_round.svg" },
	"incendiary_round": { "name": "燃烧弹", "rarity": "epic", "cost": 16, "kind": "ranged_burn", "desc": "远程命中点燃敌人", "unique": false, "icon": "res://assets/items/incendiary_round.svg" },
	"quick_chamber": { "name": "快装器", "rarity": "quality", "cost": 12, "kind": "ranged_cooldown", "desc": "远程武器冷却 ×0.9", "unique": false, "icon": "res://assets/items/quick_chamber.svg" },
	"long_barrel": { "name": "长枪管", "rarity": "quality", "cost": 12, "kind": "ranged_speed", "desc": "远程武器弹速 +60", "unique": false, "icon": "res://assets/items/long_barrel.svg" },
	# ==== 武器侧：近战 ====
	"whetstone": { "name": "磨刀石", "rarity": "epic", "cost": 15, "kind": "melee_mult", "desc": "近战武器攻击力 ×1.1", "unique": false, "icon": "res://assets/items/whetstone.svg" },
	"good_steel": { "name": "好钢", "rarity": "normal", "cost": 6, "kind": "melee_flat", "desc": "近战武器攻击力 +1", "unique": false, "icon": "res://assets/items/good_steel.svg" },
	"handle": { "name": "舒适刀柄", "rarity": "quality", "cost": 12, "kind": "melee_cooldown", "desc": "近战武器冷却 ×0.9", "unique": false, "icon": "res://assets/items/handle.svg" },
	"hammer": { "name": "锻锤", "rarity": "quality", "cost": 12, "kind": "melee_range_mult", "desc": "近战攻击距离 +10%", "unique": false, "icon": "res://assets/items/hammer.svg" },
	"sharpener": { "name": "磨刀器", "rarity": "quality", "cost": 12, "kind": "melee_flat", "desc": "近战武器攻击力 +2", "unique": false, "icon": "res://assets/items/sharpener.svg" },
	"heavy_blade": { "name": "重刃", "rarity": "epic", "cost": 16, "kind": "melee_mult", "desc": "近战武器攻击力 ×1.15", "unique": false, "icon": "res://assets/items/heavy_blade.svg" },
	"chain_blade": { "name": "链锯", "rarity": "epic", "cost": 16, "kind": "melee_bleed", "desc": "近战命中附加流血", "unique": false, "icon": "res://assets/items/chain_blade.svg" },
	"serrated_edge": { "name": "锯齿刃", "rarity": "quality", "cost": 13, "kind": "melee_bleed2", "desc": "近战流血上限提升", "unique": false, "icon": "res://assets/items/serrated_edge.svg" },
	"tempered_steel": { "name": "淬火钢", "rarity": "epic", "cost": 16, "kind": "melee_mult", "desc": "近战攻击力 ×1.1，距离 +10%", "unique": false, "icon": "res://assets/items/tempered_steel.svg" },
	"grip_tape": { "name": "握把带", "rarity": "quality", "cost": 12, "kind": "melee_cooldown", "desc": "近战武器冷却 ×0.9", "unique": false, "icon": "res://assets/items/grip_tape.svg" },
	# ==== 全武器 ====
	"battle_banner": { "name": "战旗", "rarity": "epic", "cost": 16, "kind": "all_dmg", "desc": "所有武器攻击力 ×1.1", "unique": false, "icon": "res://assets/items/battle_banner.svg" },
	"war_drum": { "name": "战鼓", "rarity": "epic", "cost": 16, "kind": "all_cd", "desc": "所有武器冷却 ×0.93", "unique": false, "icon": "res://assets/items/war_drum.svg" },
	"legion_ring": { "name": "军团徽记", "rarity": "epic", "cost": 15, "kind": "all_dmg2", "desc": "所有武器攻击力 +2", "unique": false, "icon": "res://assets/items/legion_ring.svg" },
	"energy_drink": { "name": "能量饮料", "rarity": "quality", "cost": 12, "kind": "all_cd", "desc": "所有武器冷却 ×0.93", "unique": false, "icon": "res://assets/items/energy_drink.svg" },
	"coffee": { "name": "咖啡", "rarity": "quality", "cost": 12, "kind": "all_cd", "desc": "所有武器冷却 ×0.93", "unique": false, "icon": "res://assets/items/coffee.svg" },
	# ==== 暴击/吸血/闪避/回血 ====
	"crit_scope": { "name": "精密瞄准", "rarity": "epic", "cost": 16, "kind": "crit_chance", "desc": "暴击率 +10%", "unique": false, "icon": "res://assets/items/crit_scope.svg" },
	"crit_lens": { "name": "暴击透镜", "rarity": "epic", "cost": 16, "kind": "crit_dmg", "desc": "暴击伤害 +30%", "unique": false, "icon": "res://assets/items/crit_lens.svg" },
	"vampiric_fang": { "name": "吸血獠牙", "rarity": "epic", "cost": 16, "kind": "lifesteal", "desc": "命中回复伤害3%血量", "unique": false, "icon": "res://assets/items/vampiric_fang.svg" },
	"blood_orb": { "name": "血珠", "rarity": "legendary", "cost": 25, "kind": "lifesteal", "desc": "命中回复伤害5%血量", "unique": false, "icon": "res://assets/items/blood_orb.svg" },
	"dodge_boots": { "name": "闪避靴", "rarity": "epic", "cost": 16, "kind": "dodge", "desc": "闪避 +8%", "unique": false, "icon": "res://assets/items/dodge_boots.svg" },
	"shadow_cloak": { "name": "影披风", "rarity": "legendary", "cost": 25, "kind": "dodge", "desc": "闪避 +12%", "unique": false, "icon": "res://assets/items/shadow_cloak.svg" },
	"regen_rune": { "name": "再生符文", "rarity": "epic", "cost": 16, "kind": "regen", "desc": "每秒回复1点血量", "unique": false, "icon": "res://assets/items/regen_rune.svg" },
	"phoenix_heart": { "name": "凤凰之心", "rarity": "legendary", "cost": 28, "kind": "regen", "desc": "每秒回复2血，血量上限 +20", "unique": false, "icon": "res://assets/items/phoenix_heart.svg" },
	# ==== 经济/成长 ====
	"xp_tome": { "name": "经验法典", "rarity": "epic", "cost": 16, "kind": "xp_gain", "desc": "获得经验 +15%", "unique": false, "icon": "res://assets/items/xp_tome.svg" },
	"xp_amulet": { "name": "学识项链", "rarity": "legendary", "cost": 25, "kind": "xp_gain", "desc": "获得经验 +25%", "unique": false, "icon": "res://assets/items/xp_amulet.svg" },
	"gold_pouch": { "name": "金币袋", "rarity": "quality", "cost": 12, "kind": "gold_gain", "desc": "获得金币 +15%", "unique": false, "icon": "res://assets/items/gold_pouch.svg" },
	"golden_idol": { "name": "黄金神像", "rarity": "legendary", "cost": 25, "kind": "gold_gain", "desc": "获得金币 +30%", "unique": false, "icon": "res://assets/items/golden_idol.svg" },
	# ==== 玩家侧基础 ====
	"shoes": { "name": "跑鞋", "rarity": "normal", "cost": 6, "kind": "move_speed", "desc": "移速 +10", "unique": false, "icon": "res://assets/items/shoes.svg" },
	"sprint_tech": { "name": "冲刺鞋", "rarity": "quality", "cost": 12, "kind": "move_speed", "desc": "移速 +15", "unique": false, "icon": "res://assets/items/sprint_tech.svg" },
	"armor": { "name": "劣质盔甲", "rarity": "normal", "cost": 6, "kind": "armor", "desc": "防御力 +1", "unique": false, "icon": "res://assets/items/armor.svg" },
	"steel_plate": { "name": "钢板甲", "rarity": "quality", "cost": 12, "kind": "armor", "desc": "防御力 +2", "unique": false, "icon": "res://assets/items/steel_plate.svg" },
	"reagent": { "name": "生命试剂", "rarity": "normal", "cost": 6, "kind": "max_hp", "desc": "血量上限 +10", "unique": false, "icon": "res://assets/items/reagent.svg" },
	"vitality_core": { "name": "活力核心", "rarity": "epic", "cost": 15, "kind": "max_hp", "desc": "血量上限 +25", "unique": false, "icon": "res://assets/items/vitality_core.svg" },
	"bandage": { "name": "绷带", "rarity": "normal", "cost": 6, "kind": "heal", "desc": "立即回复 10 血", "unique": false, "icon": "res://assets/items/bandage.svg" },
	"medkit": { "name": "医疗包", "rarity": "quality", "cost": 12, "kind": "heal", "desc": "立即回复 25 血", "unique": false, "icon": "res://assets/items/medkit.svg" },
	"clover": { "name": "幸运草", "rarity": "normal", "cost": 6, "kind": "luck", "desc": "幸运值 +1", "unique": false, "icon": "res://assets/items/clover.svg" },
	"lucky_coin": { "name": "幸运币", "rarity": "quality", "cost": 12, "kind": "luck", "desc": "幸运值 +2", "unique": false, "icon": "res://assets/items/lucky_coin.svg" },
	# ==== 唯一特殊 ====
	"ring": { "name": "咒戒", "rarity": "legendary", "cost": 25, "kind": "ring", "desc": "刷怪效率 ×2，所有武器攻击力 ×1.5", "unique": true, "icon": "res://assets/items/ring.svg" },
	"devil_contract": { "name": "恶魔契约", "rarity": "legendary", "cost": 30, "kind": "devil_contract", "desc": "所有武器攻击力 ×1.8，但每秒掉 1 血", "unique": true, "icon": "res://assets/items/devil_contract.svg" },
	"angel_wing": { "name": "天使之翼", "rarity": "legendary", "cost": 30, "kind": "angel_wing", "desc": "所有武器冷却 ×0.8，移速 +20%", "unique": true, "icon": "res://assets/items/angel_wing.svg" },
}

const RARITY_NAMES := { "normal": "普通", "quality": "优质", "epic": "史诗", "legendary": "传说" }
const RARITY_COLORS := {
	"normal": Color(0.78, 0.78, 0.78),
	"quality": Color(0.35, 0.85, 0.4),
	"epic": Color(0.65, 0.45, 0.95),
	"legendary": Color(0.95, 0.72, 0.25),
}

## 全部道具 id。
static func all_ids() -> Array:
	return ITEMS.keys()

## 唯一道具（购买后商店不再刷出）。
static func is_unique(item_id: String) -> bool:
	return ITEMS.has(item_id) and ITEMS[item_id]["unique"]

static func def(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func name(item_id: String) -> String:
	return def(item_id).get("name", item_id)

static func cost(item_id: String) -> int:
	return int(def(item_id).get("cost", 0))

static func kind(item_id: String) -> String:
	return def(item_id).get("kind", "")

static func desc(item_id: String) -> String:
	return def(item_id).get("desc", "")

static func rarity(item_id: String) -> String:
	return def(item_id).get("rarity", "normal")

static func rarity_name(item_id: String) -> String:
	return RARITY_NAMES.get(rarity(item_id), "普通")

static func rarity_color(item_id: String) -> Color:
	return RARITY_COLORS.get(rarity(item_id), Color.WHITE)

## 道具图标贴图路径（资产在 assets/items/）。
static func icon(item_id: String) -> String:
	return def(item_id).get("icon", "")

## 道具价格涨幅：每多持有一个，价格 ×(1 + 涨幅)。稀有度越高涨幅越快。
static func price_growth(item_id: String) -> float:
	match rarity(item_id):
		"legendary":
			return 0.8
		"epic":
			return 0.5
		"quality":
			return 0.3
		_:
			return 0.15

## 计算某把武器的最终属性（含道具加成）。公式单一来源，WeaponManager 与商店/背包 UI 共用。
## 规则：先加算后乘算 —— 攻击力 = (base + Σ加算) × Π乘算（咒戒 ×1.5 对全武器生效）。
static func weapon_final_stats(weapon: Node2D, counts: Dictionary) -> Dictionary:
	var flat := 0
	var mult := 1.0
	if weapon.is_melee:
		flat = counts.get("good_steel", 0)
		mult = pow(1.1, counts.get("whetstone", 0))
	else:
		flat = counts.get("blast_shot", 0)
		mult = pow(1.1, counts.get("gunpowder", 0))
	if counts.get("ring", 0) > 0:
		mult *= 1.5
	var cd_mult := 1.0
	if weapon.is_melee:
		cd_mult = pow(0.9, counts.get("handle", 0))
	else:
		cd_mult = pow(0.9, counts.get("gun_oil", 0))
	var speed: float = weapon.base_projectile_speed
	if not weapon.is_melee:
		speed += 50.0 * counts.get("scope", 0)
	var rng: float = weapon.base_range
	if weapon.is_melee:
		rng *= pow(1.1, counts.get("hammer", 0))
	return {
		"damage": int(round((weapon.base_damage + flat) * mult)),
		"cooldown": weapon.base_cooldown * cd_mult,
		"speed": speed,
		"range": rng,
	}
