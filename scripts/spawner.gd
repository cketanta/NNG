extends Node2D
## 在定时波期间刷怪，每波更快更密。波次时机由 Main 通过 begin_wave()/end_wave() 控制。

signal enemy_killed(global_pos: Vector2, xp_value: int, gold_value: int)

const ENEMY_MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")
const ENEMY_RANGED_SCENE := preload("res://scenes/enemies/enemy_ranged.tscn")
const ENEMY_BOMBER_SCENE := preload("res://scenes/enemies/enemy_bomber.tscn")
const ENEMY_CHASER_SCENE := preload("res://scenes/enemies/enemy_chaser.tscn")
const ENEMY_SPITTER_SCENE := preload("res://scenes/enemies/enemy_spitter.tscn")
const ENEMY_BROOD_SCENE := preload("res://scenes/enemies/enemy_brood.tscn")
const ENEMY_SPORE_SCENE := preload("res://scenes/enemies/enemy_spore.tscn")
const ENEMY_FROST_SCENE := preload("res://scenes/enemies/enemy_frost.tscn")
const ENEMY_ELITE_SCENE := preload("res://scenes/enemies/enemy_elite.tscn")
const ENEMY_BOSS_SCENE := preload("res://scenes/enemies/enemy_boss.tscn")

@export var base_interval: float = 1.35
@export var min_interval: float = 0.25
@export var spawn_radius_min: float = 500.0
@export var spawn_radius_max: float = 700.0
@export var melee_weight: float = 0.7
@export var interval_per_wave_decay: float = 0.94

var _active := false
var _wave := 0
var _timer := 0.0
var _spawn_mult := 1.0
var _hp_mult := 1.0
var _attack_mult := 1.0
var _density_mult := 1.0
var _rate_mult := 1.0  # 刷怪效率倍率（咒戒 ×2，间隔除以该值）

## 应用难度倍率：影响刷怪间隔、每只怪的属性与刷怪密度。
func set_difficulty(spawn_mult: float, hp_mult: float, attack_mult: float, density_mult := 1.0) -> void:
	_spawn_mult = spawn_mult
	_hp_mult = hp_mult
	_attack_mult = attack_mult
	_density_mult = density_mult

## 刷怪效率倍率（>1 刷得更快）；咒戒购买时设为 2.0。
func set_spawn_rate_mult(mult: float) -> void:
	_rate_mult = maxf(mult, 0.1)

var _boss_kind := 0   # BOSS 类型轮换索引（0-6 对应 7 种 BOSS）
var _elite_kind := 0  # 独立精英类型轮换索引（0-4 对应 5 种精英）

func begin_wave(wave: int) -> void:
	_wave = wave
	_timer = 0.0
	_active = true
	if wave % 5 == 0:
		spawn_boss()  # 每 5 波生成一个 BOSS

## 生成 BOSS（每 5 波一次，类型轮换）。
func spawn_boss() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var boss := ENEMY_BOSS_SCENE.instantiate()
	boss.setup(_boss_kind, _wave)
	_boss_kind = (_boss_kind + 1) % 7  # 7 种 BOSS 轮换
	boss.apply_difficulty(_hp_mult, _attack_mult)
	var angle := randf() * TAU
	boss.global_position = player.global_position + Vector2.from_angle(angle) * 500.0
	add_child(boss)
	boss.died.connect(_on_enemy_died)

## 生成独立精英（5 种轮换：狂战士/死灵法师/巨盾者/刺客/毒巫医）。
func _spawn_elite() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var elite := ENEMY_ELITE_SCENE.instantiate()
	elite.setup(_elite_kind, _wave)
	_elite_kind = (_elite_kind + 1) % 5
	elite.apply_difficulty(_hp_mult, _attack_mult)
	var angle := randf() * TAU
	elite.global_position = player.global_position + Vector2.from_angle(angle) * randf_range(spawn_radius_min, spawn_radius_max)
	add_child(elite)
	elite.died.connect(_on_enemy_died)

func end_wave() -> void:
	_active = false

func _process(delta: float) -> void:
	if not _active:
		return
	var interval := maxf(min_interval, base_interval * _spawn_mult * pow(interval_per_wave_decay, _wave - 1) / _rate_mult)
	_timer += delta
	if _timer >= interval:
		_timer = 0.0
		spawn_batch()

func spawn_batch() -> void:
	var batch := maxi(1, int(round((1 + (_wave - 1) / 2.5) * _density_mult)))
	for i in batch:
		spawn_enemy()

func spawn_enemy() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	# 独立精英：第 3 波起概率出现（5 种专属机制，替代旧普通怪放大版）。
	if _wave >= 3 and randf() < minf(0.05 + 0.012 * _wave, 0.22):
		_spawn_elite()
		return
	# 敌人类别权重（8 种小怪）：爆炸10% / 冲锋12% / 孵化5% / 喷吐8% / 孢子8% / 冰霜6% / 近战 / 其余远程。
	var r := randf()
	var scene: PackedScene = ENEMY_RANGED_SCENE
	if r < 0.10:
		scene = ENEMY_BOMBER_SCENE
	elif r < 0.10 + 0.12:
		scene = ENEMY_CHASER_SCENE
	elif r < 0.10 + 0.12 + 0.05:
		scene = ENEMY_BROOD_SCENE
	elif r < 0.10 + 0.12 + 0.05 + 0.08:
		scene = ENEMY_SPITTER_SCENE
	elif r < 0.10 + 0.12 + 0.05 + 0.08 + 0.08:
		scene = ENEMY_SPORE_SCENE
	elif r < 0.10 + 0.12 + 0.05 + 0.08 + 0.08 + 0.06:
		scene = ENEMY_FROST_SCENE
	elif r < 0.10 + 0.12 + 0.05 + 0.08 + 0.08 + 0.06 + melee_weight * 0.4:
		scene = ENEMY_MELEE_SCENE
	var enemy := scene.instantiate()
	enemy.apply_wave_scale(_wave)
	enemy.apply_difficulty(_hp_mult, _attack_mult)
	var angle := randf() * TAU
	var radius := randf_range(spawn_radius_min, spawn_radius_max)
	enemy.global_position = player.global_position + Vector2.from_angle(angle) * radius
	add_child(enemy)
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(global_pos: Vector2, xp_value: int, gold_value: int) -> void:
	enemy_killed.emit(global_pos, xp_value, gold_value)
