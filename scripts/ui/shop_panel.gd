class_name ShopPanel
extends CenterContainer
## 每波结束的空商店（游戏暂停）：武器升级已删除、道具系统暂停使用（框架保留）。
## 只显示金币与玩家状态 + 「开始下一波」按钮。

var _main: Main
var _gold_label: Label
var _stats_label: Label

func setup(main: Main) -> void:
	_main = main
	_build_ui()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	add_child(panel)

	vbox.add_child(_make_title("商店"))
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gold_label)

	var hint := Label.new()
	hint.text = "商店暂时休业（武器升级与道具系统调整中）"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_stats_label)

	var close := Button.new()
	close.text = "开始下一波"
	close.pressed.connect(_on_close_pressed)
	vbox.add_child(close)

func refresh() -> void:
	_gold_label.text = "金币: %d" % _main.player.gold
	_stats_label.text = _main.player_stats_text()

func _on_close_pressed() -> void:
	_main.close_shop()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# 标记已处理，阻断同一事件继续传给 main（shop 状态下 main 不弹暂停，保持统一约定）。
		get_viewport().set_input_as_handled()
		_main.close_shop()

func _make_title(text: String) -> Label:
	return UiStyle.big_title(text)
