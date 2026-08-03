extends Area2D
## 回旋镖弹幕：沿瞄准方向飞出，达到射程后折返回玩家，往返路径上命中多个敌人。
## 天赋：贯穿（每趟命中上限+1）/ 二段往返（多趟）/ 绞杀旋涡（折返时旋转加速、命中上限翻倍）。

const LAYER_FRIENDLY := 4  # 玩家弹幕所在碰撞层（1 基）
const LAYER_ENEMY := 3     # 敌人所在碰撞层（1 基）
const MAX_FRIENDLY := 260  # 友好弹幕总量上限（性能保护）

var _dir := Vector2.RIGHT
var _speed := 460.0
var _damage := 2
var _out_distance := 300.0
var _max_trips := 1
var _pierce := 0
var _whirlwind := false
var _whirl_tier := 0
var _magnet := 0
var _armor_break := false
var _crit_chance := 0.0
var _crit_dmg := 0.0
var _lifesteal := 0.0

var _traveled := 0.0
var _returning := false
var _trip := 0          # 已完成趟数（0 起始）
var _hit_bodies := {}   # 本趟已命中敌人（折返后清空，可再次命中）
var _hit_count := 0     # 本趟命中数（受命中上限限制）
var _hit_limit := 1     # 本趟命中上限
var _spin := 0.0        # 旋转角（视觉）

func setup(dir: Vector2, speed: float, damage: int, out_distance: float, max_trips: int,
		pierce: int, whirlwind: bool, crit_chance: float, crit_dmg: float, lifesteal: float,
		whirl_tier: int = 0, magnet: int = 0, armor_break: bool = false) -> void:
	_dir = dir.normalized()
	_speed = speed
	_damage = damage
	_out_distance = maxf(out_distance, 50.0)
	_max_trips = maxi(max_trips, 1)
	_pierce = maxi(pierce, 0)
	_whirlwind = whirlwind
	_whirl_tier = maxi(whirl_tier, 0)
	_magnet = maxi(magnet, 0)
	_armor_break = armor_break
	_crit_chance = maxf(crit_chance, 0.0)
	_crit_dmg = maxf(crit_dmg, 0.0)
	_lifesteal = maxf(lifesteal, 0.0)
	_update_hit_limit()

func _ready() -> void:
	# 弹幕总量性能保护：友好弹超过上限立即自毁。
	if get_tree().get_nodes_in_group("friendly_projectiles").size() >= MAX_FRIENDLY:
		queue_free()
		return
	collision_layer = 1 << (LAYER_FRIENDLY - 1)
	collision_mask = 1 << (LAYER_ENEMY - 1)
	body_entered.connect(_on_body_entered)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	add_to_group("friendly_projectiles")
	_update_hit_limit()

## 每趟可命中敌人上限：基础 1 + 穿透数；绞杀旋涡时翻倍（折返多段伤害）。
func _update_hit_limit() -> void:
	_hit_limit = 1 + _pierce
	if _whirlwind:
		_hit_limit *= 2
	_hit_limit += _whirl_tier  # 旋涡强化：额外命中数

func _physics_process(delta: float) -> void:
	# 旋转：旋涡状态下折返更快。
	_spin += delta * (14.0 if _whirlwind and _returning else 7.0)
	rotation = _spin
	if not _returning:
		# 飞出阶段：沿瞄准方向前进，达到射程后折返。
		_traveled += _speed * delta
		global_position += _dir * _speed * delta
		if _traveled >= _out_distance:
			_returning = true
	else:
		# 折返阶段：朝玩家飞回；到达后若还有趟数则再次飞出（二段往返）。
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player):
			queue_free()
			return
		var to_player := player.global_position - global_position
		if to_player.length() < 24.0:
			_trip += 1
			if _trip >= _max_trips:
				queue_free()  # 最后一趟到达玩家，收回
				return
			global_position = player.global_position
			_traveled = 0.0
			_returning = false
			_hit_bodies.clear()
			_hit_count = 0
		else:
			global_position = global_position.move_toward(player.global_position, _speed * delta)
	# 磁吸风暴：飞行时缓慢吸附附近敌人（拖拽）。
	if _magnet > 0:
		for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 110.0:
				enemy.set_pull(global_position, 60.0 + 30.0 * _magnet)

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	if _hit_bodies.has(body):
		return  # 本趟已命中过该敌人，不重复
	_hit_bodies[body] = true
	if _hit_count >= _hit_limit:
		return  # 本趟命中数已达上限
	_hit_count += 1
	# 暴击：命中时按暴击率 roll。
	var crit_hit := false
	if _crit_chance > 0.0 and randf() * 100.0 < _crit_chance:
		crit_hit = true
	var real_dmg := _damage
	if crit_hit:
		real_dmg = maxi(1, int(round(_damage * (1.0 + _crit_dmg / 100.0))))
	# 特效：命中爆闪 + 伤害数字；暴击屏幕震动。
	Fx.hit(global_position, get_tree(), crit_hit)
	Fx.number(global_position, get_tree(), str(real_dmg), crit_hit)
	if crit_hit:
		Fx.shake(get_tree(), 5.0)
	body.take_damage(real_dmg)
	# 破甲：命中削弱敌人防御（受击增伤）。
	if _armor_break and body.has_method("add_vulnerable"):
		body.add_vulnerable(1)
	# 吸血：命中回复一定比例血量。
	if _lifesteal > 0.0:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("heal"):
			player.heal(maxi(1, int(round(real_dmg * _lifesteal / 100.0))))

func _draw() -> void:
	# 占位：绿色回旋镖（双弯翼），旋转由节点 rotation 控制。
	draw_colored_polygon(PackedVector2Array([
		Vector2(15, 0), Vector2(6, -9), Vector2(-5, -2), Vector2(3, -6),
		Vector2(-11, 7), Vector2(-2, 15), Vector2(7, 5), Vector2(-1, 9),
	]), Color(0.35, 0.75, 0.4))
	draw_circle(Vector2.ZERO, 3.0, Color(0.85, 0.95, 0.7))
