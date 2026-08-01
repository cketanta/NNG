extends SceneTree
## 卡死压测探针：测试模式 + 满级分裂者/黑洞枪，测量每帧耗时与各实体数量，
## 定位是否出现单帧耗时爆炸或死循环（窗口未响应的主因）。

const BLACK_HOLE_SCRIPT := preload("res://scripts/items/black_hole.gd")

var _frames := 0
var _main: Node
var _last_time := 0.0
var _max_frame_time := 0.0
var _splitter_lv := 40
var _bhg_lv := 20
var _staff_lv := 0
var _density := -1.0  # <=0 表示用配置默认
var _diff := "test"

func _initialize() -> void:
	_last_time = Time.get_ticks_msec() / 1000.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("splitter="):
			_splitter_lv = int(a.split("=")[1])
		elif a.begins_with("bhg="):
			_bhg_lv = int(a.split("=")[1])
		elif a.begins_with("staff="):
			_staff_lv = int(a.split("=")[1])
		elif a.begins_with("density="):
			_density = float(a.split("=")[1])
		elif a.begins_with("diff="):
			_diff = a.split("=")[1]
	var scene := load("res://scenes/main.tscn")
	_main = scene.instantiate()
	_main.auto_pause_menus = false
	root.add_child(_main)
	current_scene = _main

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_main.choose_difficulty(_diff)
		if _density > 0.0:
			_main.difficulty["spawn_density_mult"] = _density
			_main.call("_apply_difficulty_to_spawner")
		var player: Node2D = _main.get_node("Player")
		player.weapon_levels["whip"] = 1
		player.weapon_levels["splitter"] = _splitter_lv
		player.weapon_levels["black_hole_gun"] = _bhg_lv
		player.weapon_levels["staff"] = _staff_lv
		for a in OS.get_cmdline_user_args():
			if a == "noxp":
				player.xp_max = 1000000  # 关闭升级，隔离升级/天赋是否卡死主因
		_main.start_with_weapon("whip")
	var now := Time.get_ticks_msec() / 1000.0
	var frame_time := now - _last_time
	_last_time = now
	_max_frame_time = maxf(_max_frame_time, frame_time)
	if frame_time > 0.4:
		print("[SPIKE] frame=%d took=%.3fs enemies=%d friendly=%d blackholes=%d gems=%d" % [_frames, frame_time, get_nodes_in_group("enemies").size(), get_nodes_in_group("friendly_projectiles").size(), _count_black_holes(), current_scene.get_child_count()])
	if _frames % 500 == 0:
		print("[probe] frame=%d fps=%.0f max_frame=%.3fs enemies=%d friendly=%d blackholes=%d gems=%d" % [_frames, 1.0 / maxf(frame_time, 0.001), _max_frame_time, get_nodes_in_group("enemies").size(), get_nodes_in_group("friendly_projectiles").size(), _count_black_holes(), current_scene.get_child_count()])
	if _frames >= 15000:
		print("[probe] done, max frame time = %.3fs" % _max_frame_time)
		quit(0)
		return true
	return false

func _count_black_holes() -> int:
	var n := 0
	for child in current_scene.get_children():
		if child.get_script() == BLACK_HOLE_SCRIPT:
			n += 1
	return n
