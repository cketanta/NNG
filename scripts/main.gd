class_name Main
extends Node2D
## 主控制器：波次状态机、经济（经验/金币）、商店/天赋/背包菜单（带暂停）、HUD 更新与游戏结束。

const XP_GEM_SCENE := preload("res://scenes/items/xp_gem.tscn")
const COIN_SCENE := preload("res://scenes/items/coin.tscn")
const HEART_SCENE := preload("res://scenes/items/heart.tscn")

enum GameState { START, COMBAT, SHOP, GAMEOVER }

const WEAPON_IDS := ["whip", "staff", "splitter", "black_hole_gun"]
const WEAPON_BASE_COST := { "whip": 8, "staff": 6, "splitter": 10, "black_hole_gun": 12 }
const WEAPON_NAMES := { "whip": "鞭子", "staff": "法杖", "splitter": "分裂者", "black_hole_gun": "黑洞枪" }
const WEAPON_NODE_NAMES := { "whip": "Whip", "staff": "Staff", "splitter": "Splitter", "black_hole_gun": "BlackHoleGun" }

const DIFFICULTY_IDS := ["easy", "normal", "hard"]
const DIFFICULTIES := {
	"easy":   { "name": "简单", "spawn_interval_mult": 1.2, "enemy_hp_mult": 0.8, "enemy_attack_mult": 0.7 },
	"normal": { "name": "普通", "spawn_interval_mult": 1.0, "enemy_hp_mult": 1.0, "enemy_attack_mult": 1.0 },
	"hard":   { "name": "困难", "spawn_interval_mult": 0.8, "enemy_hp_mult": 2.0, "enemy_attack_mult": 2.0 },
}

@export var wave_duration: float = 25.0
@export var auto_pause_menus := true

var kills := 0
var elapsed := 0.0
var wave_number := 0
var wave_timer := 0.0
var game_state := GameState.START
var talent_tree: TalentTree
var difficulty_id := "normal"
var difficulty: Dictionary = DIFFICULTIES["normal"]

# --- 商店道具（每波随机 5 个） ---
var shop_item_offerings: Array[String] = []
var purchased_unique: Array[String] = []  # 已购买的唯一道具（不再刷出）
var bought_items_this_wave: Dictionary = {}  # 本波已购买的道具（每波重置，每道具本波仅可购一次）

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var hud: CanvasLayer = $HUD
@onready var weapon_manager: Node2D = $Player/WeaponManager
@onready var shop_panel: ShopPanel = $HUD/ShopPanel
@onready var talent_panel: TalentPanel = $HUD/TalentPanel
@onready var backpack_panel: BackpackPanel = $HUD/BackpackPanel
@onready var start_panel: StartPanel = $HUD/StartPanel
@onready var difficulty_panel: DifficultyPanel = $HUD/DifficultyPanel
@onready var pause_panel: PausePanel = $HUD/PausePanel

func _ready() -> void:
	talent_tree = TalentTree.new()
	player.hp_changed.connect(_on_player_hp_changed)
	player.xp_changed.connect(_on_player_xp_changed)
	player.gold_changed.connect(_on_player_gold_changed)
	player.level_up.connect(_on_player_level_up)
	player.died.connect(_on_player_died)
	spawner.enemy_killed.connect(_on_enemy_killed)
	weapon_manager.attack_mode_changed.connect(_on_attack_mode_changed)

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
	start_panel.setup(self)
	difficulty_panel.setup(self)
	pause_panel.setup(self)

	_apply_difficulty_to_spawner()
	open_difficulty()

func _process(delta: float) -> void:
	if game_state != GameState.COMBAT:
		return
	elapsed += delta
	wave_timer += delta
	hud.update_time(elapsed)
	if wave_timer >= wave_duration:
		end_wave()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_backpack") and game_state == GameState.COMBAT:
		open_backpack()
	elif event.is_action_pressed("ui_cancel") and game_state == GameState.COMBAT:
		open_pause()

# --- 开局流程 ---

func weapon_ids() -> Array:
	return WEAPON_IDS

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
	open_start()

func _apply_difficulty_to_spawner() -> void:
	spawner.set_difficulty(
		difficulty["spawn_interval_mult"],
		difficulty["enemy_hp_mult"],
		difficulty["enemy_attack_mult"],
		difficulty.get("spawn_density_mult", 1.0))
	wave_duration = float(difficulty.get("wave_duration", 25.0))

func open_start() -> void:
	game_state = GameState.START
	start_panel.visible = true
	get_tree().paused = true

## 选武面板按 Esc：返回难度选择（上一级）。
func back_to_difficulty() -> void:
	start_panel.visible = false
	difficulty_panel.visible = true

## 用选中的初始武器开战；其余武器保持 0 级（可在商店购买）。
func start_with_weapon(weapon_id: String) -> void:
	player.weapon_levels[weapon_id] = 1
	difficulty_panel.visible = false
	start_panel.visible = false
	get_tree().paused = false
	start_next_wave()

# --- 波次流程 ---

func start_next_wave() -> void:
	wave_number += 1
	game_state = GameState.COMBAT
	wave_timer = 0.0
	spawner.begin_wave(wave_number)
	hud.update_wave(wave_number)

func end_wave() -> void:
	spawner.end_wave()
	_clear_remaining_enemies()
	open_shop()

func _clear_remaining_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

# --- 商店 ---

func open_shop() -> void:
	game_state = GameState.SHOP
	if auto_pause_menus:
		get_tree().paused = true
	refresh_shop_items()
	shop_panel.visible = true
	shop_panel.refresh()

## 每波随机挑 5 个不重复道具；已购买的唯一道具不再进入候选池。
## 新的一波：重置「本波已购买」记录（道具每波仅可购一次）。
func refresh_shop_items() -> void:
	bought_items_this_wave.clear()
	var pool: Array[String] = []
	for item_id in ItemDefs.all_ids():
		if ItemDefs.is_unique(item_id) and item_id in purchased_unique:
			continue
		pool.append(item_id)
	pool.shuffle()
	shop_item_offerings = pool.slice(0, 5)

## 购买道具：校验金币与唯一性 -> 扣款 -> 玩家侧生效 -> 唯一道具记入已购。
func buy_item(item_id: String) -> bool:
	var cost := ItemDefs.cost(item_id)
	if player.gold < cost:
		return false
	if bought_items_this_wave.get(item_id, false):
		return false  # 本波该道具已购，不可再购
	if ItemDefs.is_unique(item_id) and item_id in purchased_unique:
		return false
	player.gold -= cost
	player.gold_changed.emit(player.gold)
	player.buy_item(item_id)
	bought_items_this_wave[item_id] = true  # 本波该道具已购，不可再购
	if ItemDefs.is_unique(item_id):
		purchased_unique.append(item_id)
		if item_id == "ring":
			spawner.set_spawn_rate_mult(2.0)  # 咒戒：刷怪效率 ×2
	shop_panel.refresh()
	return true

func close_shop() -> void:
	shop_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false
	start_next_wave()

func weapon_cost(weapon_id: String) -> int:
	var level: int = player.weapon_levels.get(weapon_id, 0)
	var effective := maxi(level, 1)  # 0 级（未拥有）= 按基础价首购
	return int(round(float(WEAPON_BASE_COST.get(weapon_id, 6)) * (1.0 + 0.5 * float(effective - 1))))

func buy_weapon(weapon_id: String) -> bool:
	var cost := weapon_cost(weapon_id)
	if player.gold < cost:
		return false
	player.gold -= cost
	player.gold_changed.emit(player.gold)
	player.add_weapon_level(weapon_id)
	shop_panel.refresh()
	return true

func weapon_name(weapon_id: String) -> String:
	return WEAPON_NAMES.get(weapon_id, weapon_id)

## 某等级下的效果描述；商店与背包共用。
func weapon_effect_text(weapon_id: String, level: int) -> String:
	match weapon_id:
		"whip":
			return "近战：Lv.%d 段连斩，逐段扇出" % level
		"staff":
			return "远程：每次发射 %d 枚弹幕" % level
		"splitter":
			return "分裂：命中分裂 %d 枚小弹（每级+1）" % _weapon_node("Splitter").split_count_for_level(level)
		"black_hole_gun":
			return "黑洞：命中产生黑洞（范围 Lv.%d，半径 %d）" % [level, int(_weapon_node("BlackHoleGun").black_hole_radius_for_level(level))]
	return ""

func _weapon_node(node_name: String) -> Node2D:
	return player.get_node("WeaponManager/" + node_name)

## 人物属性摘要（移速/防御/血量/幸运），商店与背包共用。
func player_stats_text() -> String:
	return "移速 %d\n防御 %d\n血量 %d/%d\n幸运 %d" % [
		int(player.speed + player.move_speed_bonus),
		player.defense,
		player.hp, player.max_hp,
		player.luck,
	]

## 某武器的属性摘要（含当前道具加成），商店与背包共用。
func weapon_attr_text(weapon_id: String) -> String:
	var node := _weapon_node(WEAPON_NODE_NAMES.get(weapon_id, weapon_id))
	var stats: Dictionary = ItemDefs.weapon_final_stats(node, player.item_counts)
	if node.is_melee:
		return "攻击 %d    冷却 %.1fs    距离 %d" % [stats.damage, stats.cooldown, int(stats.range)]
	return "攻击 %d    冷却 %.1fs    弹速 %d" % [stats.damage, stats.cooldown, int(stats.speed)]

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

func _on_talent_purchased(branch_id: String) -> void:
	if talent_tree.unlock(branch_id):
		player.apply_talent_stats(talent_tree)
		talent_panel.refresh()
		backpack_panel.refresh()

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
	# v1.1.0 天赋树停用：升级不再发天赋点、不弹天赋窗（框架保留待后续重做）。
	pass

func _on_player_died() -> void:
	game_state = GameState.GAMEOVER
	spawner.end_wave()
	hud.show_game_over(elapsed)

func _on_enemy_killed(global_pos: Vector2, xp_value: int, gold_value: int) -> void:
	kills += 1
	hud.update_kills(kills)
	spawn_xp_gem(global_pos, xp_value)
	spawn_coin(global_pos, gold_value)
	# 红心掉率随幸运值提升：基础 5%，每点幸运 +5%。
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
