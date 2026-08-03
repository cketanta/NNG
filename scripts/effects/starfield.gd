class_name Starfield
extends Node2D
## 浮动星光背景装饰：全屏 Node2D，纯 _draw 画缓慢漂移的星点。
## 作为面板背景的装饰层（放在 fullscreen_bg 之上），不拦截鼠标。

var _stars: Array[Dictionary] = []

func _ready() -> void:
	for i in 30:
		_stars.append({
			"pos": Vector2(randf() * 1920.0, randf() * 1080.0),
			"speed": randf_range(4.0, 14.0),
			"r": randf_range(1.0, 2.5),
			"phase": randf() * TAU,
		})

func _process(delta: float) -> void:
	for s: Dictionary in _stars:
		s["pos"] = (s["pos"] as Vector2) + Vector2(0, -(s["speed"] as float) * delta)
		if (s["pos"] as Vector2).y < -5.0:
			s["pos"] = Vector2((s["pos"] as Vector2).x, 1085.0)
	queue_redraw()

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for s: Dictionary in _stars:
		var tw := 0.5 + 0.5 * sin(t * 2.0 + (s["phase"] as float))
		var a := 0.25 + 0.5 * tw
		draw_circle(s["pos"], s["r"], Color(0.8, 0.9, 1.0, a))
