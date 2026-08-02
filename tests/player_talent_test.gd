extends SceneTree
## 人物天赋测试：4 分支线性加点、效果倍率（移速）、分支点满后不可再点。

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
		_main.start_with_weapon("pistol")
		var pt = _player.get("player_talent")
		pt.points = 10
		# 疾跑 2 级 → 移速倍率 1.2。
		if _main.unlock_personal_talent("move_speed") and _main.unlock_personal_talent("move_speed"):
			print("[OK] move_speed x2 unlocked")
		else:
			_failures.append("move_speed unlock failed")
		if absf(_player.get("move_speed_mult") - 1.2) < 0.001:
			print("[OK] move_speed_mult = 1.2")
		else:
			_failures.append("move_speed_mult=%f" % _player.get("move_speed_mult"))
		# 分支可点满 5 级，满后不可再点。
		for i in range(5):
			if not _main.unlock_personal_talent("damage"):
				_failures.append("damage unlock %d failed" % i)
		if pt.owned_count("damage") == 5:
			print("[OK] damage branch maxed (5/5)")
		else:
			_failures.append("damage owned=%d" % pt.owned_count("damage"))
		if not _main.unlock_personal_talent("damage"):
			print("[OK] maxed branch cannot unlock further")
		else:
			_failures.append("maxed branch unlocked again")
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] player talent test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
