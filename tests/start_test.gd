extends SceneTree
## 开局测试：游戏开始先暂停显示难度面板；选难度后出现选武面板；
## 选武器后开战，未选中的武器保持 0 级。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_player = _main.get_node("Player")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		if paused and _main.get_node("HUD/DifficultyPanel").visible:
			print("[OK] run starts paused with the difficulty panel")
		else:
			_failures.append("difficulty panel not shown (paused=%s panel=%s)" % [paused, _main.get_node("HUD/DifficultyPanel").visible])
		if _main.get("game_state") == 0:
			print("[OK] game_state = START")
		else:
			_failures.append("game_state=%d" % _main.get("game_state"))
		var levels: Dictionary = _player.get("weapon_levels")
		if levels["whip"] == 0 and levels["staff"] == 0:
			print("[OK] all weapons start at level 0")
		else:
			_failures.append("weapons not all 0: %s" % levels)
		_main.choose_difficulty("normal")
	elif _frames == 3:
		if _main.get_node("HUD/StartPanel").visible and not _main.get_node("HUD/DifficultyPanel").visible:
			print("[OK] difficulty chosen, weapon panel shown")
		else:
			_failures.append("weapon panel not shown after difficulty")
		if _main.get("difficulty_id") == "normal":
			print("[OK] difficulty = normal")
		else:
			_failures.append("difficulty_id=%s" % _main.get("difficulty_id"))
		# 选武面板按 Esc 返回难度面板。
		_main.back_to_difficulty()
	elif _frames == 4:
		if _main.get_node("HUD/DifficultyPanel").visible and not _main.get_node("HUD/StartPanel").visible:
			print("[OK] Esc from weapon panel returns to difficulty")
		else:
			_failures.append("back to difficulty failed")
		_main.choose_difficulty("normal")
		_main.start_with_weapon("whip")
	elif _frames == 6:
		if not paused and _main.get("game_state") == 1 and _main.get("wave_number") == 1:
			print("[OK] start_with_weapon begins combat (wave 1, unpaused)")
		else:
			_failures.append("combat not started (paused=%s state=%d wave=%d)" % [paused, _main.get("game_state"), _main.get("wave_number")])
		var levels: Dictionary = _player.get("weapon_levels")
		if levels["whip"] == 1 and levels["staff"] == 0:
			print("[OK] whip=1 staff=0")
		else:
			_failures.append("weapon levels wrong: %s" % levels)
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] start test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
