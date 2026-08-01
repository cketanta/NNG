extends SceneTree
## 拾取测试：确定性验证经验宝石 -> 经验、金币 -> 金币 的链路，
## 把拾取物放在静止玩家固定距离处。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main
	_player = _main.get_node("Player")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("whip")
		# 走 Main 的真实生成路径，一并验证拾取接线。
		_main.spawn_xp_gem(_player.global_position + Vector2(80, 0), 2)
		_main.spawn_coin(_player.global_position + Vector2(-80, 0), 2)
	elif _frames == 150:
		var xp: int = _player.get("xp")
		var gold: int = _player.get("gold")
		if xp == 2:
			print("[OK] xp gem collected, xp=%d" % xp)
		else:
			_failures.append("xp gem not collected (xp=%d)" % xp)
		if gold == 2:
			print("[OK] coin collected, gold=%d" % gold)
		else:
			_failures.append("coin not collected (gold=%d)" % gold)
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] pickup test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
