extends SceneTree
## 背包测试：打开暂停；显示金币 / 玩家属性 / 武器（名称等级，无天赋） / 道具；关闭恢复。

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
		_player.gain_gold(50)
		_main.buy_item("shoes")
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
		# 武器区：显示名称与等级，不含天赋。
		var weapons_text := _gather_text(backpack._weapons_box)
		if "破旧手枪" in weapons_text and "Lv.1" in weapons_text:
			print("[OK] backpack lists weapon with level")
		else:
			_failures.append("weapons text '%s'" % weapons_text)
		if not "天赋" in weapons_text:
			print("[OK] backpack weapon area has no talent")
		else:
			_failures.append("backpack shows weapon talent")
		# 道具区：显示已购道具 ×数量。
		var items_text := _gather_text(backpack._items_box)
		if "跑鞋" in items_text and "×1" in items_text:
			print("[OK] backpack lists item with count")
		else:
			_failures.append("items text '%s'" % items_text)
		_main.close_backpack()
	elif _frames == 10:
		if not paused and not _main.get_node("HUD/BackpackPanel").visible:
			print("[OK] close_backpack resumes the game")
		else:
			_failures.append("game still paused / panel visible after close")
		_finish()
		return true
	return false

## 递归收集某容器内所有 Label 文本。
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
