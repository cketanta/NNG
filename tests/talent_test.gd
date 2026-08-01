extends SceneTree
## 天赋测试（v1.1.0 停用后）：升级不再发天赋点、不自动弹天赋窗、不暂停。

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
		_main.start_with_weapon("whip")
		_player.gain_xp(5)  # 触发升级（level 1 -> 2）
	elif _frames == 5:
		var tree = _main.get("talent_tree")
		if tree.points == 0:
			print("[OK] no talent points granted on level up")
		else:
			_failures.append("talent points=%d" % tree.points)
		if not _main.get_node("HUD/TalentPanel").visible:
			print("[OK] talent panel not auto-opened")
		else:
			_failures.append("talent panel auto-opened")
		if not paused:
			print("[OK] game not paused on level up")
		else:
			_failures.append("game paused on level up")
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] talent test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
