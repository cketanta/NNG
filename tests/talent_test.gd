extends SceneTree
## 天赋测试：升级 -> 弹天赋窗 + 游戏暂停；花费点数 -> 属性倍率生效；关闭 -> 恢复。

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
		_player.gain_xp(5)  # exactly one level-up (xp_max is 5 at level 1)
	elif _frames == 5:
		if paused:
			print("[OK] talent window pauses the game")
		else:
			_failures.append("talent window did not pause")
		if _main.get_node("HUD/TalentPanel").visible:
			print("[OK] talent panel visible")
		else:
			_failures.append("talent panel not visible")
		var tree = _main.get("talent_tree")
		if tree.points == 1:
			print("[OK] gained 1 talent point")
		else:
			_failures.append("talent points=%d" % tree.points)
		_main._on_talent_purchased("move_speed")
		tree.points += 1  # grant another point to test the damage branch too
		_main._on_talent_purchased("damage")
	elif _frames == 10:
		var tree = _main.get("talent_tree")
		if tree.owned_count("move_speed") == 1 and tree.owned_count("damage") == 1 and tree.points == 0:
			print("[OK] move_speed + damage unlocked, points consumed")
		else:
			_failures.append("unlock state wrong (move=%d dmg=%d points=%d)" % [tree.owned_count("move_speed"), tree.owned_count("damage"), tree.points])
		var move_mult: float = _player.get("move_speed_mult")
		if absf(move_mult - 1.1) < 0.001:
			print("[OK] move_speed_mult = 1.1")
		else:
			_failures.append("move_speed_mult=%f" % move_mult)
		var dmg_mult: float = _player.get("damage_mult")
		if absf(dmg_mult - 1.1) < 0.001:
			print("[OK] damage_mult = 1.1")
		else:
			_failures.append("damage_mult=%f" % dmg_mult)
		_main.close_talent()
	elif _frames == 15:
		if not paused and not _main.get_node("HUD/TalentPanel").visible:
			print("[OK] close_talent resumes the game")
		else:
			_failures.append("game still paused / panel still visible after close")
		# 点满整棵天赋树后再次升级 -> 不再弹天赋窗。
		var tree = _main.get("talent_tree")
		tree.points = 18  # 20 tiers total; move_speed + damage already at 1 each
		for branch_id in ["move_speed", "attack_speed", "attack_range", "damage"]:
			for i in range(5):
				tree.unlock(branch_id)
		_player.gain_xp(10)  # level 2->3 (xp_max = 10 at level 2), triggers level_up
	elif _frames == 20:
		if not _main.get_node("HUD/TalentPanel").visible and not paused:
			print("[OK] no talent popup after maxing the tree")
		else:
			_failures.append("talent panel still pops after maxing (visible=%s paused=%s)" % [_main.get_node("HUD/TalentPanel").visible, paused])
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
