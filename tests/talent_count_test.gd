extends SceneTree
## 天赋节点数校验：每把武器天赋树 ≥32 节点（v1.6.1 删减繁复分支后）；人物树保持 22。

var _failures: Array[String] = []

func _process(_delta: float) -> bool:
	var trees: Dictionary = TalentTree.TREES
	for tree_id in ["blade", "revolver", "whip", "staff", "splitter", "black_hole_gun", "boomerang"]:
		var count: int = (trees.get(tree_id, []) as Array).size()
		if count >= 32:
			print("[OK] %s: %d nodes" % [tree_id, count])
		else:
			_failures.append("%s nodes=%d (<32)" % [tree_id, count])
	var player_count: int = (trees.get("player", []) as Array).size()
	if player_count == 22:
		print("[OK] player tree: %d nodes" % player_count)
	else:
		_failures.append("player tree nodes=%d" % player_count)
	_finish()
	return true

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] talent count test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
