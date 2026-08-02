extends SceneTree
## 左轮天赋测试：弹头/弹匣/快枪手 终值、追踪开关、转盘天赋启用、连射弹数。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _revolver: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main
	_player = _main.get_node("Player")
	_revolver = _main.get_node("Player/WeaponManager/Revolver")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("pistol")
		_main.debug_set_attack("revolver")
		_revolver.call("_apply_talents")
		_check_base()
		_grant("rev_bullet_1")
		_grant("rev_mag_1")
		_grant("rev_quick_1")
		_revolver.call("_apply_talents")
		_check_buffs()
		_grant("rev_homing_1")
		_revolver.call("_apply_talents")
		if absf(_revolver.get("_homing_deg") - 0.5) < 0.001:
			print("[OK] homing_1 = weak tracking (0.5)")
		else:
			_failures.append("homing_1 deg=%f" % _revolver.get("_homing_deg"))
		_grant("rev_spinner")
		_revolver.call("_apply_talents")
		if _revolver.get("_has_spinner") == true:
			print("[OK] spinner talent enabled")
		else:
			_failures.append("spinner not enabled")
		# 连射：弹匣 1 → 每次开火 2 发。
		var before := get_nodes_in_group("friendly_projectiles").size()
		_revolver.set_aim_direction(Vector2.RIGHT)
		_revolver.call("fire")
		var bullets := get_nodes_in_group("friendly_projectiles").size() - before
		if bullets == 2:
			print("[OK] revolver fires 2 bullets with mag_1")
		else:
			_failures.append("revolver bullets=%d" % bullets)
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	var tree = _main.get("talent_tree")
	tree.points += 1
	if not tree.unlock("revolver", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _revolver.get("damage") == 4 and absf(_revolver.get("cooldown") - 0.9) < 0.001 and _revolver.get("_bullet_count") == 1:
		print("[OK] revolver base (dmg=4 cd=0.9 bullets=1)")
	else:
		_failures.append("revolver base wrong (dmg=%d cd=%.2f bullets=%d)" % [_revolver.get("damage"), _revolver.get("cooldown"), _revolver.get("_bullet_count")])

func _check_buffs() -> void:
	# 弹匣1 +1弹、弹头1 +10%（取整仍 4）、快枪手1 cd×0.9。
	if _revolver.get("_bullet_count") == 2:
		print("[OK] mag_1 -> 2 bullets")
	else:
		_failures.append("bullets=%d" % _revolver.get("_bullet_count"))
	if _revolver.get("damage") == 4:
		print("[OK] bullet_1 keeps dmg=4 (rounded)")
	else:
		_failures.append("damage=%d" % _revolver.get("damage"))
	if absf(_revolver.get("cooldown") - 0.81) < 0.001:
		print("[OK] quick_1 -> cd 0.81")
	else:
		_failures.append("cooldown=%.3f" % _revolver.get("cooldown"))

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] revolver test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
