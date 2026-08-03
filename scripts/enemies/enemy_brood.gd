extends "res://scripts/enemies/enemy_base.gd"
## 孵化怪：死亡时分裂成 2 个小型近战怪（小怪不额外掉落）。橙黄。

const MINI_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")

func die() -> void:
	for i in 2:
		var mini := MINI_SCENE.instantiate()
		mini.global_position = global_position + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))
		mini.xp_value = 0
		mini.gold_value = 0
		mini.max_hp = maxi(mini.max_hp, 1)
		mini.scale = Vector2(0.7, 0.7)
		get_tree().current_scene.add_child(mini)
		mini.died.connect(_on_mini_died)
	super.die()

func _on_mini_died(_global_pos: Vector2, _xp: int, _gold: int) -> void:
	pass  # 分裂小怪不额外掉落/不计击杀
