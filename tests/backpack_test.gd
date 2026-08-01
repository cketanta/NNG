extends SceneTree
## 背包测试：打开背包 -> 暂停；显示金币/道具；背包内可花费攒下的天赋点；关闭 -> 恢复。

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
		_player.gain_gold(50)
		var tree = _main.get("talent_tree")
		tree.points = 1  # simulate one banked talent point
		_main.open_backpack()
	elif _frames == 5:
		if paused:
			print("[OK] backpack pauses the game")
		else:
			_failures.append("backpack did not pause")
		var panel: Control = _main.get_node("HUD/BackpackPanel")
		if not panel.visible:
			_failures.append("backpack panel not visible")
			_finish()
			return true
		var backpack := panel as BackpackPanel
		if backpack._gold_label.text == "金币: 50":
			print("[OK] backpack shows gold")
		else:
			_failures.append("gold label '%s'" % backpack._gold_label.text)
		if "Lv.1" in backpack._items_label.text and "段连斩" in backpack._items_label.text:
			print("[OK] backpack lists weapons with their effects")
		else:
			_failures.append("items label '%s'" % backpack._items_label.text)
		# 在背包内花费攒下的天赋点。
		backpack._on_buy("attack_speed")
	elif _frames == 10:
		var mult: float = _player.get("attack_speed_mult")
		if absf(mult - 1.08) < 0.001:
			print("[OK] spent banked point from backpack, attack_speed_mult=1.08")
		else:
			_failures.append("attack_speed_mult=%f" % mult)
		_main.close_backpack()
	elif _frames == 15:
		if not paused and not _main.get_node("HUD/BackpackPanel").visible:
			print("[OK] close_backpack resumes the game")
		else:
			_failures.append("game still paused / panel still visible after close")
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] backpack test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
