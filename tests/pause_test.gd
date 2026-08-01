extends SceneTree
## 暂停/返回测试（真实分发顺序）：
## 1) 背包等界面打开时按 Esc -> 返回上一级（关面板回到游戏），不弹暂停菜单。
## 2) 暂停菜单打开时按 Esc -> 回到游戏。
## 注意：真实输入分发是「深度优先逆序」——面板先于 main 收到同一事件；
## 面板 set_input_as_handled 后 main 不再收到。旧测试先调 main 掩盖了双开 bug，这里改为面板优先。

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
	elif _frames == 2:
		_main.open_backpack()
	elif _frames == 3:
		if not _main.get_node("HUD/BackpackPanel").visible:
			_failures.append("backpack not open")
		_send_esc()
	elif _frames == 5:
		if _main.get_node("HUD/BackpackPanel").visible:
			_failures.append("backpack still open after Esc")
		if _main.get_node("HUD/PausePanel").visible:
			_failures.append("Esc from backpack opened pause menu!")
		if not paused:
			print("[OK] Esc in backpack closes it and returns to game (no pause)")
		else:
			_failures.append("game paused after Esc in backpack")
		_main.open_pause()
	elif _frames == 6:
		if not _main.get_node("HUD/PausePanel").visible:
			_failures.append("pause not open")
		_send_esc()
	elif _frames == 8:
		if _main.get_node("HUD/PausePanel").visible:
			_failures.append("pause still open after Esc")
		if not paused:
			print("[OK] Esc in pause menu returns to game")
		else:
			_failures.append("game still paused after Esc in pause")
		_finish()
		return true
	return false

## 模拟按 Esc，按真实分发顺序：可见面板先收到；面板 handled 后 main 不再收到同一事件。
func _send_esc() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	for panel in ["PausePanel", "BackpackPanel", "ShopPanel"]:
		var node: Node = _main.get_node_or_null("HUD/" + panel)
		if node != null and node.visible:
			node._unhandled_input(ev)
			if root.is_input_handled():
				return
	_main._unhandled_input(ev)

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] pause test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
