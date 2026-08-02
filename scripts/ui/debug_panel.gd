class_name DebugPanel
extends CenterContainer
## 测试模式调试面板（L 键唤出，游戏暂停）：
## 可调 当前波数 / 金币 / 角色等级 / 角色属性（移速/防御/血量/幸运）/ 武器等级，
## 道具区可无限 +1 获取所有道具。整体包 ScrollContainer 纵向滚动。

var _main: Main
var _wave_spin: SpinBox
var _wave_time_spin: SpinBox
var _gold_spin: SpinBox
var _level_spin: SpinBox
var _attr_spins: Dictionary = {}   # 属性名 -> SpinBox（speed/defense/max_hp/luck）
var _item_spins: Dictionary = {}  # 道具 id -> 数量 SpinBox（可直接输入目标数量）
var _updating := false  # refresh 设值期间防 value_changed 递归

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	# 整体滚动容器：内容超高时纵向滑动。
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 480)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var panel := PanelContainer.new()
	scroll.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	vbox.add_child(UiStyle.big_title("调试面板"))

	# --- 基础数值：波数 / 金币 / 等级 ---
	_wave_spin = _new_spin(1, 999, 1)
	vbox.add_child(_make_adjust_row("当前波数", _wave_spin, _apply_wave.bind(_wave_spin)))
	_wave_time_spin = _new_spin(1.0, 120.0, 1.0)
	vbox.add_child(_make_adjust_row("每波时间(秒)", _wave_time_spin, _apply_wave_time.bind(_wave_time_spin)))
	_gold_spin = _new_spin(0, 999999, 1)
	vbox.add_child(_make_adjust_row("金币", _gold_spin, _apply_gold.bind(_gold_spin)))
	_level_spin = _new_spin(1, 999, 1)
	vbox.add_child(_make_adjust_row("角色等级", _level_spin, _apply_level.bind(_level_spin)))

	# --- 角色属性 ---
	vbox.add_child(UiStyle.title_bar("角色属性"))
	var attr_specs := {
		"speed": { "label": "移速", "min": 0.0, "max": 2000.0, "step": 10.0 },
		"defense": { "label": "防御", "min": 0.0, "max": 100.0, "step": 1.0 },
		"max_hp": { "label": "血量上限", "min": 1.0, "max": 9999.0, "step": 10.0 },
		"luck": { "label": "幸运", "min": 0.0, "max": 100.0, "step": 1.0 },
	}
	for kind in attr_specs:
		var spec: Dictionary = attr_specs[kind]
		var spin := _new_spin(spec["min"], spec["max"], spec["step"])
		_attr_spins[kind] = spin
		vbox.add_child(_make_adjust_row(spec["label"], spin, _apply_attr.bind(kind, spin)))

	# --- 攻击方式切换 ---
	vbox.add_child(UiStyle.title_bar("攻击方式（测试切换）"))
	for attack_id in _main.attack_ids():
		var attack_btn := Button.new()
		attack_btn.text = "切换为 " + _main.attack_name(attack_id)
		attack_btn.pressed.connect(_apply_attack.bind(attack_id))
		vbox.add_child(attack_btn)

	# --- 道具（无限获取） ---
	vbox.add_child(UiStyle.title_bar("道具（点击 +1 无限获取）"))
	for item_id in ItemDefs.all_ids():
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "[%s] %s" % [ItemDefs.rarity_name(item_id), ItemDefs.name(item_id)]
		name_label.add_theme_color_override("font_color", ItemDefs.rarity_color(item_id))
		name_label.custom_minimum_size = Vector2(220, 0)
		row.add_child(name_label)
		# 数量直接输入：改值即应用（提交数字或点箭头）。
		var spin := _new_spin(0, 9999, 1)
		spin.custom_minimum_size = Vector2(90, 0)
		spin.value_changed.connect(_on_item_value_changed.bind(item_id))
		row.add_child(spin)
		_item_spins[item_id] = spin
		var remove := Button.new()
		remove.text = "-1"
		remove.custom_minimum_size = Vector2(50, 0)
		remove.pressed.connect(_remove_item.bind(item_id))
		row.add_child(remove)
		var give := Button.new()
		give.text = "+1"
		give.custom_minimum_size = Vector2(50, 0)
		give.pressed.connect(_give_item.bind(item_id))
		row.add_child(give)
		vbox.add_child(row)

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func refresh() -> void:
	_wave_spin.value = _main.wave_number
	_wave_time_spin.value = _main.wave_duration
	_gold_spin.value = _main.player.gold
	_level_spin.value = _main.player.level
	_attr_spins["speed"].value = _main.player.speed
	_attr_spins["defense"].value = _main.player.defense
	_attr_spins["max_hp"].value = _main.player.max_hp
	_attr_spins["luck"].value = _main.player.luck
	_updating = true
	for item_id in _item_spins:
		_item_spins[item_id].value = _main.player.item_counts.get(item_id, 0)
	_updating = false

func _new_spin(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(120, 0)
	return spin

func _make_adjust_row(label_text: String, spin: SpinBox, on_apply: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(90, 0)
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)
	row.add_child(spin)
	var apply := Button.new()
	apply.text = "应用"
	apply.pressed.connect(on_apply)
	row.add_child(apply)
	return row

# --- 各应用回调 ---

func _apply_wave(spin: SpinBox) -> void:
	_main.set_wave_number(int(spin.value))

func _apply_wave_time(spin: SpinBox) -> void:
	_main.set_wave_duration(float(spin.value))

func _apply_gold(spin: SpinBox) -> void:
	_main.player.set_gold(int(spin.value))

func _apply_level(spin: SpinBox) -> void:
	_main.player.set_level(int(spin.value))

func _apply_attr(kind: String, spin: SpinBox) -> void:
	match kind:
		"speed":
			_main.player.set_speed(float(spin.value))
		"defense":
			_main.player.set_defense(int(spin.value))
		"max_hp":
			_main.player.set_max_hp(int(spin.value))
		"luck":
			_main.player.set_luck(int(spin.value))

func _apply_attack(attack_id: String) -> void:
	_main.debug_set_attack(attack_id)
	refresh()

func _give_item(item_id: String) -> void:
	_main.debug_give_item(item_id)

func _remove_item(item_id: String) -> void:
	_main.debug_remove_item(item_id)

## 数量 SpinBox 直接输入：把该道具数量设为目标值（refresh 设值时跳过，防递归）。
func _on_item_value_changed(value: float, item_id: String) -> void:
	if _updating:
		return
	_main.debug_set_item_count(item_id, int(value))

func _on_close_pressed() -> void:
	_main.close_debug()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# 标记已处理，阻断同一事件继续传给 main，防止 main 随后弹暂停。
		get_viewport().set_input_as_handled()
		_main.close_debug()
