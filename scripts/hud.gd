extends CanvasLayer
## HUD：血条、击杀、时间、波次、经验条、金币、攻击模式、键位提示与游戏结束界面。
## 商店/天赋/背包等菜单面板是 HUD 下的独立子节点。

@onready var hp_bar: ProgressBar = $HPBar
@onready var kills_label: Label = $KillsLabel
@onready var time_label: Label = $TimeLabel
@onready var wave_label: Label = $WaveLabel
@onready var xp_bar: ProgressBar = $XPBar
@onready var xp_label: Label = $XPLabel
@onready var gold_label: Label = $GoldLabel
@onready var mode_label: Label = $ModeLabel
@onready var talent_hint: Label = $TalentHint
@onready var game_over_panel: ColorRect = $GameOverPanel
@onready var game_over_title: Label = $GameOverPanel/CenterBox/GameOverTitle
@onready var game_over_time_label: Label = $GameOverPanel/CenterBox/GameOverTime
@onready var game_over_difficulty: Label = $GameOverPanel/CenterBox/GameOverDifficulty
@onready var game_over_kills: Label = $GameOverPanel/CenterBox/GameOverKills
@onready var game_over_wave: Label = $GameOverPanel/CenterBox/GameOverWave
@onready var game_over_level: Label = $GameOverPanel/CenterBox/GameOverLevel
@onready var game_over_gold: Label = $GameOverPanel/CenterBox/GameOverGold

func _ready() -> void:
	# 血条/经验条填充色（深色槽已由主题统一）。
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.88, 0.32, 0.34, 1.0)
	hp_fill.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.95, 0.78, 0.3, 1.0)
	xp_fill.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	# 悬浮文字统一加黑色阴影，叠在游戏场景上可读。
	for label in [kills_label, time_label, wave_label, mode_label]:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	# 金币区：圆角半透明底框托底。
	var gold_bg := StyleBoxFlat.new()
	gold_bg.bg_color = Color(0.1, 0.1, 0.15, 0.7)
	gold_bg.set_corner_radius_all(6)
	gold_label.add_theme_stylebox_override("normal", gold_bg)

func update_hp(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current

func update_kills(kills: int) -> void:
	kills_label.text = "击杀: %d" % kills

func update_time(seconds: float) -> void:
	time_label.text = "时间: %s" % _format_time(seconds)

func update_wave(wave: int) -> void:
	wave_label.text = "第 %d 波" % wave

func update_xp(current: int, xp_max: int) -> void:
	xp_bar.max_value = xp_max
	xp_bar.value = current
	xp_label.text = "经验 %d/%d" % [current, xp_max]

func update_gold(gold: int) -> void:
	gold_label.text = "金币: %d" % gold

func set_attack_mode(mode: int) -> void:
	mode_label.text = "模式: 自动 (Tab)" if mode == 0 else "模式: 手动 (Tab)"

var _hint_tween: Tween

## 屏幕下方一行文字提示（升级发点等），显示 3 秒后淡出。
func show_talent_hint(text: String) -> void:
	talent_hint.text = text
	talent_hint.visible = true
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_interval(3.0)
	_hint_tween.tween_callback(func() -> void: talent_hint.visible = false)

## 结算界面：title 区分「游戏结束 / 本局结束」，展示本局统计。
func show_result(title: String, difficulty: String, kills: int, wave: int, level: int, gold: int, survived: float) -> void:
	game_over_title.text = title
	game_over_difficulty.text = "难度: %s" % difficulty
	game_over_kills.text = "击杀: %d" % kills
	game_over_wave.text = "到达波次: %d" % wave
	game_over_level.text = "玩家等级: %d" % level
	game_over_gold.text = "金币: %d" % gold
	game_over_time_label.text = "存活时间 %s" % _format_time(survived)
	game_over_panel.visible = true

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
