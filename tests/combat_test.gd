extends SceneTree
## 战斗冒烟测试：攻击模式切换（含 HUD 标签）、敌方弹幕伤害、接触伤害、玩家死亡与游戏结束界面。

const MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")
const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")

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
		_test_toggle()
		# 在玩家身上放一枚敌方弹 -> 验证受击盒 area_entered。
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(Vector2.LEFT, 0.0, 5, false)
		_main.add_child(proj)
		proj.global_position = _player.global_position
	elif _frames == 10:
		if _player.hp == _player.max_hp - 5:
			print("[OK] enemy projectile damage applied, hp=%d" % _player.hp)
		else:
			_failures.append("enemy projectile damage not applied (hp=%d)" % _player.hp)
		# 在玩家身上放一只近战怪 -> 验证接触伤害。
		var enemy := MELEE_SCENE.instantiate()
		_main.get_node("Spawner").add_child(enemy)
		enemy.global_position = _player.global_position + Vector2(12, 0)
	elif _frames == 40:
		if _player.hp < _player.max_hp - 5:
			print("[OK] contact damage applied, hp=%d" % _player.hp)
		else:
			_failures.append("contact damage never applied")
		# 故意击杀玩家以验证游戏结束流程。
		_player.take_damage(999)
	elif _frames == 100:
		var panel: CanvasItem = _main.get_node("HUD/GameOverPanel")
		if panel.visible:
			print("[OK] game over panel shown after player death")
		else:
			_failures.append("game over panel not shown after player death")
		_finish()
		return true
	return false

func _test_toggle() -> void:
	var wm: Node2D = _player.get_node("WeaponManager")
	var before: int = wm.attack_mode
	wm.toggle_mode()
	var after: int = wm.attack_mode
	if after == before:
		_failures.append("attack mode toggle did not flip")
	else:
		print("[OK] attack mode toggled %d -> %d" % [before, after])
		var mode_label: Label = _main.get_node("HUD/ModeLabel")
		if after == 1 and mode_label.text == "模式: 手动 (Tab)":
			print("[OK] HUD mode label updated")
		else:
			_failures.append("HUD mode label not updated (text='%s')" % mode_label.text)
	wm.toggle_mode()  # restore AUTO

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] combat test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
