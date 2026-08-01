extends SceneTree
## 无头冒烟测试：加载 main.tscn，模拟约 16 秒战斗，验证核心循环：
## 输入动作、波次刷怪、武器击杀、掉经验宝石+金币、经验/金币累积。
## 关闭菜单自动暂停，让战斗持续进行。

const GEM_SCRIPT := preload("res://scripts/items/xp_gem.gd")
const COIN_SCRIPT := preload("res://scripts/items/coin.gd")

const REQUIRED_ACTIONS := ["move_left", "move_right", "move_up", "move_down", "toggle_attack_mode", "toggle_backpack"]
# 无头模式每帧约 0.007s，这些帧数对应约 16 秒模拟时间。
const FRAMES_TO_RUN := 2400

var _frames := 0
var _sim_time := 0.0
var _failures: Array[String] = []

func _initialize() -> void:
	seed(1234)  # deterministic spawn positions

	var missing := []
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			missing.append(action)
	if missing.is_empty():
		print("[OK] input actions registered")
	else:
		_failures.append("missing input actions: %s" % missing)

	var scene := load("res://scenes/main.tscn")
	if scene == null:
		_failures.append("cannot load res://scenes/main.tscn")
		_finish()
		return
	var main: Node = scene.instantiate()
	main.auto_pause_menus = false  # keep combat running across level-up/menu events
	root.add_child(main)
	current_scene = main

func _process(delta: float) -> bool:
	_frames += 1
	_sim_time += delta
	if _frames == 1:
		current_scene.call("start_with_weapon", "staff")  # begin combat with the ranged weapon
	if _frames >= FRAMES_TO_RUN:
		_check()
		_finish()
		return true
	return false

func _check() -> void:
	var main: Node = current_scene
	if main == null:
		_failures.append("current_scene is null")
		return

	var player: Node2D = main.get_node("Player")
	var kills: int = main.get("kills")
	var wave: int = main.get("wave_number")

	var gems := 0
	var coins := 0
	for child in main.get_children():
		var script_ref = child.get_script()
		if script_ref == GEM_SCRIPT:
			gems += 1
		elif script_ref == COIN_SCRIPT:
			coins += 1

	if wave < 1:
		_failures.append("wave never started")
	if kills < 2:
		_failures.append("too few enemies killed (%d, expected >= 2)" % kills)
	if gems == 0 and coins == 0:
		_failures.append("no drops after kills")
	if not is_instance_valid(player):
		_failures.append("player node missing")
	else:
		print("[OK] player alive, hp=%d/%d level=%d" % [player.hp, player.max_hp, player.get("level")])

	# 拾取收集（金币/经验）由 gem_test 确定性覆盖；静止玩家只会拾到落在磁吸范围内的掉落。
	print("[STATE] sim=%.1fs wave=%d kills=%d gold=%d xp=%d gems=%d coins=%d" % \
			[_sim_time, wave, kills, player.get("gold"), player.get("xp"), gems, coins])

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] smoke test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
