extends SceneTree
## 天赋树聚合测试：aggregate 效果（倍率连乘 / 数值累加 / flags / counts）与人物树效果。

var _failures: Array[String] = []

func _initialize() -> void:
	pass

func _process(_delta: float) -> bool:
	_test_aggregate()
	_test_berserk()
	_test_person_tree()
	_finish()
	return true

func _test_aggregate() -> void:
	var tree: TalentTree = TalentTree.new()
	# blade：范围/伤害/攻速各一点。
	tree.owned["blade"]["blade_range_1"] = true
	tree.owned["blade"]["blade_sharp_1"] = true
	tree.owned["blade"]["blade_swift_1"] = true
	var agg: Dictionary = tree.aggregate("blade")
	if absf(agg.dmg_mult - 1.1) < 0.001 and absf(agg.range_mult - 1.1) < 0.001 and absf(agg.cd_mult - 0.9) < 0.001:
		print("[OK] blade aggregate (dmg 1.1 range 1.1 cd 0.9)")
	else:
		_failures.append("blade aggregate wrong dmg=%.2f range=%.2f cd=%.2f" % [agg.dmg_mult, agg.range_mult, agg.cd_mult])
	# counts 累加：左轮弹匣 2 点 -> bullet=2。
	tree.owned["revolver"]["rev_mag_1"] = true
	tree.owned["revolver"]["rev_mag_2"] = true
	agg = tree.aggregate("revolver")
	if int(agg.counts.get("bullet", 0)) == 2:
		print("[OK] revolver mag counts accumulate (bullet=2)")
	else:
		_failures.append("revolver counts=%s" % agg.counts)

func _test_berserk() -> void:
	var tree: TalentTree = TalentTree.new()
	tree.owned["blade"]["blade_berserk"] = true
	var agg: Dictionary = tree.aggregate("blade")
	if bool(agg.flags.get("berserk", false)) and absf(agg.dmg_mult - 1.2) < 0.001 \
			and absf(agg.cd_mult - 0.8) < 0.001 and absf(agg.speed_mult - 1.3) < 0.001:
		print("[OK] berserk flags+multipliers (dmg 1.2 cd 0.8 speed 1.3)")
	else:
		_failures.append("berserk agg wrong %s" % agg)

func _test_person_tree() -> void:
	var pt: PlayerTalent = PlayerTalent.new()
	pt.points = 10
	pt.tree.owned["player"]["person_brute"] = true
	pt.tree.owned["player"]["person_crit"] = true
	pt.tree.owned["player"]["person_crit_dmg"] = true
	var fx: Dictionary = pt.effects()
	if absf(fx.dmg_mult - 1.1) < 0.001 and absf(fx.crit_chance - 15.0) < 0.001 and absf(fx.crit_dmg - 60.0) < 0.001:
		print("[OK] person effects (dmg 1.1 crit 15% crit_dmg 60%)")
	else:
		_failures.append("person effects wrong %s" % fx)
	# 互斥：点锐眼后连珠不可选。
	if pt.tree.selectable("player").has("person_extra"):
		_failures.append("extra selectable despite crit conflict")
	else:
		print("[OK] extra locked by crit conflict")

func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] talent tree test passed")
		quit(0)
	else:
		for failure in _failures:
			print("[FAIL] " + failure)
		quit(1)
