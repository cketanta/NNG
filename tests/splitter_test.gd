extends SceneTree
## 分裂者天赋测试：分裂弹数、制导分裂（小弹追踪）、剧毒（中毒 DOT）、制导与剧毒互斥。

const MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

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
		_check_poison_conflict()
		_grant("split_power_1")
		_splitter.call("_apply_talents")
		_check_poison_hit()
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

func _check_poison_conflict() -> void:
	if _tree.unlock("splitter", "split_poison"):
		_failures.append("split_poison unlocked despite homing conflict")
	else:
		print("[OK] split_poison conflicts with split_homing")
	# 直接置 owned 验证剧毒（不触发冲突检查）。
	_tree.owned["splitter"]["split_poison"] = true
	_splitter.call("_apply_talents")
	if _splitter.get("_poison") == true:
		print("[OK] split_poison -> poison enabled")
	else:
		_failures.append("poison not enabled")

func _check_poison_hit() -> void:
	var enemy := MELEE_SCENE.instantiate()
	enemy.set("max_hp", 100)
	_main.get_node("Spawner").add_child(enemy)
	_splitter.call("fire")
	var proj := get_nodes_in_group("friendly_projectiles")
	if proj.is_empty():
		_failures.append("no projectile fired")
		return
	proj[proj.size() - 1].call("_on_body_entered", enemy)
	if enemy.get("poison_stacks") == 1:
		print("[OK] poison hit applies poison stack")
	else:
		_failures.append("poison_stacks=%d" % enemy.get("poison_stacks"))
	enemy.free()

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
