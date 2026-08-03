class_name HitFx
extends Node2D
## 命中爆闪：中心圆 + 8 放射短线，0.18s 衰减消失。纯 _draw 代码粒子，无物理依赖。

const LIFE := 0.18

var _t := 0.0
var _color := Color(1, 1, 1)

func setup(c: Color) -> void:
	_color = c

func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p := _t / LIFE  # 0 → 1
	var a := 0.75 * (1.0 - p)
	var r := 6.0 + 14.0 * p
	draw_circle(Vector2.ZERO, r * 0.5, Color(_color.r, _color.g, _color.b, a * 0.4))
	for i in 8:
		var ang := TAU * float(i) / 8.0 + p * 0.8
		var dir := Vector2.from_angle(ang)
		draw_line(dir * (r * 0.3), dir * (r + 5.0), Color(_color.r, _color.g, _color.b, a), 2.0)
