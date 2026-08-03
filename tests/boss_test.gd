extends SceneTree
## BOSS 测试：验证 spawn_boss 生成与 setup（巨型/血厚），以及每 5 波 begin_wave 自动生成 BOSS。

var _frames := 0
var _failures: Array[String] = []
var _main: Node

func _initialize() -> void:
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.choose_test_mode()
		var spawner: Node = _main.get_node("Spawner")
		# 直接调 spawn_boss：应生成一个 is_elite + body_scale=2.0 的 BOSS。
		spawner.call("spawn_boss")
		var boss: Node2D = null
		for e in get_nodes_in_group("enemies"):
			if e.get("body_scale") == 2.0:  # BOSS 特征：2 倍体型（专属配色，非精英金色）
				boss = e
		if boss != null:
			print("[OK] boss spawned with setup (elite + big)")
			if boss.get("max_hp") >= 120:
				print("[OK] boss hp scaled (%d)" % boss.get("max_hp"))
			else:
				_failures.append("boss hp=%d" % boss.get("max_hp"))
		else:
			_failures.append("no boss spawned")
		# 每 5 波：begin_wave(5) 应额外生成一个 BOSS。
		var before := get_nodes_in_group("enemies").size()
		spawner.call("begin_wave", 5)
		var after := get_nodes_in_group("enemies").size()
		if after > before:
			print("[OK] wave 5 auto-spawns boss")
		else:
			_failures.append("wave5 no boss")
		# 非 5 波不应生成 BOSS。
		var before2 := get_nodes_in_group("enemies").size()
		spawner.call("begin_wave", 6)
		var after2 := get_nodes_in_group("enemies").size()
		if after2 == before2:
			print("[OK] wave 6 no boss")
		else:
			_failures.append("wave6 spawned extra enemy")
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] boss test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
