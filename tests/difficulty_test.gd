extends SceneTree
## 难度测试：开局选难度，验证倍率下发到刷怪器并生成缩放后的敌人
##（困难：怪血量/攻击 ×2，刷怪更快）。

const MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

var _frames := 0
var _failures: Array[String] = []
var _main: Node
var _spawner: Node2D

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_spawner = _main.get_node("Spawner")

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		if _main.get_node("HUD/DifficultyPanel").visible and paused:
			print("[OK] run starts on the difficulty panel")
		else:
			_failures.append("difficulty panel not shown first")
		_main.choose_difficulty("hard")
	elif _frames == 3:
		if _main.get("difficulty_id") == "hard":
			print("[OK] difficulty = hard")
		else:
			_failures.append("difficulty_id=%s" % _main.get("difficulty_id"))
		var spawn_mult: float = _spawner.get("_spawn_mult")
		var hp_mult: float = _spawner.get("_hp_mult")
		var attack_mult: float = _spawner.get("_attack_mult")
		if absf(spawn_mult - 0.8) < 0.001 and absf(hp_mult - 2.0) < 0.001 and absf(attack_mult - 2.0) < 0.001:
			print("[OK] spawner got hard multipliers")
		else:
			_failures.append("spawner mults wrong: %.2f/%.2f/%.2f" % [spawn_mult, hp_mult, attack_mult])
		# 手动应用难度后应得到困难值：近战怪血量 1*2=2、攻击 1*2=2。
		var enemy := MELEE_SCENE.instantiate()
		enemy.apply_difficulty(hp_mult, attack_mult)
		if enemy.get("max_hp") == 2 and enemy.get("contact_damage") == 2:
			print("[OK] hard enemy hp=2 attack=2")
		else:
			_failures.append("hard enemy stats wrong (hp=%d atk=%d)" % [enemy.get("max_hp"), enemy.get("contact_damage")])
		enemy.free()  # 未加入场景，避免泄漏
		_main.start_with_weapon("whip")
	elif _frames == 5:
		if _main.get("game_state") == 1 and not paused:
			print("[OK] combat started on hard")
		else:
			_failures.append("combat not started (state=%d paused=%s)" % [_main.get("game_state"), paused])
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] difficulty test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
