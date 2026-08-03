extends SceneTree
## 鞭子天赋测试：范围/伤害/攻速终值、连抽、血鞭（流血）、致命抽击（暴击）、连抽与血鞭互斥。

const MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _whip: Node2D
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
		_main.debug_give_weapon("whip")
		var slots: Array = _player.get("weapon_slots")
		var idx := _find_idx(slots, "whip")
		_tree = slots[idx].tree
		_tree.points = 100
		var wm: Node = _main.get_node("Player/WeaponManager")
		for child in wm.get_children():
			if child.get("weapon_id") == "whip":
				_whip = child
		_whip.set_talent_tree(_tree)
		_whip.call("_apply_talents")
	elif _frames == 2:
		_check_base()
		_grant("whip_range_1")
		_grant("whip_swift_1")
		_grant("whip_swift_2")  # 连抽/血鞭前置
		_grant("whip_power_1")
		_grant("whip_power_2")  # 致命抽击前置
		_whip.call("_apply_talents")
		_check_range()
		_grant("whip_multi")
		_whip.call("_apply_talents")
		_check_multi()
		_check_bleed_conflict()
		_grant("whip_crit")
		_whip.call("_apply_talents")
		_check_crit()
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	_tree.points += 1
	if not _tree.unlock("whip", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _whip.get("damage") == 1 and absf(_whip.get("cooldown") - 0.7) < 0.001 \
			and absf(_whip.get("melee_range") - 70.0) < 0.001 and _whip.get("_sweep_count") == 1:
		print("[OK] whip base (dmg=1 cd=0.7 range=70 sweep=1)")
	else:
		_failures.append("whip base wrong (dmg=%d cd=%.2f range=%.1f sweep=%d)" % [_whip.get("damage"), _whip.get("cooldown"), _whip.get("melee_range"), _whip.get("_sweep_count")])

func _check_range() -> void:
	if absf(_whip.get("melee_range") - 80.5) < 0.001:
		print("[OK] whip_range_1 -> range 80.5")
	else:
		_failures.append("whip range=%.1f" % _whip.get("melee_range"))

func _check_multi() -> void:
	if _whip.get("_sweep_count") == 2:
		print("[OK] whip_multi -> sweep count 2")
	else:
		_failures.append("sweep=%d" % _whip.get("_sweep_count"))

func _check_bleed_conflict() -> void:
	if _tree.unlock("whip", "whip_bleed"):
		_failures.append("whip_bleed unlocked despite multi conflict")
	else:
		print("[OK] whip_bleed conflicts with whip_multi")
	# 直接置 owned 验证血鞭效果（不触发冲突检查）。
	_tree.owned["whip"]["whip_bleed"] = true
	_whip.call("_apply_talents")
	if _whip.get("_bleed_on_hit") == true and _whip.get("_bleed_max") == 20:
		print("[OK] whip_bleed -> bleed_on_hit max 20")
	else:
		_failures.append("whip bleed wrong (%s max=%d)" % [_whip.get("_bleed_on_hit"), _whip.get("_bleed_max")])
	var enemy := MELEE_SCENE.instantiate()
	enemy.set("max_hp", 100)
	_main.get_node("Spawner").add_child(enemy)
	_whip.call("_on_zone_body_entered", enemy, 2)
	if enemy.get("bleed_stacks") == 1:
		print("[OK] whip hit applies bleed stack")
	else:
		_failures.append("bleed_stacks=%d" % enemy.get("bleed_stacks"))
	enemy.free()

func _check_crit() -> void:
	if _whip.get("_crit_chance") == 20.0:
		print("[OK] whip_crit -> crit chance 20%")
	else:
		_failures.append("crit_chance=%.1f" % _whip.get("_crit_chance"))

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] whip test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
