extends "res://scripts/enemies/enemy_base.gd"
## 近战敌人：直线冲向玩家，靠接触造成伤害。

func _physics_process(_delta: float) -> void:
	_apply_movement(direction_to_player() * speed)
