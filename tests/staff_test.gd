extends SceneTree
## 法杖天赋测试：散射弹数、贯穿、爆裂、凝光（收窄散射）、贯穿与爆裂互斥。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _staff: Node2D
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
		_main.debug_give_weapon("staff")
		var slots: Array = _player.get("weapon_slots")
		var idx := _find_idx(slots, "staff")
		_tree = slots[idx].tree
		_tree.points = 100
		var wm: Node = _main.get_node("Player/WeaponManager")
		for child in wm.get_children():
			if child.get("weapon_id") == "staff":
				_staff = child
		_staff.set_talent_tree(_tree)
		_staff.call("_apply_talents")
	elif _frames == 2:
		_check_base()
		_grant("staff_bullets_1")
		_grant("staff_bullets_2")
		_grant("staff_bullets_3")  # 凝光前置
		_staff.call("_apply_talents")
		_check_bullets()
		_grant("staff_pierce")
		_staff.call("_apply_talents")
		_check_pierce()
		_check_explode_conflict()
		_grant("staff_focus")
		_staff.call("_apply_talents")
		_check_focus()
		_check_fire()
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	_tree.points += 1
	if not _tree.unlock("staff", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _staff.get("damage") == 1 and absf(_staff.get("cooldown") - 0.8) < 0.001 \
			and _staff.get("_bullet_count") == 1:
		print("[OK] staff base (dmg=1 cd=0.8 bullets=1)")
	else:
		_failures.append("staff base wrong (dmg=%d cd=%.2f bullets=%d)" % [_staff.get("damage"), _staff.get("cooldown"), _staff.get("_bullet_count")])

func _check_bullets() -> void:
	if _staff.get("_bullet_count") == 4:  # 基础 1 + 星弹 x3
		print("[OK] staff_bullets x3 -> bullet count 4")
	else:
		_failures.append("bullet_count=%d" % _staff.get("_bullet_count"))

func _check_pierce() -> void:
	if _staff.get("_pierce") == 1:
		print("[OK] staff_pierce -> pierce 1")
	else:
		_failures.append("pierce=%d" % _staff.get("_pierce"))

func _check_explode_conflict() -> void:
	if _tree.unlock("staff", "staff_explode"):
		_failures.append("staff_explode unlocked despite pierce conflict")
	else:
		print("[OK] staff_explode conflicts with staff_pierce")
	_tree.owned["staff"]["staff_explode"] = true
	_staff.call("_apply_talents")
	if _staff.get("_explode") == true:
		print("[OK] staff_explode -> explode enabled")
	else:
		_failures.append("explode not enabled")

func _check_focus() -> void:
	if _staff.get("_focus") == true:
		print("[OK] staff_focus -> focus enabled")
	else:
		_failures.append("focus not enabled")

func _check_fire() -> void:
	var before := get_nodes_in_group("friendly_projectiles").size()
	_staff.call("fire")
	var after := get_nodes_in_group("friendly_projectiles").size()
	if after - before == 4:
		print("[OK] fire launches 4 projectiles")
	else:
		_failures.append("projectiles launched=%d" % (after - before))

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] staff test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
