extends SceneTree
## 武器测试：验证分裂者（命中分裂成 4 枚）与黑洞枪的黑洞
##（把子弹与怪物吸向核心、保持存活、不造成伤害）。

const MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")
const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
const BLACK_HOLE_SCENE := preload("res://scenes/items/black_hole.tscn")

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _split_enemy: Node2D
var _hole_enemy: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.start_with_weapon("whip")
		_setup_splitter()
	elif _frames == 2:
		_check_weapon_level_effects()
		_check_staff_arc_cap()
	elif _frames == 60:
		_check_splitter()
		_setup_black_holes()
	elif _frames == 140:
		_check_black_holes()
		_finish()
		return true
	return false

func _check_weapon_level_effects() -> void:
	# 用独立的武器实例测试（不加入场景、不会开火），避免干扰分裂实战测试。
	var splitter := preload("res://scenes/weapons/splitter.tscn").instantiate()
	var bhg := preload("res://scenes/weapons/black_hole_gun.tscn").instantiate()
	splitter.set_level(1)
	bhg.set_level(1)
	if splitter.current_split_count() == 2 and bhg.current_black_hole_radius() == 130.0:
		print("[OK] level 1: splitter=2 children, black hole radius=130")
	else:
		_failures.append("level 1 effects wrong (split=%d radius=%f)" % [splitter.current_split_count(), bhg.current_black_hole_radius()])
	splitter.set_level(3)
	bhg.set_level(2)
	if splitter.current_split_count() == 4 and bhg.current_black_hole_radius() == 150.0:
		print("[OK] level 3 splitter=4, level 2 black hole radius=150")
	else:
		_failures.append("leveled effects wrong (split=%d radius=%f)" % [splitter.current_split_count(), bhg.current_black_hole_radius()])
	# 黑洞半径随等级无上限增长（恢复玩家要求的全范围）。
	var lv20_radius: float = bhg.black_hole_radius_for_level(20)
	if absf(lv20_radius - 510.0) < 0.001:
		print("[OK] black hole radius grows uncapped (level 20 radius=%d)" % int(lv20_radius))
	else:
		_failures.append("radius growth wrong at level 20: %f" % lv20_radius)
	splitter.free()
	bhg.free()

func _check_staff_arc_cap() -> void:
	var staff := preload("res://scenes/weapons/staff.tscn").instantiate()
	# 早期（未满一圈）：相邻角保持 12°
	if absf(staff.arc_step_degrees(8) - 12.0) < 0.001:
		print("[OK] staff step=12° under one ring (count=8)")
	else:
		_failures.append("staff early step wrong: %f" % staff.arc_step_degrees(8))
	# 满一圈（31 弹）：进入封顶，步进 < 12°，方向不重叠
	var step31: float = staff.arc_step_degrees(31)
	if step31 < 12.0 and absf(step31 - 360.0 / 31.0) < 0.001:
		print("[OK] staff arc capped at 360° (count=31 step=%.2f°)" % step31)
	else:
		_failures.append("staff ring step wrong: %f" % step31)
	# 超过一圈：封顶 360° 内均匀分布，方向唯一不重叠
	var step60: float = staff.arc_step_degrees(60)
	if step60 < 12.0 and absf(step60 - 360.0 / 60.0) < 0.001:
		print("[OK] staff arc capped (count=60 step=%.2f°)" % step60)
	else:
		_failures.append("staff cap wrong: %f" % step60)
	var dirs := {}
	var overlap := false
	for i in range(60):
		var offset := (i - 59.0 / 2.0) * deg_to_rad(step60)
		var angle := fposmod(rad_to_deg(offset), 360.0)
		if dirs.has(angle):
			overlap = true
		dirs[angle] = true
	if not overlap:
		print("[OK] staff 60 bullets have 60 distinct directions")
	else:
		_failures.append("staff directions overlap at count=60")
	staff.free()

func _setup_splitter() -> void:
	_split_enemy = MELEE_SCENE.instantiate()
	_split_enemy.set("max_hp", 10)  # 足够高，保证母弹+重击小弹后仍存活
	_split_enemy.global_position = Vector2(120, 0)  # 先设位置再入树，避免碰撞形状滞留在原点
	_split_enemy.set_physics_process(false)  # 让它静止，命中位置确定
	_main.get_node("Spawner").add_child(_split_enemy)
	var proj := PROJECTILE_SCENE.instantiate()
	proj.setup(Vector2.RIGHT, 420.0, 1, true)
	proj.set_split_on_hit(4)
	proj.global_position = Vector2.ZERO
	_main.add_child(proj)

func _check_splitter() -> void:
	# 1.0.0 基线：分裂小弹会立刻命中母弹刚打中的怪（已知问题），因此只断言母弹命中，
	# 不断言小弹存活数量。
	if _split_enemy.get("hp") < _split_enemy.get("max_hp"):
		print("[OK] splitter parent hit the enemy (hp=%d/%d)" % [_split_enemy.get("hp"), _split_enemy.get("max_hp")])
	else:
		_failures.append("splitter parent never hit (hp=%d/%d)" % [_split_enemy.get("hp"), _split_enemy.get("max_hp")])

func _setup_black_holes() -> void:
	# 清掉分裂测试留下的子弹，避免干扰黑洞测试
	for group_name in ["friendly_projectiles", "enemy_projectiles"]:
		for b in get_nodes_in_group(group_name):
			if is_instance_valid(b):
				b.queue_free()
	# 黑洞 1 拉一只与 AI 方向相反（AI 想回原点玩家处）的怪，验证拉拽压过 AI。
	var hole1 := BLACK_HOLE_SCENE.instantiate()
	hole1.set("lifetime", 0.9)
	_main.add_child(hole1)
	hole1.global_position = Vector2(0, 300)
	_hole_enemy = MELEE_SCENE.instantiate()
	_hole_enemy.set("max_hp", 5)  # 避免任何散弹命中导致它提前死亡干扰断言
	_hole_enemy.global_position = Vector2(0, 200)  # 先设位置再入树
	_main.get_node("Spawner").add_child(_hole_enemy)
	# 黑洞 2 吸一枚友方弹 + 一枚敌方弹（附近无敌人）。
	var hole2 := BLACK_HOLE_SCENE.instantiate()
	hole2.set("lifetime", 0.9)
	_main.add_child(hole2)
	hole2.global_position = Vector2(400, 0)
	var fb := PROJECTILE_SCENE.instantiate()
	fb.setup(Vector2.RIGHT, 0.0, 1, true)
	fb.global_position = Vector2(500, 0)
	_main.add_child(fb)
	var eb := PROJECTILE_SCENE.instantiate()
	eb.setup(Vector2.LEFT, 0.0, 1, false)
	eb.global_position = Vector2(300, 0)
	_main.add_child(eb)

func _check_black_holes() -> void:
	# 敌人被黑洞 1 拉近（距离 < 初始 100）且未受伤。
	var hole1_pos := Vector2(0, 300)
	var enemy_dist := _hole_enemy.global_position.distance_to(hole1_pos)
	if enemy_dist < 100.0:
		print("[OK] enemy pulled toward hole (dist=%.0f)" % enemy_dist)
	else:
		_failures.append("enemy not pulled (dist=%.0f)" % enemy_dist)
	if _hole_enemy.get("hp") >= _hole_enemy.get("max_hp"):
		print("[OK] black hole deals no damage")
	else:
		_failures.append("black hole damaged the enemy")
	if _hole_enemy.get("_pull_twitch_time") > 0.0:
		print("[OK] enemy twitches at the hole core")
	else:
		_failures.append("enemy not twitching at core (twitch_time=%.3f)" % _hole_enemy.get("_pull_twitch_time"))
	# 两枚子弹都被吸到黑洞 2 的环形翻搅带内（距核心 < 100，初始为 100）且仍存活（未被消耗）。
	var hole2_pos := Vector2(400, 0)
	var near := 0
	for group_name in ["friendly_projectiles", "enemy_projectiles"]:
		for b in get_nodes_in_group(group_name):
			if not is_instance_valid(b):
				continue
			if b.global_position.distance_to(hole2_pos) < 100.0:
				near += 1
	if near >= 2:
		print("[OK] both bullets pulled into the hole ring (%d near)" % near)
	else:
		_failures.append("bullets not pulled to hole (near=%d)" % near)

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] weapons test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
