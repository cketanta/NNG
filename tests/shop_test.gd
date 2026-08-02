extends SceneTree
## 商店测试（空商店）：开商店 -> 暂停；显示金币与状态；无武器升级、无道具出售；
## 关店 -> 恢复并进入下一波。

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
		_main.start_with_weapon("pistol")
		_player.gain_gold(100)
		_main.open_shop()
	elif _frames == 5:
		if paused and _main.get("game_state") == 2:
			print("[OK] shop opens with pause (state=SHOP)")
		else:
			_failures.append("shop did not pause (paused=%s state=%d)" % [paused, _main.get("game_state")])
		if _main.get_node("HUD/ShopPanel").visible:
			print("[OK] shop panel visible")
		else:
			_failures.append("shop panel not visible")
		var shop := _main.get_node("HUD/ShopPanel") as ShopPanel
		# 空商店：武器升级区与道具购买区已删除。
		if not shop.has_method("_make_upgrade_box") and not shop.has_method("_make_item_shop_box"):
			print("[OK] shop has no weapon upgrade / item purchase")
		else:
			_failures.append("shop still has upgrade/item boxes")
		if "100" in shop._gold_label.text:
			print("[OK] shop shows gold")
		else:
			_failures.append("shop gold label '%s'" % shop._gold_label.text)
		_main.close_shop()
	elif _frames == 8:
		if not paused and _main.get("game_state") == 1 and _main.get("wave_number") == 2:
			print("[OK] close_shop resumes and starts wave 2")
		else:
			_failures.append("close_shop state wrong (paused=%s state=%d wave=%d)" % [paused, _main.get("game_state"), _main.get("wave_number")])
		_finish()
		return true
	return false

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] shop test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
