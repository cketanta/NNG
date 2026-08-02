extends SceneTree
## 商店测试：买武器入空槽；槽满同名自动合成；买道具；出售武器半价；槽位点选合成。

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
		_main.open_shop()
	elif _frames == 5:
		if paused and _main.get("game_state") == 2:
			print("[OK] shop opens with pause (state=SHOP)")
		else:
			_failures.append("shop did not pause (paused=%s state=%d)" % [paused, _main.get("game_state")])
		# 初始手枪 1 槽。买短刃两次：有空槽 → 各入一槽（不合成）。
		if _main.buy_weapon("blade") and _main.buy_weapon("blade"):
			print("[OK] bought 2 blades into empty slots")
		else:
			_failures.append("buy blade failed")
		# 买左轮 5 把 → 塞满到 8 槽。
		for i in range(5):
			if not _main.buy_weapon("revolver"):
				_failures.append("buy revolver %d failed" % i)
		var slots: Array = _player.get("weapon_slots")
		if slots.size() == 8:
			print("[OK] slots capped at 8")
		else:
			_failures.append("slots=%d" % slots.size())
		# 槽满且已有同名左轮 → 自动合成：等级 +1，槽数不变。
		var rev_before := _count_levels(slots, "revolver")
		if _main.buy_weapon("revolver"):
			slots = _player.get("weapon_slots")
			var rev_after := _count_levels(slots, "revolver")
			if slots.size() == 8 and rev_after == rev_before + 1:
				print("[OK] full slots auto-merge same-name (revolver levels %d -> %d)" % [rev_before, rev_after])
			else:
				_failures.append("auto merge wrong (slots=%d rev %d->%d)" % [slots.size(), rev_before, rev_after])
		else:
			_failures.append("buy on full slots failed")
		# 买道具。
		if _main.buy_item("shoes"):
			print("[OK] bought item (shoes)")
		else:
			_failures.append("buy item failed")
		# 出售一把短刃：金币 + 购买价值一半，槽 -1。
		slots = _player.get("weapon_slots")
		var blade_idx := _find_idx(slots, "blade")
		var blade_slot: Dictionary = slots[blade_idx]
		var sell_value: int = _main.get("WEAPON_BASE_COST")["blade"] / 2
		var gold_before: int = _player.get("gold")
		if blade_idx >= 0 and _main.sell_weapon(blade_idx):
			slots = _player.get("weapon_slots")
			if slots.size() == 7 and _player.get("gold") == gold_before + sell_value:
				print("[OK] sold blade for half value (%d), slots=7" % sell_value)
			else:
				_failures.append("sell wrong (slots=%d gold %d->%d)" % [slots.size(), gold_before, _player.get("gold")])
		else:
			_failures.append("sell failed")
		# 补买一把短刃用于合成验证（刚卖掉一把，只剩一把）。
		_main.buy_weapon("blade")
		# 合成：两把同名短刃点选合成 → 等级相加、保留一把、点数 = 新等级 - 已点天赋数。
		slots = _player.get("weapon_slots")
		var b1 := _find_idx(slots, "blade")
		var b2 := -1
		for i in range(slots.size()):
			if slots[i].id == "blade" and i != b1:
				b2 = i
				break
		if b1 >= 0 and b2 >= 0:
			var lv_sum: int = slots[b1].level + slots[b2].level
			if _main.combine_weapons(b1, b2):
				slots = _player.get("weapon_slots")
				var blade_cnt := _count_slots(slots, "blade")
				var blade_max := _max_level(slots, "blade")
				if blade_cnt == 1 and blade_max == lv_sum:
					print("[OK] combine blade: level sums to %d, one slot left" % lv_sum)
				else:
					_failures.append("combine wrong (count=%d max=%d want %d)" % [blade_cnt, blade_max, lv_sum])
			else:
				_failures.append("combine failed")
		else:
			_failures.append("need 2 blades to combine")
		_main.close_shop()
	elif _frames == 8:
		if not paused and _main.get("game_state") == 1 and _main.get("wave_number") == 2:
			print("[OK] close_shop resumes and starts wave 2")
		else:
			_failures.append("close_shop state wrong")
		_finish()
		return true
	return false

func _count_levels(slots: Array, id: String) -> int:
	var total := 0
	for s in slots:
		if s.id == id:
			total += s.level
	return total

func _count_slots(slots: Array, id: String) -> int:
	var n := 0
	for s in slots:
		if s.id == id:
			n += 1
	return n

func _max_level(slots: Array, id: String) -> int:
	var best := 0
	for s in slots:
		if s.id == id:
			best = maxi(best, s.level)
	return best

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] shop test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
