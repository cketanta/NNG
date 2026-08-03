class_name DamageNumber
extends Node2D
## 上飘淡出的伤害数字：普通白 / 暴击橙黄大号 + 阴影描边。

const LIFE := 0.7

var _t := 0.0
var _text := ""
var _color := Color(1, 1, 1)
var _crit := false

func setup(text: String, crit: bool) -> void:
	_text = text
	_crit = crit
	_color = Color(1.0, 0.72, 0.25) if crit else Color(1, 1, 1)

func _process(delta: float) -> void:
	_t += delta
	position.y -= 46.0 * delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var a := clampf((LIFE - _t) / 0.25, 0.0, 1.0)
	var fsize := 24 if _crit else 17
	var font := ThemeDB.fallback_font
	# 阴影描边（下偏移 1px）。
	draw_string(font, Vector2(-42, 1), _text, HORIZONTAL_ALIGNMENT_CENTER, 84, fsize, Color(0, 0, 0, a * 0.75))
	draw_string(font, Vector2(-42, 0), _text, HORIZONTAL_ALIGNMENT_CENTER, 84, fsize,
		Color(_color.r, _color.g, _color.b, a))
