class_name TalentTreeUI
extends VBoxContainer
## 可复用的天赋树控件：多条分支列 × 每列 5 个层级按钮。
## 先 setup(tree, on_purchase)，状态变化时调用 refresh()。

var _tree: TalentTree
var _on_purchase: Callable
var _buttons: Dictionary = {}  # branch_id -> Array[Button]

func setup(tree: TalentTree, on_purchase: Callable) -> void:
	_tree = tree
	_on_purchase = on_purchase
	_build()

func _build() -> void:
	var row := HBoxContainer.new()
	for branch in _tree.branches():
		var col := VBoxContainer.new()
		var title := Label.new()
		title.text = "%s\n%s" % [branch.name, branch.desc]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.custom_minimum_size = Vector2(180, 0)
		col.add_child(title)
		var buttons: Array[Button] = []
		for t in range(int(branch.tiers)):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(180, 0)
			btn.pressed.connect(_on_purchase.bind(branch.id))
			buttons.append(btn)
			col.add_child(btn)
		_buttons[branch.id] = buttons
		row.add_child(col)
	add_child(row)

func refresh() -> void:
	if _tree == null:
		return
	var points: int = _tree.points
	for branch in _tree.branches():
		var owned: int = _tree.owned_count(branch.id)
		var buttons: Array = _buttons[branch.id]
		for t in range(buttons.size()):
			var btn: Button = buttons[t]
			if t < owned:
				btn.text = "Lv.%d ✓" % (t + 1)
				btn.disabled = true
			elif points > 0 and t == owned:
				btn.text = "Lv.%d 点亮" % (t + 1)
				btn.disabled = false
			else:
				btn.text = "Lv.%d 未解锁" % (t + 1)
				btn.disabled = true
