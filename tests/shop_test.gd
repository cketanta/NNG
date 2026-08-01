extends SceneTree
## 商店测试：开商店 -> 暂停；买重复武器 -> 等级叠加、金币扣除；武器节点同步；
## 关店 -> 恢复并进入下一波。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _whip: Node2D
var _staff: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()  # auto_pause_menus defaults true
	root.add_child(_main)
	current_scene = _main
	_player = _main.get_node("Player")
	_whip = _main.get_node("Player/WeaponManager/Whip")
	_staff = _main.get_node("Player/WeaponManager/Staff")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("whip")  # whip=1, staff=0
		_player.gain_gold(100)
		_main.open_shop()
	elif _frames == 5:
		if paused and _main.get("game_state") == 2:
			print("[OK] shop opens with pause (state=SHOP)")
		else:
			_failures.append("shop did not pause (paused=%s state=%d)" % [paused, _main.get("game_state")])
		if _main.get_node("HUD/ShopPanel").visible:
			print("[OK] shop panel visible")
		else:
			_failures.append("shop panel not visible")
		var ok1: bool = _main.buy_weapon("whip")
		var ok2: bool = _main.buy_weapon("staff")
		var ok3: bool = _main.buy_weapon("splitter")
		var ok4: bool = _main.buy_weapon("black_hole_gun")
		var ok5: bool = _main.buy_weapon("black_hole_gun")  # second copy -> level 2
		if ok1 and ok2 and ok3 and ok4 and ok5:
			print("[OK] bought all four weapons (bhg twice)")
		else:
			_failures.append("buy failed: %s/%s/%s/%s/%s" % [ok1, ok2, ok3, ok4, ok5])
		if _main.buy_item("shoes"):
			print("[OK] bought item (shoes)")
		else:
			_failures.append("buy item failed")
	elif _frames == 7:
		# 商店效果文案必须立即反映新等级（修复显示滞后 bug）。
		var shop := _main.get_node("HUD/ShopPanel") as ShopPanel
		var bhg_effect: String = shop._item_rows["black_hole_gun"]["effect"].text
		if "150" in bhg_effect:
			print("[OK] shop shows fresh black hole radius: %s" % bhg_effect)
		else:
			_failures.append("shop effect stale (bhg): '%s'" % bhg_effect)
		var row_count := 0
		var has_rarity := false
		for item_id in shop._shop_item_rows:
			row_count += 1
			if shop._shop_item_rows[item_id]["name"].text.begins_with("["):
				has_rarity = true
		if row_count == 5 and has_rarity:
			print("[OK] shop offers 5 items with rarity label")
		else:
			_failures.append("shop item rows=%d has_rarity=%s" % [row_count, has_rarity])
		_main.close_shop()
	elif _frames == 10:
		# 关店后游戏恢复，武器管理器已同步等级。
		# 开局 whip=1：买 whip -> 2；staff/splitter 0->1；bhg 0->1->2。
		var levels: Dictionary = _player.get("weapon_levels")
		if levels["whip"] == 2 and levels["staff"] == 1 and levels["splitter"] == 1 and levels["black_hole_gun"] == 2:
			print("[OK] weapon levels stacked correctly")
		else:
			_failures.append("weapon levels wrong: %s" % levels)
		if _player.get("gold") == 100 - 8 - 6 - 10 - 12 - 12 - 6:
			print("[OK] gold deducted correctly (46, incl. shoes)")
		else:
			_failures.append("gold not deducted (gold=%d)" % _player.get("gold"))
		if _player.get("item_counts").get("shoes", 0) == 1:
			print("[OK] item count tracked: shoes x1")
		else:
			_failures.append("shoes count=%d" % _player.get("item_counts").get("shoes", 0))
		if _whip.get("level") == 2:
			print("[OK] whip node synced to level 2")
		else:
			_failures.append("whip node level=%d" % _whip.get("level"))
		if _staff.get("level") == 1 and _staff.current_bullet_count() == 1:
			print("[OK] staff node synced, bullet count=%d" % int(_staff.current_bullet_count()))
		else:
			_failures.append("staff level=%d bullets=%d" % [_staff.get("level"), _staff.current_bullet_count()])
		if not paused and _main.get("game_state") == 1 and _main.get("wave_number") == 2:
			print("[OK] close_shop resumes and starts wave 2")
		else:
			_failures.append("close_shop state wrong (paused=%s state=%d wave=%d)" % [paused, _main.get("game_state"), _main.get("wave_number")])
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] shop test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
