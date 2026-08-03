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
@onready var game_over_panel: Control = $GameOverPanel
@onready var game_over_title: Label = $GameOverPanel/CenterBox/GameOverTitle
@onready var game_over_time_label: Label = $GameOverPanel/CenterBox/GameOverTime
@onready var game_over_difficulty: Label = $GameOverPanel/CenterBox/GameOverDifficulty
@onready var game_over_kills: Label = $GameOverPanel/CenterBox/GameOverKills
@onready var game_over_wave: Label = $GameOverPanel/CenterBox/GameOverWave
@onready var game_over_level: Label = $GameOverPanel/CenterBox/GameOverLevel
@onready var game_over_gold: Label = $GameOverPanel/CenterBox/GameOverGold

var _hp_fill: StyleBoxTexture  # 血条填充样式（低血量脉动用）
var _hp_pulse: Tween           # 低血量闪烁 tween

func _ready() -> void:
	# 血条/经验条：渐变纹理填充 + 凹槽背景。
	_hp_fill = StyleBoxTexture.new()
	_hp_fill.texture = preload("res://assets/ui/hp_fill.svg")
	_hp_fill.set_texture_margin_all(8)
	hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	var hp_bg := StyleBoxTexture.new()
	hp_bg.texture = preload("res://assets/ui/hp_bg.svg")
	hp_bg.set_texture_margin_all(8)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	var xp_fill := StyleBoxTexture.new()
	xp_fill.texture = preload("res://assets/ui/xp_fill.svg")
	xp_fill.set_texture_margin_all(8)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	var xp_bg := StyleBoxTexture.new()
	xp_bg.texture = preload("res://assets/ui/xp_bg.svg")
	xp_bg.set_texture_margin_all(8)
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	# 状态栏浮层背景：左上角半透明面板（放在状态元素下层）。
	var status_bg := PanelContainer.new()
	status_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_bg.position = Vector2(12, 12)
	status_bg.custom_minimum_size = Vector2(540, 400)
	status_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_bg.add_theme_stylebox_override("panel", _status_bg_style())
	add_child(status_bg)
	move_child(status_bg, 0)  # 放到最底层，不遮挡状态元素
	# 悬浮文字统一加黑色阴影，叠在游戏场景上可读。
	for label in [kills_label, time_label, wave_label, mode_label]:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	# 金币区：与悬浮文字一致加阴影（Label 无 normal stylebox，旧底框 override 无效）。
	gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	gold_label.add_theme_constant_override("shadow_offset_x", 1)
	gold_label.add_theme_constant_override("shadow_offset_y", 1)

## 状态栏浮层半透明背景样式（panel_bg 贴图压暗）。
func _status_bg_style() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = preload("res://assets/ui/panel_bg.svg")
	sb.set_texture_margin_all(16.0)
	sb.modulate_color = Color(0.6, 0.66, 0.78, 0.85)
	return sb

func update_hp(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current
	_set_low_hp(current < max_hp * 0.3)

## 低血量警示：hp < 30% 时血条填充泛白脉动闪烁，恢复后停止。
func _set_low_hp(low: bool) -> void:
	if low and _hp_pulse == null:
		_hp_pulse = create_tween().set_loops()
		_hp_pulse.tween_method(_set_hp_pulse_mod, 0.85, 1.4, 0.45)
		_hp_pulse.tween_method(_set_hp_pulse_mod, 1.4, 0.85, 0.45)
	elif not low and _hp_pulse != null:
		_hp_pulse.kill()
		_hp_pulse = null
		_hp_fill.modulate_color = Color(1, 1, 1, 1)

func _set_hp_pulse_mod(v: float) -> void:
	_hp_fill.modulate_color = Color(v, v, v, 1)

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
	_play_result_intro()

## 结算页入场动画：面板淡入 + 标题缩放回落 + 统计逐条浮现。
func _play_result_intro() -> void:
	game_over_panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.3)
	var title_tw: Tween = create_tween()
	title_tw.tween_property(game_over_title, "scale", Vector2.ONE, 0.5).from(Vector2(1.25, 1.25))
	var labels := [game_over_time_label, game_over_difficulty, game_over_kills,
		game_over_wave, game_over_level, game_over_gold]
	var delay := 0.0
	for l in labels:
		l.modulate.a = 0.0
		var tw2: Tween = create_tween().set_delay(delay)
		tw2.tween_property(l, "modulate:a", 1.0, 0.25)
		delay += 0.12

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
