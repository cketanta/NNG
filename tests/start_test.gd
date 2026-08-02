extends SceneTree
## 开局测试：游戏开始先暂停显示难度面板；选难度后直接开战；
## 初始武器槽位含破旧手枪 Lv.1；WeaponManager 按槽位实例化武器节点。

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
			_failures.append("difficulty panel not shown (paused=%s)" % paused)
		if _main.get("game_state") == 0:
			print("[OK] game_state = START")
		else:
			_failures.append("game_state=%d" % _main.get("game_state"))
		var slots: Array = _player.get("weapon_slots")
		if slots.size() == 1 and slots[0].id == "pistol" and slots[0].level == 1:
			print("[OK] initial slot = pistol Lv.1")
		else:
			_failures.append("initial slots wrong: %s" % slots)
		_main.choose_difficulty("normal")
	elif _frames == 3:
		if _main.get("difficulty_id") == "normal":
			print("[OK] difficulty = normal")
		else:
			_failures.append("difficulty_id=%s" % _main.get("difficulty_id"))
		if not paused and _main.get("game_state") == 1 and _main.get("wave_number") == 1:
			print("[OK] combat starts directly after difficulty")
		else:
			_failures.append("combat not started (paused=%s state=%d wave=%d)" % [paused, _main.get("game_state"), _main.get("wave_number")])
		if _player.visible:
			print("[OK] player visible after combat starts")
		else:
			_failures.append("player hidden after combat starts")
		var wm: Node = _main.get_node("Player/WeaponManager")
		if wm.get_child_count() == 1:
			print("[OK] weapon manager spawned 1 weapon node")
		else:
			_failures.append("weapon nodes=%d" % wm.get_child_count())
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
