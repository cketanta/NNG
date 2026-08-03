extends SceneTree
## 黑洞枪天赋测试：伤害/攻速、黑洞半径（引力场）、强吸、坍缩、持久、强吸与坍缩互斥。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _bhg: Node2D
var _tree

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main
	_player = _main.get_node("Player")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("pistol")
		_main.debug_give_weapon("black_hole_gun")
		var slots: Array = _player.get("weapon_slots")
		var idx := _find_idx(slots, "black_hole_gun")
		_tree = slots[idx].tree
		_tree.points = 100
		var wm: Node = _main.get_node("Player/WeaponManager")
		for child in wm.get_children():
			if child.get("weapon_id") == "black_hole_gun":
				_bhg = child
		_bhg.set_talent_tree(_tree)
		_bhg.call("_apply_talents")
	elif _frames == 2:
		_check_base()
		_grant("bhg_radius_1")
		_grant("bhg_radius_2")
		_grant("bhg_radius_3")
		_grant("bhg_power_1")
		_bhg.call("_apply_talents")
		_check_radius()
		_grant("bhg_pull")
		_bhg.call("_apply_talents")
		_check_pull()
		_check_collapse_conflict()
		_grant("bhg_duration")
		_bhg.call("_apply_talents")
		_check_duration()
		_check_fire()
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	_tree.points += 1
	if not _tree.unlock("black_hole_gun", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _bhg.get("damage") == 1 and absf(_bhg.get("cooldown") - 2.2) < 0.001 \
			and absf(_bhg.get("_bh_radius") - 130.0) < 0.001:
		print("[OK] bhg base (dmg=1 cd=2.2 radius=130)")
	else:
		_failures.append("bhg base wrong (dmg=%d cd=%.2f radius=%.1f)" % [_bhg.get("damage"), _bhg.get("cooldown"), _bhg.get("_bh_radius")])

func _check_radius() -> void:
	# 引力场 3 点：130 × 1.2^3 ≈ 224.64。
	if absf(_bhg.get("_bh_radius") - 224.64) < 0.01:
		print("[OK] 3x bhg_radius -> radius 224.64")
	else:
		_failures.append("radius=%.2f" % _bhg.get("_bh_radius"))

func _check_pull() -> void:
	if _bhg.get("_pull_strong") == true:
		print("[OK] bhg_pull -> strong pull")
	else:
		_failures.append("pull_strong not enabled")

func _check_collapse_conflict() -> void:
	if _tree.unlock("black_hole_gun", "bhg_collapse"):
		_failures.append("bhg_collapse unlocked despite pull conflict")
	else:
		print("[OK] bhg_collapse conflicts with bhg_pull")
	_tree.owned["black_hole_gun"]["bhg_collapse"] = true
	_bhg.call("_apply_talents")
	if _bhg.get("_collapse") == true:
		print("[OK] bhg_collapse -> collapse enabled")
	else:
		_failures.append("collapse not enabled")

func _check_duration() -> void:
	if _bhg.get("_duration") == true:
		print("[OK] bhg_duration -> duration enabled")
	else:
		_failures.append("duration not enabled")

func _check_fire() -> void:
	var before := get_nodes_in_group("friendly_projectiles").size()
	_bhg.call("fire")
	var after := get_nodes_in_group("friendly_projectiles").size()
	if after - before == 1:
		print("[OK] fire launches 1 projectile")
	else:
		_failures.append("projectiles launched=%d" % (after - before))

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] bhg test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
