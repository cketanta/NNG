extends SceneTree
## 短刃天赋测试：范围/伤害/攻速的基础终值、气刃斩发射、狂战冲突、致残流血。

const MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _blade: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main
	_player = _main.get_node("Player")
	_blade = _main.get_node("Player/WeaponManager/Blade")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("pistol")
		_main.debug_set_attack("blade")
		_blade.call("_apply_talents")
	elif _frames == 2:
		_check_base()
		_grant("blade_range_1")
		_grant("blade_sharp_1")
		_grant("blade_swift_1")
		_blade.call("_apply_talents")
		_check_buffs()
		_grant("blade_air_blade")
		_blade.call("_apply_talents")
		_check_air_blades()
		_check_bleed()
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	var tree = _main.get("talent_tree")
	tree.points += 1
	if not tree.unlock("blade", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _blade.get("damage") == 2 and absf(_blade.get("cooldown") - 0.5) < 0.001 \
			and absf(_blade.get("melee_range") - 70.0) < 0.001 and _blade.get("_combo_count") == 1:
		print("[OK] blade base (dmg=2 cd=0.5 range=70 combo=1)")
	else:
		_failures.append("blade base wrong (dmg=%d cd=%.2f range=%.1f combo=%d)" % [_blade.get("damage"), _blade.get("cooldown"), _blade.get("melee_range"), _blade.get("_combo_count")])

func _check_buffs() -> void:
	# 范围1 ×1.1、利刃1 +10%（取整仍 2）、拔刀1 cd×0.9。
	if absf(_blade.get("melee_range") - 77.0) < 0.001:
		print("[OK] range_1 -> 77")
	else:
		_failures.append("range=%.1f" % _blade.get("melee_range"))
	if _blade.get("damage") == 2:
		print("[OK] sharp_1 keeps dmg=2 (rounded)")
	else:
		_failures.append("damage=%d" % _blade.get("damage"))
	if absf(_blade.get("cooldown") - 0.45) < 0.001:
		print("[OK] swift_1 -> cd 0.45")
	else:
		_failures.append("cooldown=%.3f" % _blade.get("cooldown"))

func _check_air_blades() -> void:
	if _blade.get("_air_blade_count") == 1:
		print("[OK] air blade count = 1")
	else:
		_failures.append("air blade count=%d" % _blade.get("_air_blade_count"))
	var before := get_nodes_in_group("friendly_projectiles").size()
	_blade.call("_launch_air_blades")
	var after := get_nodes_in_group("friendly_projectiles").size()
	if after - before == 1:
		print("[OK] air blade launches 1 projectile")
	else:
		_failures.append("air blades launched=%d" % (after - before))

func _check_bleed() -> void:
	var tree = _main.get("talent_tree")
	# 已点气刃斩：狂战应无法解锁（互斥）。
	tree.points = 10
	if tree.unlock("blade", "blade_berserk"):
		_failures.append("berserk unlocked despite air blade conflict")
	else:
		print("[OK] berserk conflicts with air blade")
	_blade.call("_apply_talents")
	if _blade.get("_bleed_on_hit") == false:
		print("[OK] no bleed without maim")
	else:
		_failures.append("bleed_on_hit without maim")
	# 直接置 owned 模拟点出致残（其前置狂战与气刃斩互斥，此处只验证流血效果）。
	tree.owned["blade"]["blade_maim"] = true
	_blade.call("_apply_talents")
	if _blade.get("_bleed_on_hit") == true and _blade.get("_bleed_max") == 30:
		print("[OK] maim enables bleed (max 30)")
	else:
		_failures.append("maim wrong (on=%s max=%d)" % [_blade.get("_bleed_on_hit"), _blade.get("_bleed_max")])
	# 命中叠加流血：先受 2 挥砍伤（hp=98），再叠 1 层流血；随后受 5 伤 + 1 流血层 = 6（hp=92）。
	var enemy := MELEE_SCENE.instantiate()
	enemy.set("max_hp", 100)
	_main.get_node("Spawner").add_child(enemy)
	_blade.call("_on_zone_body_entered", enemy, 2)
	if enemy.get("bleed_stacks") == 1:
		print("[OK] hit applies bleed stack")
	else:
		_failures.append("bleed_stacks=%d" % enemy.get("bleed_stacks"))
	enemy.call("take_damage", 5)
	if enemy.get("hp") == 92:
		print("[OK] bleed adds extra damage on hit (hp=92)")
	else:
		_failures.append("bleed damage wrong (hp=%d)" % enemy.get("hp"))
	enemy.free()

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] blade test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
