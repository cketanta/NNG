extends SceneTree
## 回旋镖天赋测试：伤害/攻速、贯穿刃、二段往返、双镖、绞杀旋涡、双镖与二段往返互斥。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _boom: Node2D
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
		_main.debug_give_weapon("boomerang")
		var slots: Array = _player.get("weapon_slots")
		var idx := _find_idx(slots, "boomerang")
		_tree = slots[idx].tree
		_tree.points = 100
		var wm: Node = _main.get_node("Player/WeaponManager")
		for child in wm.get_children():
			if child.get("weapon_id") == "boomerang":
				_boom = child
		_boom.set_talent_tree(_tree)
		_boom.call("_apply_talents")
	elif _frames == 2:
		_check_base()
		_grant("boom_power_1")
		_grant("boom_power_2")
		_grant("boom_power_3")
		_grant("boom_pierce_1")
		_grant("boom_pierce_2")  # 二段往返/旋涡前置
		_boom.call("_apply_talents")
		_check_power_pierce()
		_grant("boom_return")
		_boom.call("_apply_talents")
		_check_return()
		_grant("boom_whirlwind")
		_boom.call("_apply_talents")
		_check_whirlwind()
		_check_multi_conflict()
		_check_fire()
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	_tree.points += 1
	if not _tree.unlock("boomerang", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _boom.get("damage") == 2 and absf(_boom.get("cooldown") - 0.9) < 0.001 \
			and _boom.get("_pierce") == 0 and _boom.get("_max_trips") == 1:
		print("[OK] boomerang base (dmg=2 cd=0.9 pierce=0 trips=1)")
	else:
		_failures.append("boomerang base wrong (dmg=%d cd=%.2f pierce=%d trips=%d)" % [_boom.get("damage"), _boom.get("cooldown"), _boom.get("_pierce"), _boom.get("_max_trips")])

func _check_power_pierce() -> void:
	# 开刃链 1.1×1.1×1.15=1.3915 → 2×1.3915=2.783 → round 3。
	if _boom.get("damage") == 3:
		print("[OK] power chain -> dmg 3")
	else:
		_failures.append("damage=%d" % _boom.get("damage"))
	if _boom.get("_pierce") == 2:  # 贯穿刃 1 + 2
		print("[OK] boom_pierce x2 -> pierce 2")
	else:
		_failures.append("pierce=%d" % _boom.get("_pierce"))

func _check_return() -> void:
	if _boom.get("_max_trips") == 2:
		print("[OK] boom_return -> max trips 2")
	else:
		_failures.append("trips=%d" % _boom.get("_max_trips"))

func _check_multi_conflict() -> void:
	if _tree.unlock("boomerang", "boom_multi"):
		_failures.append("boom_multi unlocked despite return conflict")
	else:
		print("[OK] boom_multi conflicts with boom_return")
	_tree.owned["boomerang"]["boom_multi"] = true
	_boom.call("_apply_talents")
	if _boom.get("_extra_boomerang") == 1:
		print("[OK] boom_multi -> extra boomerang 1")
	else:
		_failures.append("extra_boomerang=%d" % _boom.get("_extra_boomerang"))

func _check_whirlwind() -> void:
	if _boom.get("_whirlwind") == true:
		print("[OK] boom_whirlwind -> whirlwind enabled")
	else:
		_failures.append("whirlwind not enabled")

func _check_fire() -> void:
	var before := get_nodes_in_group("friendly_projectiles").size()
	_boom.call("fire")
	var after := get_nodes_in_group("friendly_projectiles").size()
	if after - before == 2:  # 双镖：额外一枚
		print("[OK] fire launches 2 boomerangs (double)")
	else:
		_failures.append("boomerangs launched=%d" % (after - before))

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] boomerang test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
