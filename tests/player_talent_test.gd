extends SceneTree
## 人物天赋测试（树状）：加点/前置/互斥、效果聚合（伤害倍率/移速/生命上限）。

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
		var pt = _player.get("player_talent")
		pt.points = 20
		# 前置锁：未点 person_range 时 person_range_2 不可选。
		if not pt.tree.selectable("player").has("person_range_2"):
			print("[OK] range_2 locked until range_1 owned")
		else:
			_failures.append("person_range_2 selectable without prereq")
		# 疾跑 + 蛮力：移速倍率 1.1、伤害倍率 1.1。
		if not _main.unlock_personal_talent("person_sprint"):
			_failures.append("sprint unlock failed")
		if not _main.unlock_personal_talent("person_brute"):
			_failures.append("brute unlock failed")
		if absf(_player.get("move_speed_mult") - 1.1) < 0.001:
			print("[OK] sprint -> move_speed_mult = 1.1")
		else:
			_failures.append("move_speed_mult=%f" % _player.get("move_speed_mult"))
		var fx: Dictionary = pt.effects()
		if absf(fx.dmg_mult - 1.1) < 0.001:
			print("[OK] brute -> dmg_mult = 1.1")
		else:
			_failures.append("dmg_mult=%f" % fx.dmg_mult)
		# 力量链加满：1.1 × 1.1 × 1.15 = 1.3915。
		if not _main.unlock_personal_talent("person_brute_2"):
			_failures.append("brute_2 unlock failed")
		if not _main.unlock_personal_talent("person_brute_3"):
			_failures.append("brute_3 unlock failed")
		fx = pt.effects()
		if absf(fx.dmg_mult - 1.3915) < 0.001:
			print("[OK] power chain -> dmg_mult = 1.3915")
		else:
			_failures.append("power chain dmg_mult=%f" % fx.dmg_mult)
		# 坚韧：生命上限 +20 -> max_hp 120。
		if not _main.unlock_personal_talent("person_vitality"):
			_failures.append("vitality unlock failed")
		if _player.get("max_hp") == 120:
			print("[OK] vitality -> max_hp = 120")
		else:
			_failures.append("max_hp=%d" % _player.get("max_hp"))
		# 互斥：点满攻速链后连珠可选；随后点锐眼（与连珠互斥）应失败。
		if not _main.unlock_personal_talent("person_haste"):
			_failures.append("haste unlock failed")
		if not _main.unlock_personal_talent("person_haste_2"):
			_failures.append("haste_2 unlock failed")
		if not _main.unlock_personal_talent("person_extra"):
			_failures.append("extra (连珠) unlock failed")
		if _main.unlock_personal_talent("person_crit"):
			_failures.append("crit unlocked despite conflict with extra")
		else:
			print("[OK] crit conflicts with extra (连珠/暴击流二选一)")
		# 人物树点数扣减正确：sprint/brute/brute_2/brute_3/vitality/haste/haste_2/extra 共解锁 8 次 → 剩 12。
		if pt.points == 12:
			print("[OK] points deducted correctly (%d)" % pt.points)
		else:
			_failures.append("points=%d" % pt.points)
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] player talent test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
