class_name ItemDefs
extends RefCounted
## 道具定义表：id -> { name, rarity, cost, kind, desc, unique }。
## kind 含义：
##   ranged_mult / melee_mult      -> 武器攻击力乘算（公式在 weapon_manager）
##   ranged_flat / melee_flat      -> 武器攻击力加算
##   ranged_speed                  -> 远程弹速加算
##   ranged_cooldown / melee_cooldown -> 武器冷却乘算
##   melee_range                   -> 近战攻击距离加算
##   ring                          -> 咒戒（唯一：刷怪效率×2 + 全武器攻击力×1.5）
##   move_speed / armor / max_hp / heal / luck -> 玩家侧即时生效属性

const ITEMS := {
	"gunpowder": { "name": "动能火药", "rarity": "epic", "cost": 15, "kind": "ranged_mult", "desc": "远程武器攻击力 ×1.1", "unique": false },
	"scope": { "name": "瞄准镜", "rarity": "quality", "cost": 12, "kind": "ranged_speed", "desc": "远程武器弹速 +50", "unique": false },
	"blast_shot": { "name": "爆破弹", "rarity": "normal", "cost": 6, "kind": "ranged_flat", "desc": "远程武器攻击力 +1", "unique": false },
	"gun_oil": { "name": "枪械润滑剂", "rarity": "quality", "cost": 12, "kind": "ranged_cooldown", "desc": "远程武器冷却 ×0.9", "unique": false },
	"whetstone": { "name": "磨刀石", "rarity": "epic", "cost": 15, "kind": "melee_mult", "desc": "近战武器攻击力 ×1.1", "unique": false },
	"good_steel": { "name": "好钢", "rarity": "normal", "cost": 6, "kind": "melee_flat", "desc": "近战武器攻击力 +1", "unique": false },
	"handle": { "name": "舒适刀柄", "rarity": "quality", "cost": 12, "kind": "melee_cooldown", "desc": "近战武器冷却 ×0.9", "unique": false },
	"hammer": { "name": "锻锤", "rarity": "quality", "cost": 12, "kind": "melee_range_mult", "desc": "近战攻击距离 +10%", "unique": false },
	"ring": { "name": "咒戒", "rarity": "legendary", "cost": 25, "kind": "ring", "desc": "刷怪效率 ×2，所有武器攻击力 ×1.5", "unique": true },
	"shoes": { "name": "跑鞋", "rarity": "normal", "cost": 6, "kind": "move_speed", "desc": "移速 +10", "unique": false },
	"armor": { "name": "劣质盔甲", "rarity": "normal", "cost": 6, "kind": "armor", "desc": "防御力 +1", "unique": false },
	"reagent": { "name": "生命试剂", "rarity": "normal", "cost": 6, "kind": "max_hp", "desc": "血量上限 +10", "unique": false },
	"bandage": { "name": "绷带", "rarity": "normal", "cost": 6, "kind": "heal", "desc": "立即回复 10 血", "unique": false },
	"clover": { "name": "幸运草", "rarity": "normal", "cost": 6, "kind": "luck", "desc": "幸运值 +1", "unique": false },
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
