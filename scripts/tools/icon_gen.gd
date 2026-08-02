extends SceneTree
## 图标生成工具：把 assets/icon.svg 栅格化为 256x256 的 assets/icon.png，供导出程序图标用。
## 运行：godot --headless --path . --script res://scripts/tools/icon_gen.gd

func _init() -> void:
	var img := Image.load_from_file("res://assets/icon.svg")
	if img.is_empty():
		push_error("icon.svg 栅格化失败")
		quit(1)
		return
	img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	img.save_png("res://assets/icon.png")
	print("icon.png 已生成：", img.get_size())
	quit(0)
