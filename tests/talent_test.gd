extends SceneTree
## 天赋测试：首次升级弹出攻击方式选择（暂停）；选择后发点并切攻击方式；
## 之后升级只发点 + 一行提示不弹窗；T 键开天赋面板；三选一抽 3 个；前置 / 冲突生效。

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
		_player.gain_xp(5)  # level 1 -> 2：首次升级，弹攻击方式选择
	elif _frames == 4:
		if _main.get_node("HUD/AttackSelectPanel").visible and paused:
			print("[OK] first level up opens attack select panel (paused)")
		else:
			_failures.append("attack select not shown (visible=%s paused=%s)" % [_main.get_node("HUD/AttackSelectPanel").visible, paused])
		if _main.get("attack_choice_done") == false:
			print("[OK] attack choice pending")
		else:
			_failures.append("attack_choice_done=%s" % _main.get("attack_choice_done"))
		_main.choose_attack("blade")
	elif _frames == 6:
		if _main.get("attack_choice_done") == true:
			print("[OK] attack chosen (blade)")
		else:
			_failures.append("attack_choice_done not set")
		if _main.get_node("Player/WeaponManager").get("active_attack_id") == "blade":
			print("[OK] active attack switched to blade")
		else:
			_failures.append("active attack not blade")
		var points: int = _main.get("talent_tree").points
		if points == 1:
			print("[OK] 1 talent point granted on choosing attack")
		else:
			_failures.append("points=%d" % points)
		if not paused:
			print("[OK] attack select unpauses the game")
		else:
			_failures.append("game still paused after choosing")
		_player.gain_xp(100)  # 再升多级：之后只发点 + 提示，不重开选择面板
	elif _frames == 8:
		if not _main.get_node("HUD/AttackSelectPanel").visible:
			print("[OK] later level ups do not reopen attack select")
		else:
			_failures.append("attack select reopened on later level up")
		if _main.get("talent_tree").points >= 2:
			print("[OK] later level ups grant talent points (%d)" % _main.get("talent_tree").points)
		else:
			_failures.append("points=%d" % _main.get("talent_tree").points)
		_main.open_talent()
	elif _frames == 10:
		if _main.get_node("HUD/TalentPanel").visible and paused:
			print("[OK] T opens talent panel (paused)")
		else:
			_failures.append("talent panel not open (visible=%s paused=%s)" % [_main.get_node("HUD/TalentPanel").visible, paused])
		var tree = _main.get("talent_tree")
		var choices: Array = tree.draw_choices("blade", 3)
		if choices.size() == 3:
			print("[OK] draw_choices returns 3")
		else:
			_failures.append("choices=%d" % choices.size())
		tree.points = 10
		# 前置：未点 range_1 时 range_2 不可选；点 range_1 后 range_2 可选。
		if not tree.selectable("blade").has("blade_range_2"):
			print("[OK] blade_range_2 locked until range_1 owned")
		else:
			_failures.append("blade_range_2 selectable without prereq")
		if tree.unlock("blade", "blade_range_1"):
			if tree.selectable("blade").has("blade_range_2"):
				print("[OK] blade_range_2 unlocked after range_1")
			else:
				_failures.append("blade_range_2 still locked after range_1")
		else:
			_failures.append("range_1 unlock failed")
		# 冲突：点气刃斩后狂战不可选；气刃专精 1 可选。
		if tree.unlock("blade", "blade_air_blade"):
			if not tree.selectable("blade").has("blade_berserk"):
				print("[OK] berserk conflicts with air blade")
			else:
				_failures.append("berserk selectable with air blade")
			if tree.selectable("blade").has("blade_air_1"):
				print("[OK] air mastery 1 selectable after air blade")
			else:
				_failures.append("air_1 not selectable after air blade")
		else:
			_failures.append("could not unlock air blade")
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
