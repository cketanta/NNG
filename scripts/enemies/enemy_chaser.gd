extends "res://scripts/enemies/enemy_base.gd"
## 冲锋怪：高速低血量，接触伤害高，逼迫走位。蓝色。

func _physics_process(_delta: float) -> void:
	_apply_movement(direction_to_player() * speed)
