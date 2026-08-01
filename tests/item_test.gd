extends SceneTree
## 道具系统测试：防御减伤、道具购买即时生效（移速/血量/绷带/幸运）、
## 咒戒唯一性、商店随机道具、武器最终属性公式（(基础+加算)×乘算×咒戒）。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _whip: Node2D
var _staff: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main
	_player = _main.get_node("Player")
	_whip = _main.get_node("Player/WeaponManager/Whip")
	_staff = _main.get_node("Player/WeaponManager/Staff")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("whip")
		_player.gain_gold(200)
	elif _frames == 5:
		_check_defense()
		_check_player_items()
	elif _frames == 8:
		_check_unique_and_offerings()
		_check_weapon_formula()
		_finish()
		return true
	return false

func _check_defense() -> void:
	_player.take_damage(5)  # 防御 0 -> 扣 5
	if _player.get("hp") == 95:
		print("[OK] damage without armor: hp=95")
	else:
		_failures.append("no-armor damage wrong (hp=%d)" % _player.get("hp"))
	if _main.buy_item("armor"):
		print("[OK] bought armor")
	else:
		_failures.append("buy armor failed")
	if _player.get("defense") == 1:
		print("[OK] defense=1 after armor")
	else:
		_failures.append("defense=%d" % _player.get("defense"))
	_player.take_damage(5)  # 防御 1 -> 扣 4
	if _player.get("hp") == 91:
		print("[OK] armor reduces damage: hp=91")
	else:
		_failures.append("armor reduction wrong (hp=%d)" % _player.get("hp"))

func _check_player_items() -> void:
	if _main.buy_item("shoes") and _player.get("move_speed_bonus") == 10:
		print("[OK] shoes: move_speed_bonus=10")
	else:
		_failures.append("shoes effect wrong (bonus=%d)" % _player.get("move_speed_bonus"))
	if _main.buy_item("shoes") == false:
		print("[OK] item bought once per wave (second buy blocked)")
	else:
		_failures.append("shoes bought twice in same wave!")
	if _main.buy_item("clover") and _player.get("luck") == 1:
		print("[OK] clover: luck=1")
	else:
		_failures.append("clover effect wrong (luck=%d)" % _player.get("luck"))
	# 绷带：回复 10 血（先受伤留出空间；当前 hp=91）
	_player.take_damage(10)  # 防御 1 -> 扣 9，hp=82
	var hp_hurt: int = _player.get("hp")
	if _main.buy_item("bandage") and _player.get("hp") == hp_hurt + 10:
		print("[OK] bandage heals 10: %d -> %d" % [hp_hurt, _player.get("hp")])
	else:
		_failures.append("bandage heal wrong (%d -> %d)" % [hp_hurt, _player.get("hp")])
	# 生命试剂：max_hp+10 且立即回 10（hp 不满时）
	var max_before: int = _player.get("max_hp")
	var hp_before: int = _player.get("hp")
	if _main.buy_item("reagent"):
		if _player.get("max_hp") == max_before + 10 and _player.get("hp") == hp_before + 10:
			print("[OK] reagent: max_hp=%d hp=%d" % [_player.get("max_hp"), _player.get("hp")])
		else:
			_failures.append("reagent effect wrong (max=%d hp=%d)" % [_player.get("max_hp"), _player.get("hp")])
	else:
		_failures.append("buy reagent failed")
	# 武器攻击力道具（用于后续公式断言）：近战 good_steel + whetstone，远程 blast_shot + gunpowder。
	_main.buy_item("good_steel")
	_main.buy_item("whetstone")
	_main.buy_item("blast_shot")
	_main.buy_item("gunpowder")
	_main.buy_item("hammer")  # 近战距离 ×1.1（锻锤）

func _check_unique_and_offerings() -> void:
	if _main.buy_item("ring"):
		print("[OK] bought unique ring")
	else:
		_failures.append("buy ring failed")
	if _main.buy_item("ring") == false:
		print("[OK] ring cannot be bought twice")
	else:
		_failures.append("ring bought twice!")
	if "ring" in _main.purchased_unique:
		print("[OK] ring recorded as purchased unique")
	else:
		_failures.append("ring not in purchased_unique")
	_main.refresh_shop_items()
	if _main.shop_item_offerings.has("ring"):
		_failures.append("ring still offered after purchase")
	else:
		print("[OK] ring no longer offered")
	if _main.shop_item_offerings.size() == 5:
		print("[OK] shop offers 5 items")
	else:
		_failures.append("shop offerings=%d" % _main.shop_item_offerings.size())
	var uniq := {}
	for item_id in _main.shop_item_offerings:
		uniq[item_id] = true
	if uniq.size() == _main.shop_item_offerings.size():
		print("[OK] offerings are distinct")
	else:
		_failures.append("offerings have duplicates")
	if _main.buy_item("shoes"):
		print("[OK] item can be bought again next wave (after refresh)")
	else:
		_failures.append("shoes blocked after refresh")

func _check_weapon_formula() -> void:
	# 近战鞭子：base=1，good_steel+1，whetstone×1.1，ring×1.5 -> (1+1)*1.1*1.5=3.3 -> 3
	var counts: Dictionary = _player.get("item_counts")
	var whip_stats: Dictionary = ItemDefs.weapon_final_stats(_whip, counts)
	if whip_stats.damage == 3:
		print("[OK] whip final damage=3 (formula)")
	else:
		_failures.append("whip damage=%d" % whip_stats.damage)
	if absf(whip_stats.cooldown - 0.7) < 0.001:
		print("[OK] whip cooldown=0.7 (no handle)")
	else:
		_failures.append("whip cooldown=%f" % whip_stats.cooldown)
	if absf(whip_stats.range - 70.0 * 1.1) < 0.001:
		print("[OK] whip range=77 (hammer x1.1)")
	else:
		_failures.append("whip range=%f" % whip_stats.range)
	# 远程法杖：base=1，blast_shot+1，gunpowder×1.1，ring×1.5 -> 3.3 -> 3
	var staff_stats: Dictionary = ItemDefs.weapon_final_stats(_staff, counts)
	if staff_stats.damage == 3:
		print("[OK] staff final damage=3 (formula)")
	else:
		_failures.append("staff damage=%d" % staff_stats.damage)
	if absf(staff_stats.speed - 500.0) < 0.001:
		print("[OK] staff speed=500 (no scope)")
	else:
		_failures.append("staff speed=%f" % staff_stats.speed)

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] item test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
