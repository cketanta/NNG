extends SceneTree
## 开局测试：游戏开始先暂停显示难度面板；选难度后直接开战（初始攻击方式破旧手枪）。

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
		if levels.get("pistol") == 1 and levels.get("blade") == 0 and levels.get("revolver") == 0:
			print("[OK] initial attack = pistol (level 1), others 0")
		else:
			_failures.append("initial weapon_levels wrong: %s" % levels)
		_main.choose_difficulty("normal")
	elif _frames == 3:
		if _main.get("difficulty_id") == "normal":
			print("[OK] difficulty = normal")
		else:
			_failures.append("difficulty_id=%s" % _main.get("difficulty_id"))
		if not paused and _main.get("game_state") == 1 and _main.get("wave_number") == 1:
			print("[OK] combat starts directly after difficulty (no weapon panel)")
		else:
			_failures.append("combat not started (paused=%s state=%d wave=%d)" % [paused, _main.get("game_state"), _main.get("wave_number")])
		if _player.visible:
			print("[OK] player visible after combat starts")
		else:
			_failures.append("player hidden after combat starts")
		var active_id: String = _main.get_node("Player/WeaponManager").get("active_attack_id")
		if active_id == "pistol":
			print("[OK] active attack = pistol")
		else:
			_failures.append("active_attack_id=%s" % active_id)
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
