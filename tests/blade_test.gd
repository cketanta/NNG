extends SceneTree
## 短刃天赋测试（每武器独立天赋树）：范围/伤害/攻速终值、气刃斩发射、狂战冲突、致残流血、气刃大回旋。

const MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D
var _blade: Node2D
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
		_main.debug_give_weapon("blade")
		var slots: Array = _player.get("weapon_slots")
		var idx := _find_idx(slots, "blade")
		_tree = slots[idx].tree
		_tree.points = 100  # 测试用足够点数
		var wm: Node = _main.get_node("Player/WeaponManager")
		for child in wm.get_children():
			if child.get("weapon_id") == "blade":
				_blade = child
		_blade.set_talent_tree(_tree)
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
		_check_ring_wave()
		_check_ring_wave_damage()
		_check_air_wave_texture()
		_finish()
		return true
	return false

func _grant(tid: String) -> void:
	_tree.points += 1
	if not _tree.unlock("blade", tid):
		_failures.append("cannot unlock %s" % tid)

func _check_base() -> void:
	if _blade.get("damage") == 2 and absf(_blade.get("cooldown") - 0.5) < 0.001 \
			and absf(_blade.get("melee_range") - 70.0) < 0.001 and _blade.get("_combo_count") == 1:
		print("[OK] blade base (dmg=2 cd=0.5 range=70 combo=1)")
	else:
		_failures.append("blade base wrong (dmg=%d cd=%.2f range=%.1f combo=%d)" % [_blade.get("damage"), _blade.get("cooldown"), _blade.get("melee_range"), _blade.get("_combo_count")])

func _check_buffs() -> void:
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
	if _tree.unlock("blade", "blade_berserk"):
		_failures.append("berserk unlocked despite air blade conflict")
	else:
		print("[OK] berserk conflicts with air blade")
	_blade.call("_apply_talents")
	if _blade.get("_bleed_on_hit") == false:
		print("[OK] no bleed without maim")
	else:
		_failures.append("bleed_on_hit without maim")
	# 直接置 owned 模拟点出致残（前置狂战与气刃斩互斥，此处只验证流血效果）。
	_tree.owned["blade"]["blade_maim"] = true
	_blade.call("_apply_talents")
	if _blade.get("_bleed_on_hit") == true and _blade.get("_bleed_max") == 30:
		print("[OK] maim enables bleed (max 30)")
	else:
		_failures.append("maim wrong")
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

func _check_ring_wave() -> void:
	_tree.owned["blade"]["blade_grand_slash"] = true
	_blade.call("_apply_talents")
	if _blade.get("_grand_slash") == true:
		print("[OK] grand slash enabled")
	else:
		_failures.append("grand slash not enabled")
	var before := _count_ring_waves()
	_blade.call("_launch_air_blades")
	var after := _count_ring_waves()
	if after - before == 1:
		print("[OK] grand slash spawns a ring wave")
	else:
		_failures.append("ring waves spawned=%d" % (after - before))

func _check_ring_wave_damage() -> void:
	var wave_script: Script = load("res://scripts/effects/ring_wave.gd")
	var wave: Node2D = wave_script.new()
	_main.add_child(wave)
	wave.global_position = Vector2.ZERO
	wave.setup(10, 0.0, 100.0)
	wave.set("_radius", 20.0)
	var enemy := MELEE_SCENE.instantiate()
	enemy.set("max_hp", 100)
	_main.get_node("Spawner").add_child(enemy)
	enemy.global_position = Vector2(24, 0)
	wave.call("_check_hits")
	if enemy.get("hp") == 90:
		print("[OK] ring wave deals damage in band")
	else:
		_failures.append("ring wave damage wrong (hp=%d)" % enemy.get("hp"))
	enemy.global_position = Vector2(60, 0)
	enemy.set("hp", 100)
	wave.call("_check_hits")
	if enemy.get("hp") == 100:
		print("[OK] ring wave misses enemies outside band")
	else:
		_failures.append("ring wave hit outside band (hp=%d)" % enemy.get("hp"))
	enemy.free()
	wave.queue_free()

func _count_ring_waves() -> int:
	var ring_script: Script = load("res://scripts/effects/ring_wave.gd")
	var n := 0
	for child in _main.get_children():
		if child.get_script() == ring_script:
			n += 1
	return n

func _check_air_wave_texture() -> void:
	var tex: Texture2D = preload("res://assets/projectiles/blade_air_wave.svg")
	var img: Image = tex.get_image()
	var has_pixels := false
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			if img.get_pixel(x, y).a > 0.5:
				has_pixels = true
				break
		if has_pixels:
			break
	if has_pixels:
		print("[OK] air wave texture renders non-empty")
	else:
		_failures.append("air wave texture is empty")

func _find_idx(slots: Array, id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == id:
			return i
	return -1

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] blade test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
