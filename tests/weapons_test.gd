extends SceneTree
## 攻击方式基础测试：破旧手枪 / 短刃 / 左轮手枪 的基础配置与发射行为（发射中心=玩家自身）。
## 分裂者与黑洞枪已在游戏内移除（脚本与贴图保留框架），不再测试。

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
		_check_pistol_fire()
	elif _frames == 2:
		_check_blade_base()
		_check_revolver_fire()
		_finish()
		return true
	return false

## 破旧手枪：单发子弹，从玩家中心发射。
func _check_pistol_fire() -> void:
	var before := get_nodes_in_group("friendly_projectiles").size()
	var pistol: Node2D = _main.get_node("Player/WeaponManager/Pistol")
	if pistol.get("base_damage") == 2 and absf(pistol.get("base_cooldown") - 0.6) < 0.001:
		print("[OK] pistol base (dmg=2 cd=0.6)")
	else:
		_failures.append("pistol base stats wrong")
	pistol.set_aim_direction(Vector2.RIGHT)
	pistol.call("fire")
	var bullets := get_nodes_in_group("friendly_projectiles")
	var new_count := bullets.size() - before
	if new_count == 1:
		print("[OK] pistol fires 1 bullet")
	else:
		_failures.append("pistol bullets=%d" % new_count)
	var b := bullets[bullets.size() - 1]
	if b.global_position.distance_to(_player.global_position) < 1.0:
		print("[OK] bullet spawns at player center")
	else:
		_failures.append("bullet spawn pos wrong")

## 短刃：近战配置。
func _check_blade_base() -> void:
	var blade: Node2D = _main.get_node("Player/WeaponManager/Blade")
	if blade.get("is_melee") == true and absf(blade.get("base_range") - 70.0) < 0.001:
		print("[OK] blade is melee, range 70")
	else:
		_failures.append("blade base stats wrong")

## 左轮手枪：基础 1 发，从玩家中心发射。
func _check_revolver_fire() -> void:
	var before := get_nodes_in_group("friendly_projectiles").size()
	var revolver: Node2D = _main.get_node("Player/WeaponManager/Revolver")
	if revolver.get("base_damage") == 4 and absf(revolver.get("base_cooldown") - 0.9) < 0.001:
		print("[OK] revolver base (dmg=4 cd=0.9)")
	else:
		_failures.append("revolver base stats wrong")
	_main.debug_set_attack("revolver")
	revolver.set_aim_direction(Vector2.RIGHT)
	revolver.call("fire")
	var bullets := get_nodes_in_group("friendly_projectiles")
	var new_count := bullets.size() - before
	if new_count == 1:
		print("[OK] revolver fires 1 bullet (no mag)")
	else:
		_failures.append("revolver bullets=%d" % new_count)
	var b := bullets[bullets.size() - 1]
	if b.global_position.distance_to(_player.global_position) < 1.0:
		print("[OK] revolver bullet spawns at player center")
	else:
		_failures.append("revolver spawn pos wrong")

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] weapons test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
