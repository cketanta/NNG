class_name Main
extends Node2D
## 主控制器：波次状态机、经济（经验/金币）、攻击方式选择、天赋树加点、商店/背包/暂停菜单与游戏结束。
## 攻击方式：初始破旧手枪；首次升级二选一（短刃/左轮）；天赋树围绕所选攻击方式，T 键加点（三选一）。
## 商店为空商店（武器升级已删、道具系统暂停使用但框架保留）。

const XP_GEM_SCENE := preload("res://scenes/items/xp_gem.tscn")
const COIN_SCENE := preload("res://scenes/items/coin.tscn")
const HEART_SCENE := preload("res://scenes/items/heart.tscn")

enum GameState { START, COMBAT, SHOP, GAMEOVER }

const ATTACK_IDS := ["pistol", "blade", "revolver"]
const ATTACK_NAMES := { "pistol": "破旧手枪", "blade": "短刃", "revolver": "左轮手枪" }
const ATTACK_DESCS := {
	"pistol": "初始攻击方式，单发子弹",
	"blade": "近战挥砍，攻守均衡",
	"revolver": "远程高伤，射速偏慢",
}
const ATTACK_NODE_NAMES := { "pistol": "Pistol", "blade": "Blade", "revolver": "Revolver" }

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
var test_mode := false  # 测试模式：本局可按 L 打开调试面板
var attack_choice_done := false  # 是否已选择攻击方式（首次升级触发）

# --- 商店道具框架（道具系统暂停使用，保留数据与函数） ---
var shop_item_offerings: Array[String] = []
var purchased_unique: Array[String] = []
var bought_items_this_wave: Dictionary = {}

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var hud: CanvasLayer = $HUD
@onready var weapon_manager: Node2D = $Player/WeaponManager
@onready var shop_panel: ShopPanel = $HUD/ShopPanel
@onready var talent_panel: TalentPanel = $HUD/TalentPanel
@onready var backpack_panel: BackpackPanel = $HUD/BackpackPanel
@onready var attack_select_panel: AttackSelectPanel = $HUD/AttackSelectPanel
@onready var difficulty_panel: DifficultyPanel = $HUD/DifficultyPanel
@onready var pause_panel: PausePanel = $HUD/PausePanel
@onready var debug_panel: DebugPanel = $HUD/DebugPanel

func _ready() -> void:
	talent_tree = TalentTree.new()
	player.talent_tree = talent_tree  # 注入玩家，攻击方式每帧读它计算天赋终值
	player.attack_id = "pistol"
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
	attack_select_panel.setup(self)
	difficulty_panel.setup(self)
	pause_panel.setup(self)
	debug_panel.setup(self)

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

func attack_ids() -> Array:
	return ATTACK_IDS

func attack_name(id: String) -> String:
	return ATTACK_NAMES.get(id, id)

func attack_desc(id: String) -> String:
	return ATTACK_DESCS.get(id, "")

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
	wave_duration = float(difficulty.get("wave_duration", 25.0))

## 开局直接以初始攻击方式（破旧手枪）进入战斗。
func start_game() -> void:
	player.visible = true  # 开局菜单结束，进入战斗才渲染玩家
	weapon_manager.set_active_attack("pistol")
	get_tree().paused = false
	start_next_wave()

## 兼容旧测试入口：忽略武器参数，直接开始战斗（初始破旧手枪）。
func start_with_weapon(_weapon_id: String) -> void:
	start_game()

# --- 攻击方式选择（首次升级） ---

func choose_attack(attack_id: String) -> void:
	attack_choice_done = true
	player.attack_id = attack_id
	player.weapon_levels[attack_id] = 1
	talent_tree.attack_id = attack_id
	weapon_manager.set_active_attack(attack_id)
	attack_select_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false
	# 选择攻击方式即送 1 点天赋，引导打开天赋树。
	talent_tree.points += 1
	hud.show_talent_hint("已选择 %s！获得 1 天赋点，按 T 打开天赋树" % attack_name(attack_id))

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

# --- 商店（空商店：无武器升级、无道具出售，只显示状态 + 进入下一波） ---

func open_shop() -> void:
	game_state = GameState.SHOP
	if auto_pause_menus:
		get_tree().paused = true
	shop_panel.visible = true
	shop_panel.refresh()

func close_shop() -> void:
	shop_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false
	start_next_wave()

## 每波随机挑 5 个不重复道具；已购买的唯一道具不再进入候选池（道具框架保留，调试可用）。
func refresh_shop_items() -> void:
	bought_items_this_wave.clear()
	var pool: Array[String] = []
	for item_id in ItemDefs.all_ids():
		if ItemDefs.is_unique(item_id) and item_id in purchased_unique:
			continue
		pool.append(item_id)
	pool.shuffle()
	shop_item_offerings = pool.slice(0, 5)

## 道具购买：框架保留（道具系统暂停使用，商店不再调用；调试面板仍可用）。
func buy_item(item_id: String) -> bool:
	var cost := ItemDefs.cost(item_id)
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

# --- 天赋 ---

func open_talent() -> void:
	if not attack_choice_done:
		return  # 未选择攻击方式前不能加天赋
	if auto_pause_menus:
		get_tree().paused = true
	talent_panel.visible = true
	talent_panel.refresh()

func close_talent() -> void:
	talent_panel.visible = false
	if auto_pause_menus:
		get_tree().paused = false

func _on_talent_purchased(attack_id: String, talent_id: String) -> void:
	if talent_tree.unlock(attack_id, talent_id):
		talent_panel.refresh()

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

## 人物属性摘要（商店与背包共用）。
func player_stats_text() -> String:
	return "移速 %d\n防御 %d\n血量 %d/%d\n幸运 %d" % [
		int(player.speed * player.move_speed_mult + player.move_speed_bonus),
		player.defense,
		player.hp, player.max_hp,
		player.luck,
	]

## 当前攻击方式摘要（背包显示）。
func attack_info_text(attack_id: String) -> String:
	if attack_id == "" or attack_id == "pistol":
		return "当前: 破旧手枪（初始单发子弹）"
	var tree_id := attack_id
	var owned_ids: Array = talent_tree.owned_ids(tree_id)
	var tree_name := "短刃天赋" if tree_id == "blade" else "左轮天赋"
	return "当前: %s\n已点 %d 个天赋（%s）" % [attack_name(attack_id), owned_ids.size(), tree_name]

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

## 调试：设置当前波数并立即以新波次强度重开（清掉场上怪）。
func set_wave_number(n: int) -> void:
	wave_number = maxi(n, 1)
	_clear_remaining_enemies()
	spawner.begin_wave(wave_number)
	hud.update_wave(wave_number)

## 调试：设置每波持续时间（秒）。
func set_wave_duration(seconds: float) -> void:
	wave_duration = maxf(seconds, 1.0)

## 调试：无限获取道具（跳过金币/唯一/每波限制），直接累加并应用玩家侧效果。
func debug_give_item(item_id: String) -> void:
	player.buy_item(item_id)
	if item_id == "ring":
		spawner.set_spawn_rate_mult(2.0)
	debug_panel.refresh()

## 调试：移除道具（减计数并撤销玩家侧效果）。
func debug_remove_item(item_id: String) -> void:
	var before: int = player.item_counts.get(item_id, 0)
	player.remove_item(item_id)
	if item_id == "ring" and before == 1:
		spawner.set_spawn_rate_mult(1.0)
	debug_panel.refresh()

## 调试：把某道具数量直接设为 count。按差额逐次增减，保证玩家侧效果与计数一致。
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

## 调试：切换当前攻击方式（测试用，纯切换不影响暂停态/点数）。
func debug_set_attack(attack_id: String) -> void:
	player.attack_id = attack_id
	player.weapon_levels[attack_id] = 1
	talent_tree.attack_id = attack_id
	weapon_manager.set_active_attack(attack_id)

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
	if not attack_choice_done:
		# 首次升级：主动弹出攻击方式选择面板（暂停）。
		if auto_pause_menus:
			get_tree().paused = true
		attack_select_panel.visible = true
	else:
		# 之后升级：只发 1 点天赋 + 屏幕下方一行文字提示（不弹窗）。
		talent_tree.points += 1
		hud.show_talent_hint("获得 1 天赋点，按 T 打开天赋树")

## 统一结束本局并显示结算界面。reason 用于标题区分（游戏结束 / 本局结束）。
func end_game(reason: String) -> void:
	game_state = GameState.GAMEOVER
	spawner.end_wave()
	get_tree().paused = false
	var wm := player.get_node_or_null("WeaponManager")
	if wm != null:
		wm.call("halt")
	hud.show_result(reason, difficulty_name(difficulty_id), kills, wave_number,
		player.level, player.gold, elapsed)

## 暂停菜单「结束该局」：先关暂停面板、解除暂停，再走统一结算。
func end_game_from_pause() -> void:
	pause_panel.visible = false
	get_tree().paused = false
	end_game("本局结束")

func _on_player_died() -> void:
	end_game("游戏结束")

func _on_enemy_killed(global_pos: Vector2, xp_value: int, gold_value: int) -> void:
	kills += 1
	hud.update_kills(kills)
	spawn_xp_gem(global_pos, xp_value)
	spawn_coin(global_pos, gold_value)
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
