class_name DeathFx
extends Node2D
## 死亡粒子：N 个随机方向飘散点，衰减消失。纯 _draw 代码粒子。

const LIFE := 0.6

var _t := 0.0
var _parts: Array[Dictionary] = []  # {pos, vel, color, life}

func setup(color: Color, count := 14) -> void:
	for i in count:
		var ang := randf() * TAU
		var spd := randf_range(40.0, 150.0)
		_parts.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(ang) * spd,
			"color": color.lightened(randf() * 0.4),
			"life": randf_range(0.3, LIFE),
		})

func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	for p: Dictionary in _parts:
		p["vel"] = (p["vel"] as Vector2) * pow(0.9, delta * 60.0)
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["life"] = (p["life"] as float) - delta
	queue_redraw()

func _draw() -> void:
	for p: Dictionary in _parts:
		if (p["life"] as float) > 0.0:
			var a := minf((p["life"] as float) * 3.0, 1.0)
			var c: Color = p["color"]
			draw_circle(p["pos"], 3.0, Color(c.r, c.g, c.b, a))
