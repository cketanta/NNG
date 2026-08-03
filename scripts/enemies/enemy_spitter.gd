extends "res://scripts/enemies/enemy_base.gd"
## 喷吐怪：远程，周期喷射 3 向弹幕，制造弹幕压力。绿色。

const PROJECTILE := preload("res://scenes/weapons/projectile.tscn")

@export var fire_cooldown: float = 2.2
var _t := 0.0

func _physics_process(delta: float) -> void:
	_apply_movement(direction_to_player() * speed * 0.3)
	_t += delta
	if _t >= fire_cooldown:
		_t = 0.0
		_fire_fan()

func _fire_fan() -> void:
	var dir := direction_to_player()
	for i in 3:
		var off := (float(i) - 1.0) * deg_to_rad(16.0)
		var p := PROJECTILE.instantiate()
		p.setup(dir.rotated(off), 300.0, 1, false)
		p.global_position = global_position
		get_tree().current_scene.add_child(p)
