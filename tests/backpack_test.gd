extends SceneTree
## 背包测试（v1.1.0）：打开暂停；显示人物属性/已拥有武器/道具（×数量）；
## 不含天赋树；关闭恢复。

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
		_main.buy_item("shoes")  # 买一个道具用于显示
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
		if backpack._gold_label.text == "金币: 44":
			print("[OK] backpack shows gold after purchase")
		else:
			_failures.append("gold label '%s'" % backpack._gold_label.text)
		if "移速" in backpack._stats_label.text and "防御" in backpack._stats_label.text:
			print("[OK] backpack shows player stats")
		else:
			_failures.append("stats label '%s'" % backpack._stats_label.text)
		var whip_row: Dictionary = backpack._weapon_rows["whip"]
		if "Lv.1" in whip_row["name"].text and "段连斩" in whip_row["effect"].text:
			print("[OK] backpack lists owned weapons")
		else:
			_failures.append("weapons row '%s / %s'" % [whip_row["name"].text, whip_row["effect"].text])
		var items_text := _gather_text(backpack._items_box)
		if "跑鞋" in items_text and "×1" in items_text:
			print("[OK] backpack lists item with count")
		else:
			_failures.append("items text '%s'" % items_text)
		if backpack.get("_tree_ui") == null:
			print("[OK] no talent tree in backpack")
		else:
			_failures.append("talent tree still in backpack")
		_main.close_backpack()
	elif _frames == 10:
		if not paused and not _main.get_node("HUD/BackpackPanel").visible:
			print("[OK] close_backpack resumes the game")
		else:
			_failures.append("game still paused / panel visible after close")
		_finish()
		return true
	return false

## 递归收集某容器内所有 Label 文本，用于断言卡片化的道具区内容。
func _gather_text(node: Node) -> String:
	var out := ""
	if node is Label:
		out += node.text + "\n"
	for child in node.get_children():
		out += _gather_text(child)
	return out

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] backpack test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
