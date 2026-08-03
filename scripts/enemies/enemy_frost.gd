extends "res://scripts/enemies/enemy_base.gd"
## 冰霜射手：远程发射减速弹（命中玩家移速减半）。淡蓝色。

const PROJECTILE := preload("res://scenes/weapons/projectile.tscn")

@export var fire_cooldown: float = 2.4
var _t := 0.0

func _physics_process(delta: float) -> void:
	_apply_movement(direction_to_player() * speed * 0.3)
	_t += delta
	if _t >= fire_cooldown:
		_t = 0.0
		_fire()

func _fire() -> void:
	var dir := direction_to_player()
	var p := PROJECTILE.instantiate()
	p.setup(dir, 340.0, 1, false)
	p.set_slow(1)  # 命中玩家减速
	p.set_visual_type("frost")
	p.global_position = global_position
	get_tree().current_scene.add_child(p)
