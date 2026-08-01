extends SceneTree
## 结算界面测试：暂停菜单「结束该局」→ 结算（标题「本局结束」+ 统计 + 解除暂停）；
## 死亡路径 → 结算（标题「游戏结束」）。

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
		_main.start_with_weapon("whip")
		_player.gain_gold(50)
		_main.open_pause()
	elif _frames == 5:
		# 暂停态下「结束该局」进入结算。
		if paused and _main.get_node("HUD/PausePanel").visible:
			print("[OK] pause open before ending")
		else:
			_failures.append("pause not open (paused=%s)" % paused)
		_main.end_game_from_pause()
	elif _frames == 8:
		_check_result("本局结束", "paused=" + str(paused))
		# 死亡路径：结算标题变为「游戏结束」。
		_player.take_damage(999)
	elif _frames == 12:
		var panel: Control = _main.get_node("HUD/GameOverPanel")
		if panel.visible:
			var title: String = panel.get_node("CenterBox/GameOverTitle").text
			if title == "游戏结束":
				print("[OK] death path shows 游戏结束")
			else:
				_failures.append("death title='%s'" % title)
		else:
			_failures.append("game over panel not visible after death")
		_finish()
		return true
	return false

## 断言结算面板展示：标题、统计文本、state、暂停、退出按钮。
func _check_result(expected_title: String, ctx: String) -> void:
	var panel: Control = _main.get_node("HUD/GameOverPanel")
	if not panel.visible:
		_failures.append("result panel not visible (%s)" % ctx)
		return
	var title: String = panel.get_node("CenterBox/GameOverTitle").text
	if title == expected_title:
		print("[OK] result title: %s" % title)
	else:
		_failures.append("title='%s' want '%s'" % [title, expected_title])
	var labels := {
		"CenterBox/GameOverDifficulty": "难度",
		"CenterBox/GameOverKills": "击杀",
		"CenterBox/GameOverWave": "到达波次",
		"CenterBox/GameOverLevel": "玩家等级",
		"CenterBox/GameOverGold": "金币",
		"CenterBox/GameOverTime": "存活时间",
	}
	var filled := true
	for path in labels:
		var text: String = panel.get_node(path).text
		if not text.begins_with(labels[path]):
			filled = false
			_failures.append("%s not filled: '%s'" % [path, text])
	if filled:
		print("[OK] all result stats filled")
	if _main.get("game_state") == 3:
		print("[OK] game_state = GAMEOVER")
	else:
		_failures.append("game_state=%d" % _main.get("game_state"))
	if not paused:
		print("[OK] game unpaused on result (%s)" % ctx)
	else:
		_failures.append("still paused (%s)" % ctx)
	if panel.has_node("CenterBox/QuitButton"):
		print("[OK] quit button exists")
	else:
		_failures.append("quit button missing")

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] result test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
