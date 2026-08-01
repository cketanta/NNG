extends Node2D
## 在定时波期间刷怪，每波更快更密。波次时机由 Main 通过 begin_wave()/end_wave() 控制。

signal enemy_killed(global_pos: Vector2, xp_value: int, gold_value: int)

const ENEMY_MELEE_SCENE := preload("res://scenes/enemies/enemy_melee.tscn")
const ENEMY_RANGED_SCENE := preload("res://scenes/enemies/enemy_ranged.tscn")

@export var base_interval: float = 1.5
@export var min_interval: float = 0.3
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

## 应用难度倍率：影响刷怪间隔、每只怪的属性与刷怪密度。
func set_difficulty(spawn_mult: float, hp_mult: float, attack_mult: float, density_mult := 1.0) -> void:
	_spawn_mult = spawn_mult
	_hp_mult = hp_mult
	_attack_mult = attack_mult
	_density_mult = density_mult

func begin_wave(wave: int) -> void:
	_wave = wave
	_timer = 0.0
	_active = true

func end_wave() -> void:
	_active = false

func _process(delta: float) -> void:
	if not _active:
		return
	var interval := maxf(min_interval, base_interval * _spawn_mult * pow(interval_per_wave_decay, _wave - 1))
	_timer += delta
	if _timer >= interval:
		_timer = 0.0
		spawn_batch()

func spawn_batch() -> void:
	var batch := maxi(1, int(round((1 + (_wave - 1) / 3) * _density_mult)))
	for i in batch:
		spawn_enemy()

func spawn_enemy() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var scene: PackedScene = ENEMY_MELEE_SCENE if randf() < melee_weight else ENEMY_RANGED_SCENE
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
