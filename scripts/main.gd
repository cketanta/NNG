class_name Main
extends Node2D
## 主控制器：波次状态机、经济（经验/金币）、商店（武器购买/出售/合成 + 道具）、
## 天赋（人物天赋 + 每武器独立天赋）、背包/暂停菜单与游戏结束。

const XP_GEM_SCENE := preload("res://scenes/items/xp_gem.tscn")
const COIN_SCENE := preload("res://scenes/items/coin.tscn")
const HEART_SCENE := preload("res://scenes/items/heart.tscn")
const BOSS_SCRIPT := preload("res://scripts/enemies/enemy_boss.gd")  # BOSS 波结束条件判断用

enum GameState { START, COMBAT, SHOP, GAMEOVER }

const WEAPON_IDS := ["blade", "revolver", "whip", "staff", "splitter", "black_hole_gun", "boomerang"]  # 商店售卖的武器（破旧手枪不在商店，仅初始/可出售）
const WEAPON_NAMES := {
	"pistol": "破旧手枪", "blade": "短刃", "revolver": "左轮手枪",
	"whip": "鞭子", "staff": "法杖", "splitter": "分裂者",
	"black_hole_gun": "黑洞枪", "boomerang": "回旋镖",
}
const WEAPON_BASE_COST := {
	"pistol": 4, "blade": 8, "revolver": 6,
	"whip": 5, "staff": 6, "splitter": 7,
	"black_hole_gun": 9, "boomerang": 7,
}

const DIFFICULTY_IDS := ["easy", "normal", "hard"]
const DIFFICULTIES := {
	"easy":   { "name": "简单", "spawn_interval_mult": 1.2, "enemy_hp_mult": 0.8, "enemy_attack_mult": 0.7 },
	"normal": { "name": "普通", "spawn_interval_mult": 1.0, "enemy_hp_mult": 1.0, "enemy_attack_mult": 1.0 },
	"hard":   { "name": "困难", "spawn_interval_mult": 0.8, "enemy_hp_mult": 2.0, "enemy_attack_mult": 2.0 },
}

@export var wave_duration: float = 50.0
@export var auto_pause_menus := true

var kills := 0
var elapsed := 0.0
var wave_number := 0
var wave_timer := 0.0
var game_state := GameState.START
var difficulty_id := "normal"
var difficulty: Dictionary = DIFFICULTIES["normal"]
var test_mode := false  # 测试模式：本局可按 L 打开调试面板

# --- 商店道具（每波随机 5 个） ---
var shop_item_offerings: Array[String] = []
var purchased_unique: Array[String] = []
var bought_items_this_wave: Dictionary = {}
const SHOP_REFRESH_COST := 5   # 刷新商品花费
const SHOP_REFRESH_MAX := 3    # 每波最多刷新次数
var shop_refresh_count := 0    # 本波已刷新次数

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var hud: CanvasLayer = $HUD
@onready var weapon_manager: Node2D = $Player/WeaponManager
@onready var shop_panel: ShopPanel = $HUD/ShopPanel
@onready var talent_panel: TalentPanel = $HUD/TalentPanel
@onready var backpack_panel: BackpackPanel = $HUD/BackpackPanel
@onready var difficulty_panel: DifficultyPanel = $HUD/DifficultyPanel
@onready var pause_panel: PausePanel = $HUD/PausePanel
@onready var debug_panel: DebugPanel = $HUD/DebugPanel
@onready var bestiary_panel: BestiaryPanel = $HUD/BestiaryPanel

func _ready() -> void:
	player.hp_changed.connect(_on_player_hp_changed)
	player.xp_changed.connect(_on_player_xp_changed)
	player.gold_changed.connect(_on_player_gold_changed)
	player.level_up.connect(_on_player_level_up)
	player.died.connect(_on_player_died)
	spawner.enemy_killed.connect(_on_enemy_killed)
	weapon_manager.attack_mode_changed.connect(_on_attack_mode_changed)

	weapon_manager.rebuild(player.weapon_slots)  # 开局初始手枪入槽

	hud.update_hp(player.max_hp, player.max_hp)
	hud.update_kills(0)
	hud.update_time(0.0)
	hud.update_gold(player.gold)
	hud.update_xp(0, player.xp_max)
	hud.update_wave(0)
	hud.set_attack_mode(weapon_manager.attack_mode)

	shop_panel.setup(self)
	talent_panel.setup(self)
	backpack_panel.setup(self)
	difficulty_panel.setup(self)
	pause_panel.setup(self)
	debug_panel.setup(self)
	bestiary_panel.setup(self)

	_apply_difficulty_to_spawner()
	open_difficulty()

func _process(delta: float) -> void:
	if game_state != GameState.COMBAT:
		return
	elapsed += delta
	wave_timer += delta
	hud.update_time(elapsed)
	hud.update_wave_timer(wave_duration - wave_timer)
	if wave_timer >= wave_duration:
		end_wave()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_backpack") and game_state == GameState.COMBAT and not debug_panel.visible:
		get_viewport().set_input_as_handled()
		open_backpack()
	elif event.is_action_pressed("toggle_talent") and game_state == GameState.COMBAT \
			and not backpack_panel.visible and not pause_panel.visible and not debug_panel.visible:
		get_viewport().set_input_as_handled()
		open_talent()
	elif event.is_action_pressed("toggle_debug") and test_mode and game_state == GameState.COMBAT \
			and not backpack_panel.visible and not pause_panel.visible:
		get_viewport().set_input_as_handled()
		open_debug()
	elif event.is_action_pressed("ui_cancel") and game_state == GameState.COMBAT:
		if not backpack_panel.visible and not pause_panel.visible and not debug_panel.visible \
				and not talent_panel.visible:
			get_viewport().set_input_as_handled()
			open_pause()

# --- 开局流程 ---

func weapon_ids() -> Array:
	return WEAPON_IDS

func weapon_name(id: String) -> String:
	return WEAPON_NAMES.get(id, id)

func difficulty_ids() -> Array:
	return DIFFICULTY_IDS

func difficulty_name(id: String) -> String:
	return DIFFICULTIES[id]["name"]

func open_difficulty() -> void:
	game_state = GameState.START
	difficulty_panel.visible = true
	get_tree().paused = true

func choose_difficulty(id: String) -> void:
	difficulty_id = id
	difficulty = DIFFICULTIES[id]
	_apply_difficulty_to_spawner()
	difficulty_panel.visible = false
	start_game()

## 测试模式：不选难度，按普通倍率直接开始；本局可按 L 打开调试面板。
func choose_test_mode() -> void:
	test_mode = true
	difficulty_id = "normal"
	difficulty = DIFFICULTIES["normal"]
	_apply_difficulty_to_spawner()
	difficulty_panel.visible = false
	start_game()

func _apply_difficulty_to_spawner() -> void:
	spawner.set_difficulty(
		difficulty["spawn_interval_mult"],
		difficulty["enemy_hp_mult"],
		difficulty["enemy_attack_mult"],
		difficulty.get("spawn_density_mult", 1.0))
	wave_duration = float(difficulty.get("wave_duration", 50.0))

## 开局直接开始战斗（初始破旧手枪已入槽）。
func start_game() -> void:
	player.visible = true
	weapon_manager.rebuild(player.weapon_slots)
	get_tree().paused = false
	start_next_wave()

## 兼容旧测试入口：忽略武器参数，直接开始战斗。
func start_with_weapon(_weapon_id: String) -> void:
	start_game()

# --- 波次流程 ---

func start_next_wave() -> void:
	wave_number += 1
	game_state = GameState.COMBAT
	wave_timer = 0.0
	spawner.begin_wave(wave_number)
	hud.update_wave(wave_number)

func end_wave() -> void:
	# BOSS 波：BOSS 存活时波次不结束，击杀后才能进商店。
	if wave_number % 5 == 0 and _boss_alive():
		return
	spawner.end_wave()
	_clear_remaining_enemies()
	open_shop()

## BOSS 是否存活（BOSS 波结束条件）。
func _boss_alive() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_script() == BOSS_SCRIPT:
			return true
	return false

func _clear_remaining_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

# --- 商店 ---

func open_shop() -> void:
	game_state = GameState.SHOP
	if auto_pause_menus:
		get_tree().paused = true
	shop_refresh_count = 0
	refresh_shop_items()
	shop_panel.visible = true
	shop_panel.refresh()

## 刷新商店道具：花费金币重roll 5 个道具（每波限次）。
func refresh_shop_offerings() -> bool:
	if player.gold < SHOP_REFRESH_COST or shop_refresh_count >= SHOP_REFRESH_MAX:
		return false
	player.gold -= SHOP_REFRESH_COST
	player.gold_changed.emit(player.gold)
	shop_refresh_count += 1
	refresh_shop_items()
	shop_panel.refresh()
	return true

func close_shop() -> void:
	shop_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false
	start_next_wave()

## 每波随机挑 5 个不重复道具；已购买的唯一道具不再进入候选池。
func refresh_shop_items() -> void:
	bought_items_this_wave.clear()
	var pool: Array[String] = []
	for item_id in ItemDefs.all_ids():
		if ItemDefs.is_unique(item_id) and item_id in purchased_unique:
			continue
		pool.append(item_id)
	pool.shuffle()
	shop_item_offerings = pool.slice(0, 5)

## 道具当前价格：基础价 × (1 + 稀有度涨幅 × 已有个数)。越买越贵。
func item_price(item_id: String) -> int:
	var base := ItemDefs.cost(item_id)
	var owned: int = player.item_counts.get(item_id, 0)
	return int(round(base * (1.0 + ItemDefs.price_growth(item_id) * owned)))

## 购买道具：校验金币/每波一次/唯一 -> 扣款 -> 玩家侧生效。
func buy_item(item_id: String) -> bool:
	var cost := item_price(item_id)
	if player.gold < cost:
		return false
	if bought_items_this_wave.get(item_id, false):
		return false
	if ItemDefs.is_unique(item_id) and item_id in purchased_unique:
		return false
	player.gold -= cost
	player.gold_changed.emit(player.gold)
	player.buy_item(item_id)
	bought_items_this_wave[item_id] = true
	if ItemDefs.is_unique(item_id):
		purchased_unique.append(item_id)
		if item_id == "ring":
			spawner.set_spawn_rate_mult(2.0)
	shop_panel.refresh()
	return true

## 武器购买价格：基础价 × (1 + 0.5×(等级-1))。
func weapon_cost(id: String, level: int) -> int:
	var effective := maxi(level, 1)
	return int(round(float(WEAPON_BASE_COST.get(id, 6)) * (1.0 + 0.5 * float(effective - 1))))

## 购买武器：空槽入槽；槽满且已有同名 → 自动合成；槽满且无同名 → 失败。
func buy_weapon(id: String) -> bool:
	var cost := weapon_cost(id, player.weapon_level(id))
	if player.gold < cost:
		return false
	if not player.add_weapon(id, 1):
		return false  # 槽满且无同名
	player.gold -= cost
	player.gold_changed.emit(player.gold)
	weapon_manager.rebuild(player.weapon_slots)
	shop_panel.refresh()
	return true

## 出售武器：售价 = 当前购买价值一半。
func sell_weapon(idx: int) -> bool:
	if idx < 0 or idx >= player.weapon_slots.size():
		return false
	var slot: Dictionary = player.weapon_slots[idx]
	var value := weapon_cost(slot.id, slot.level) / 2
	player.remove_slot(idx)
	player.gold += value
	player.gold_changed.emit(player.gold)
	weapon_manager.rebuild(player.weapon_slots)
	shop_panel.refresh()
	return true

## 商店合成：点选两把同名武器 → 等级相加、保留高等级天赋树、点数转化。
func combine_weapons(a: int, b: int) -> bool:
	if player.combine_slots(a, b):
		weapon_manager.rebuild(player.weapon_slots)
		shop_panel.refresh()
		return true
	return false

## 人物属性摘要（商店/背包/天赋共用）。
func player_stats_text() -> String:
	return "移速 %d\n防御 %d\n血量 %d/%d\n幸运 %d" % [
		int(player.speed * player.move_speed_mult + player.move_speed_bonus),
		player.defense,
		player.hp, player.max_hp,
		player.luck,
	]

# --- 天赋 ---

func open_talent() -> void:
	if auto_pause_menus:
		get_tree().paused = true
	talent_panel.visible = true
	talent_panel.refresh()

func close_talent() -> void:
	talent_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false

## 加点武器天赋（对选中槽位的武器天赋树）。
func unlock_weapon_talent(slot_idx: int, talent_id: String) -> bool:
	if slot_idx < 0 or slot_idx >= player.weapon_slots.size():
		return false
	var slot: Dictionary = player.weapon_slots[slot_idx]
	if slot.tree.unlock(slot.id, talent_id):
		talent_panel.refresh()
		return true
	return false

## 加点人物天赋（树状节点）。
func unlock_personal_talent(talent_id: String) -> bool:
	if player.player_talent.unlock(talent_id):
		player.apply_personal_talents()
		talent_panel.refresh()
		backpack_panel.refresh()
		return true
	return false

# --- 背包 ---

func open_backpack() -> void:
	if auto_pause_menus:
		get_tree().paused = true
	backpack_panel.visible = true
	backpack_panel.refresh()

func close_backpack() -> void:
	backpack_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false

# --- 调试面板（测试模式） ---

func open_debug() -> void:
	if auto_pause_menus:
		get_tree().paused = true
	debug_panel.visible = true
	debug_panel.refresh()

func close_debug() -> void:
	debug_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false

func open_bestiary() -> void:
	if auto_pause_menus:
		get_tree().paused = true
	bestiary_panel.visible = true

func close_bestiary() -> void:
	bestiary_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false

func set_wave_number(n: int) -> void:
	wave_number = maxi(n, 1)
	_clear_remaining_enemies()
	spawner.begin_wave(wave_number)
	hud.update_wave(wave_number)

func set_wave_duration(seconds: float) -> void:
	wave_duration = maxf(seconds, 1.0)

func debug_give_item(item_id: String) -> void:
	player.buy_item(item_id)
	if item_id == "ring":
		spawner.set_spawn_rate_mult(2.0)
	debug_panel.refresh()

func debug_remove_item(item_id: String) -> void:
	var before: int = player.item_counts.get(item_id, 0)
	player.remove_item(item_id)
	if item_id == "ring" and before == 1:
		spawner.set_spawn_rate_mult(1.0)
	debug_panel.refresh()

func debug_set_item_count(item_id: String, count: int) -> void:
	var current: int = player.item_counts.get(item_id, 0)
	var target := maxi(count, 0)
	if target > current:
		for i in range(target - current):
			player.buy_item(item_id)
		if item_id == "ring" and target > 0:
			spawner.set_spawn_rate_mult(2.0)
	elif target < current:
		for i in range(current - target):
			player.remove_item(item_id)
		if item_id == "ring" and target <= 0:
			spawner.set_spawn_rate_mult(1.0)
	debug_panel.refresh()

## 调试：给玩家一把武器（空槽/同名自动合成）。
func debug_give_weapon(id: String) -> void:
	player.add_weapon(id, 1)
	weapon_manager.rebuild(player.weapon_slots)
	debug_panel.refresh()

## 调试：移除最后一个指定武器的槽位（同名留一个）。
func debug_remove_weapon(id: String) -> void:
	var idx: int = player.find_slot_by_id(id)
	if idx >= 0:
		player.remove_slot(idx)
	weapon_manager.rebuild(player.weapon_slots)
	debug_panel.refresh()

# --- 暂停菜单 ---

func open_pause() -> void:
	if auto_pause_menus:
		get_tree().paused = true
	pause_panel.visible = true
	pause_panel.refresh()

func close_pause() -> void:
	pause_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false

# --- 玩家/刷怪器/拾取物的信号 ---

func _on_player_hp_changed(current: int, max_hp: int) -> void:
	hud.update_hp(current, max_hp)

func _on_player_xp_changed(current: int, xp_max: int) -> void:
	hud.update_xp(current, xp_max)

func _on_player_gold_changed(total: int) -> void:
	hud.update_gold(total)
	if shop_panel.visible:
		shop_panel.refresh()

func _on_player_level_up(_level: int) -> void:
	# 人物天赋与经验系统挂钩：升级 +1 人物天赋点，屏幕下方一行提示。
	player.player_talent.points += 1
	player.apply_personal_talents()
	hud.show_talent_hint("获得 1 人物天赋点，按 T 打开天赋界面")

func end_game(reason: String) -> void:
	game_state = GameState.GAMEOVER
	spawner.end_wave()
	get_tree().paused = false
	# 清理残留弹幕（结算画面不再物理解算，性能与整洁）。
	for n in get_tree().get_nodes_in_group("friendly_projectiles"):
		if is_instance_valid(n):
			n.queue_free()
	for n in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(n):
			n.queue_free()
	var wm := player.get_node_or_null("WeaponManager")
	if wm != null:
		wm.call("halt")
	hud.show_result(reason, difficulty_name(difficulty_id), kills, wave_number,
		player.level, player.gold, elapsed)

func end_game_from_pause() -> void:
	pause_panel.visible = false
	get_tree().paused = false
	end_game("本局结束")

func _on_player_died() -> void:
	end_game("游戏结束")

func _on_enemy_killed(global_pos: Vector2, xp_value: int, gold_value: int) -> void:
	kills += 1
	hud.update_kills(kills)
	# 经验/金币加成：人物天赋 + 道具（经验法典/金币袋等）。
	var fx: Dictionary = player.player_talent.effects()
	var final_xp := maxi(1, int(round(xp_value * (1.0 + (fx.xp_gain + player.item_xp_gain) / 100.0))))
	var final_gold := maxi(1, int(round(gold_value * (1.0 + (fx.gold_gain + player.item_gold_gain) / 100.0))))
	spawn_xp_gem(global_pos, final_xp)
	spawn_coin(global_pos, final_gold)
	var heart_chance: float = 0.05 + 0.05 * player.luck
	if randf() < heart_chance:
		spawn_heart(global_pos)

func spawn_xp_gem(global_pos: Vector2, xp_value: int) -> void:
	var gem := XP_GEM_SCENE.instantiate()
	gem.value = xp_value
	add_child(gem)
	gem.global_position = global_pos
	gem.collected.connect(_on_gem_collected)

func _on_gem_collected(value: int) -> void:
	player.gain_xp(value)

func spawn_coin(global_pos: Vector2, gold_value: int) -> void:
	var coin := COIN_SCENE.instantiate()
	coin.value = gold_value
	add_child(coin)
	coin.global_position = global_pos
	coin.collected.connect(_on_coin_collected)

func _on_coin_collected(value: int) -> void:
	player.gain_gold(value)

func spawn_heart(global_pos: Vector2) -> void:
	var heart := HEART_SCENE.instantiate()
	heart.value = 1
	add_child(heart)
	heart.global_position = global_pos
	heart.collected.connect(_on_heart_collected)

func _on_heart_collected(value: int) -> void:
	player.heal(value)

func _on_attack_mode_changed(mode: int) -> void:
	hud.set_attack_mode(mode)
