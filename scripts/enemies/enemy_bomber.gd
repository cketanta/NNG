extends "res://scripts/enemies/enemy_base.gd"
## 爆炸怪：接近玩家进入引信距离后停止追击并自爆，对玩家造成范围伤害。紫色视觉。

const FUSE_DISTANCE := 55.0   # 进入该距离启动引信
const EXPLODE_RADIUS := 70.0  # 爆炸伤害范围
const FUSE_TIME := 0.6        # 引信倒计时（秒）

@export var explode_damage: int = 3

var _fusing := false
var _fuse_timer := 0.0

func _physics_process(delta: float) -> void:
	if _fusing:
		_fuse_timer += delta
		if _fuse_timer >= FUSE_TIME:
			_explode()
		return
	var player := get_player()
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= FUSE_DISTANCE:
		_fusing = true
		_fuse_timer = 0.0
		Fx.hit(global_position, get_tree(), false)  # 引信启动提示
		return
	_apply_movement(direction_to_player() * speed)

func _explode() -> void:
	var player := get_player()
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < EXPLODE_RADIUS:
		player.take_damage(explode_damage)
	Fx.hit(global_position, get_tree(), true)
	die()  # 自爆死亡（正常掉落）
