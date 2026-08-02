extends SceneTree
## 天赋测试：升级发人物天赋点 + 4 分支加点；武器天赋按武器等级点数（三选一 + 前置/冲突）；测试模式点击点亮/取消。

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
		_player.gain_xp(5)  # level 1 -> 2：人物天赋点 +1
	elif _frames == 3:
		var pt = _player.get("player_talent")
		if pt.points == 1:
			print("[OK] level up grants 1 personal talent point")
		else:
			_failures.append("personal talent points=%d" % pt.points)
		# 人物天赋加点：疾跑 +1 层，消耗 1 点。
		if _main.unlock_personal_talent("move_speed"):
			if pt.owned_count("move_speed") == 1 and pt.points == 0:
				print("[OK] personal talent unlocked (move_speed x1)")
			else:
				_failures.append("personal unlock wrong (owned=%d pts=%d)" % [pt.owned_count("move_speed"), pt.points])
		else:
			_failures.append("personal unlock failed")
		# 给玩家一把短刃（Lv.1 = 1 点武器天赋）。
		_main.debug_give_weapon("blade")
		var slots: Array = _player.get("weapon_slots")
		var blade_idx := _find_idx(slots, "blade")
		var tree = slots[blade_idx].tree
		if tree.points == 1:
			print("[OK] blade Lv.1 = 1 weapon talent point")
		else:
			_failures.append("blade tree points=%d" % tree.points)
		# 武器天赋三选一。
		var choices: Array = tree.draw_choices("blade", 3)
		if choices.size() == 3:
			print("[OK] weapon draw_choices returns 3")
		else:
			_failures.append("choices=%d" % choices.size())
		# 前置：未点 range_1 时 range_2 不可选。
		if not tree.selectable("blade").has("blade_range_2"):
			print("[OK] range_2 locked until range_1 owned")
		else:
			_failures.append("range_2 selectable without prereq")
		# 解锁武器天赋 range_1（消耗武器天赋点）。
		if _main.unlock_weapon_talent(blade_idx, "blade_range_1"):
			if tree.is_owned("blade", "blade_range_1") and tree.points == 0:
				print("[OK] weapon talent unlocked (range_1)")
			else:
				_failures.append("weapon unlock wrong (owned=%s pts=%d)" % [tree.is_owned("blade", "blade_range_1"), tree.points])
		else:
			_failures.append("weapon talent unlock failed")
		# 测试模式：点击树节点免费点亮 / 再点取消。
		_main.set("test_mode", true)
		var panel: Node = _main.get_node("HUD/TalentPanel")
		panel.set("_selected_slot", blade_idx)
		panel.call("_on_node_clicked", "blade_range_2")
		if tree.is_owned("blade", "blade_range_2"):
			print("[OK] test mode click lights up node")
		else:
			_failures.append("test click did not light up")
		panel.call("_on_node_clicked", "blade_range_2")
		if not tree.is_owned("blade", "blade_range_2"):
			print("[OK] test mode second click cancels node")
		else:
			_failures.append("test click did not cancel")
		_finish()
		return true
	return false

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] talent test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
