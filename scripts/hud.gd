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
@onready var game_over_panel: ColorRect = $GameOverPanel
@onready var game_over_time_label: Label = $GameOverPanel/CenterBox/GameOverTime

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

func show_game_over(survived: float) -> void:
	game_over_panel.visible = true
	game_over_time_label.text = "存活时间 %s" % _format_time(survived)

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
