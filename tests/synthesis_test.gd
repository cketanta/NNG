extends SceneTree
## 合成测试：两把同名武器合成 → 等级相加、保留高等级天赋树、点数 = 新等级 - 已点天赋数、槽位回收。

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
		_player.gain_gold(1000)
		# 买两把短刃 → 槽 1、2。
		_main.buy_weapon("blade")
		_main.buy_weapon("blade")
		var slots: Array = _player.get("weapon_slots")
		# 给第一把短刃点一个天赋（消耗 1 点，points 1->0）。
		var b1 := _find_idx(slots, "blade")
		if _main.unlock_weapon_talent(b1, "blade_range_1"):
			print("[OK] pre-combine: blade talent range_1 unlocked")
		else:
			_failures.append("pre-combine unlock failed")
		var b2 := -1
		for i in range(slots.size()):
			if slots[i].id == "blade" and i != b1:
				b2 = i
				break
		# 合成：等级相加 1+1=2；保留高等级天赋树（含 range_1）；点数 = 2 - 1 = 1。
		if _main.combine_weapons(b1, b2):
			slots = _player.get("weapon_slots")
			var blade_cnt := _count_slots(slots, "blade")
			var kept: Dictionary = _get_slot(slots, "blade")
			if blade_cnt == 1 and kept.level == 2:
				print("[OK] combine: blade level 1+1 = 2, one slot")
			else:
				_failures.append("combine level/count wrong (count=%d level=%d)" % [blade_cnt, kept.level])
			if kept.tree.is_owned("blade", "blade_range_1"):
				print("[OK] combine: higher-level talent tree kept (range_1)")
			else:
				_failures.append("talent tree not preserved")
			if kept.tree.points == 1:
				print("[OK] combine: points = level(2) - spent(1) = 1")
			else:
				_failures.append("points=%d want 1" % kept.tree.points)
		else:
			_failures.append("combine failed")
		_finish()
		return true
	return false

func _count_slots(slots: Array, id: String) -> int:
	var n := 0
	for s in slots:
		if s.id == id:
			n += 1
	return n

func _get_slot(slots: Array, id: String) -> Dictionary:
	for s in slots:
		if s.id == id:
			return s
	return {}

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] synthesis test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
