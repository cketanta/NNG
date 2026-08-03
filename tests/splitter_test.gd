extends SceneTree
## 分裂者天赋测试：分裂弹数、制导追踪、二次分裂（分裂小弹再分裂）、破片溅射。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _splitter: Node2D
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
		_main.debug_give_weapon("splitter")
		var slots: Array = _player.get("weapon_slots")
		var idx := _find_idx(slots, "splitter")
		_tree = slots[idx].tree
		_tree.points = 100
		var wm: Node = _main.get_node("Player/WeaponManager")
		for child in wm.get_children():
			if child.get("weapon_id") == "splitter":
				_splitter = child
		_splitter.set_talent_tree(_tree)
		_splitter.call("_apply_talents")
	elif _frames == 2:
		_check_base()
		_grant("split_children_1")
		_grant("split_children_2")  # 制导分裂前置
		_splitter.call("_apply_talents")
		_check_split()
		_grant("split_homing")
		_splitter.call("_apply_talents")
		_check_homing()
		_grant("sp2_tier_1")  # 二次分裂
		_splitter.call("_apply_talents")
		_check_tier()
		_grant("spf_shard_1")  # 破片溅射
		_splitter.call("_apply_talents")
		_check_shard()
		_grant("split_power_1")
		_splitter.call("_apply_talents")
		_check_fire()
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	_tree.points += 1
	if not _tree.unlock("splitter", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _splitter.get("damage") == 1 and absf(_splitter.get("cooldown") - 1.1) < 0.001 \
			and _splitter.get("_split_count") == 2:
		print("[OK] splitter base (dmg=1 cd=1.1 split=2)")
	else:
		_failures.append("splitter base wrong (dmg=%d cd=%.2f split=%d)" % [_splitter.get("damage"), _splitter.get("cooldown"), _splitter.get("_split_count")])

func _check_split() -> void:
	if _splitter.get("_split_count") == 4:  # 基础 2 + 分裂1 + 分裂2
		print("[OK] split_children x2 -> split 4")
	else:
		_failures.append("split_count=%d" % _splitter.get("_split_count"))

func _check_homing() -> void:
	if _splitter.get("_homing_deg") == 0.5:
		print("[OK] split_homing -> child homing 0.5")
	else:
		_failures.append("homing_deg=%.2f" % _splitter.get("_homing_deg"))

func _check_tier() -> void:
	if _splitter.get("_split_tier") == 1:
		print("[OK] sp2_tier_1 -> split tier 1 (二次分裂)")
	else:
		_failures.append("split_tier=%d" % _splitter.get("_split_tier"))

func _check_shard() -> void:
	if _splitter.get("_shard") == 1:
		print("[OK] spf_shard_1 -> shard 1 (破片溅射)")
	else:
		_failures.append("shard=%d" % _splitter.get("_shard"))

func _check_fire() -> void:
	_splitter.call("fire")
	var proj := get_nodes_in_group("friendly_projectiles")
	if proj.is_empty():
		_failures.append("no projectile fired")
		return
	var last := proj[proj.size() - 1]
	if last.get("_split_count") == 4 and last.get("_child_split") == 3 and last.get("_explode") == true:
		print("[OK] projectile carries split(4)/child_split(3)/shard")
	else:
		_failures.append("proj split=%d child_split=%d explode=%s" % [last.get("_split_count"), last.get("_child_split"), last.get("_explode")])

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] splitter test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
