extends SceneTree
## 武器系统测试：多武器环绕布局（圆周半径 34）、每武器独立天赋树实例、发射子弹。

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _player: Node2D

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
		_main.debug_give_weapon("revolver")
		_main.debug_give_weapon("whip")
		_main.debug_give_weapon("staff")
		_main.debug_give_weapon("splitter")
		_main.debug_give_weapon("black_hole_gun")
		_main.debug_give_weapon("boomerang")
	elif _frames == 3:
		var wm: Node = _main.get_node("Player/WeaponManager")
		if wm.get_child_count() == 8:
			print("[OK] all 8 weapon nodes spawned from slots")
		else:
			_failures.append("weapon nodes=%d" % wm.get_child_count())
		# 环绕布局：所有武器距玩家中心约 34px（圆周）。
		var on_ring := true
		for child in wm.get_children():
			if absf(child.position.length() - 34.0) > 1.0:
				on_ring = false
		if on_ring:
			print("[OK] weapons orbit player (ring radius 34)")
		else:
			_failures.append("weapons not on ring")
		# 每把武器独立天赋树实例。
		var trees := {}
		for child in wm.get_children():
			trees[child.get("talent_tree")] = true
		if trees.size() == 8:
			print("[OK] each weapon has independent talent tree")
		else:
			_failures.append("distinct trees=%d" % trees.size())
		# 破旧手枪发射子弹（从武器位置）。
		var before := get_nodes_in_group("friendly_projectiles").size()
		var pistol: Node = null
		for child in wm.get_children():
			if child.get("weapon_id") == "pistol":
				pistol = child
		if pistol != null:
			pistol.set_aim_direction(Vector2.RIGHT)
			pistol.call("fire")
			var bullets := get_nodes_in_group("friendly_projectiles").size() - before
			if bullets == 1:
				print("[OK] pistol fires 1 bullet from weapon position")
			else:
				_failures.append("pistol bullets=%d" % bullets)
		else:
			_failures.append("pistol node missing")
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] weapons test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
