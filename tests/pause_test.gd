extends SceneTree
## 暂停菜单测试：战斗中打开 Esc 暂停菜单（游戏暂停），再关闭并恢复。

var _frames := 0
var _failures: Array[String] = []
var _main: Node

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("whip")
	elif _frames == 3:
		_main.open_pause()
	elif _frames == 5:
		if paused and _main.get_node("HUD/PausePanel").visible:
			print("[OK] pause menu opens with pause")
		else:
			_failures.append("pause menu not open (paused=%s panel=%s)" % [paused, _main.get_node("HUD/PausePanel").visible])
		_main.close_pause()
	elif _frames == 7:
		if not paused and not _main.get_node("HUD/PausePanel").visible:
			print("[OK] close_pause resumes the game")
		else:
			_failures.append("game still paused after close")
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] pause test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
