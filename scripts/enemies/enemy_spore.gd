extends "res://scripts/enemies/enemy_base.gd"
## 孢子怪：死亡时爆裂，对附近玩家造成范围伤害。粉绿色。

const EXPLODE_RADIUS := 70.0

func die() -> void:
	# 爆裂：对附近玩家造成范围伤害。
	var player := get_player()
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < EXPLODE_RADIUS:
		player.take_damage(2)
	Fx.hit(global_position, get_tree(), true)
	super.die()
