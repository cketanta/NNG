extends SceneTree
## 调试面板测试（测试模式）：
## 难度面板「测试模式」进入 -> 按 L 开调试面板（暂停）-> 调波数/金币/等级/属性/武器等级生效、
## 无限道具不扣钱、Esc 关闭不弹暂停 -> 非测试模式 L 无效。

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
		_main.choose_test_mode()
		if _main.get("test_mode"):
			print("[OK] test mode enabled")
		else:
			_failures.append("test_mode not set")
		if not _main.get_node("HUD/DifficultyPanel").visible and not paused and _main.get("game_state") == 1:
			print("[OK] test mode goes straight to combat")
		else:
			_failures.append("test mode did not start combat")
		_main.start_with_weapon("pistol")
	elif _frames == 2:
		# 非测试模式下 L 应无效。
		_main.set("test_mode", false)
		_send_l()
		if _main.get_node("HUD/DebugPanel").visible:
			_failures.append("L opened debug panel in non-test mode")
		else:
			print("[OK] L disabled outside test mode")
		_main.set("test_mode", true)
	elif _frames == 3:
		_send_l()
	elif _frames == 5:
		var debug := _main.get_node("HUD/DebugPanel")
		if debug.visible and paused:
			print("[OK] L opens debug panel with pause")
		else:
			_failures.append("debug panel not open (visible=%s paused=%s)" % [debug.visible, paused])
		# 调波数：立即清怪重开。
		_main.set_wave_number(10)
		if _main.get("wave_number") == 10:
			print("[OK] wave set to 10")
		else:
			_failures.append("wave_number=%d" % _main.get("wave_number"))
		if "10" in _main.get_node("HUD/WaveLabel").text:
			print("[OK] HUD wave label updated")
		else:
			_failures.append("HUD wave label '%s'" % _main.get_node("HUD/WaveLabel").text)
		if get_nodes_in_group("enemies").is_empty():
			print("[OK] enemies cleared on wave jump")
		else:
			_failures.append("enemies remain after wave jump")
		# 金币 / 等级 / 属性 / 武器等级。
		_player.set_gold(999)
		if _player.get("gold") == 999 and "999" in _main.get_node("HUD/GoldLabel").text:
			print("[OK] gold set to 999 (HUD synced)")
		else:
			_failures.append("gold=%d hud='%s'" % [_player.get("gold"), _main.get_node("HUD/GoldLabel").text])
		_player.set_level(20)
		if _player.get("level") == 20 and _player.get("xp_max") == 100:
			print("[OK] level set to 20, xp_max=100")
		else:
			_failures.append("level=%d xp_max=%d" % [_player.get("level"), _player.get("xp_max")])
		_player.set_defense(5)
		_player.set_speed(500.0)
		_player.set_max_hp(300)
		_player.set_luck(3)
		if _player.get("defense") == 5 and _player.get("speed") == 500.0 and _player.get("max_hp") == 300 and _player.get("luck") == 3:
			print("[OK] attribute setters applied")
		else:
			_failures.append("attribute setters failed")
		_main.debug_give_weapon("blade")
		var slots: Array = _player.get("weapon_slots")
		if _count_slots(slots, "blade") == 1:
			print("[OK] debug give weapon (blade)")
		else:
			_failures.append("debug give blade failed")
		_main.debug_give_weapon("blade")
		_main.debug_remove_weapon("blade")
		slots = _player.get("weapon_slots")
		if _count_slots(slots, "blade") == 1:
			print("[OK] debug remove weapon (blade)")
		else:
			_failures.append("debug remove blade failed")
	elif _frames == 6:
		# 无限道具：不扣钱。
		var gold_before: int = _player.get("gold")
		_main.debug_give_item("shoes")
		_main.debug_give_item("shoes")
		_main.debug_give_item("shoes")
		if _player.get("item_counts").get("shoes", 0) == 3:
			print("[OK] infinite item x3")
		else:
			_failures.append("shoes count=%d" % _player.get("item_counts").get("shoes", 0))
		if _player.get("gold") == gold_before:
			print("[OK] debug item costs no gold")
		else:
			_failures.append("gold changed on debug item")
		# 每波时间。
		_main.set_wave_duration(10)
		if absf(_main.get("wave_duration") - 10.0) < 0.001:
			print("[OK] wave duration set to 10")
		else:
			_failures.append("wave_duration=%f" % _main.get("wave_duration"))
	elif _frames == 7:
		# 减少道具：减计数 + 撤销玩家侧效果（3 双跑鞋 = 移速 +30）。
		var before_bonus: int = _player.get("move_speed_bonus")
		_main.debug_remove_item("shoes")
		if _player.get("item_counts").get("shoes", 0) == 2:
			print("[OK] remove item decrements count")
		else:
			_failures.append("shoes after remove=%d" % _player.get("item_counts").get("shoes", 0))
		if _player.get("move_speed_bonus") == before_bonus - 10:
			print("[OK] remove item reverts player effect")
		else:
			_failures.append("move_speed_bonus=%d want %d" % [_player.get("move_speed_bonus"), before_bonus - 10])
		# 数量直接输入：把跑鞋数量直接设为 10（从 2 补到 10）。
		var bonus_before_set: int = _player.get("move_speed_bonus")
		_main.debug_set_item_count("shoes", 10)
		if _player.get("item_counts").get("shoes", 0) == 10:
			print("[OK] set item count to 10")
		else:
			_failures.append("shoes after set=%d" % _player.get("item_counts").get("shoes", 0))
		if _player.get("move_speed_bonus") == bonus_before_set + 8 * 10:
			print("[OK] set count applies player effects correctly")
		else:
			_failures.append("move_speed_bonus=%d want %d" % [_player.get("move_speed_bonus"), bonus_before_set + 80])
	elif _frames == 8:
		_send_esc()
	elif _frames == 10:
		var debug := _main.get_node("HUD/DebugPanel")
		if not debug.visible:
			print("[OK] Esc closes debug panel")
		else:
			_failures.append("debug panel still open after Esc")
		if not _main.get_node("HUD/PausePanel").visible:
			print("[OK] Esc from debug does not open pause")
		else:
			_failures.append("Esc from debug opened pause!")
		if not paused:
			print("[OK] game resumed after closing debug")
		else:
			_failures.append("game still paused after closing debug")
		_finish()
		return true
	return false

## 模拟按 L：走 main 的 toggle_debug 分发。
func _send_l() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_L
	ev.pressed = true
	_main._unhandled_input(ev)

## 模拟按 Esc：面板先收（真实逆序分发），handled 后 main 不再收到。
func _send_esc() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	var debug: Control = _main.get_node("HUD/DebugPanel")
	if debug.visible:
		debug._unhandled_input(ev)
		if root.is_input_handled():
			return
	_main._unhandled_input(ev)

func _count_slots(slots: Array, id: String) -> int:
	var n := 0
	for s in slots:
		if s.id == id:
			n += 1
	return n

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] debug test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
