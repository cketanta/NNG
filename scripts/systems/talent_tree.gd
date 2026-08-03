class_name TalentTree
extends RefCounted
## 天赋树数据（效果驱动）。每把武器一棵树（tree_id=武器 id），人物天赋一棵树（tree_id="player"）。
## 每个天赋：{ id, name, desc, prereq(前置天赋 id，空串=直接可点), conflict(互斥天赋 id，空串=无), effects }。
## effects 声明该天赋的数值效果，键约定：
##   - 倍率键（相乘，默认 1.0）：dmg_mult / cd_mult / range_mult / speed_mult
##   - 数值键（相加，默认 0）：crit_chance / crit_dmg / lifesteal / dodge / max_hp / defense / xp_gain / gold_gain
##   - "flags": {} 布尔开关；"counts": {} 数量（聚合时累加）
## aggregate(tree_id) 把一棵树所有已点效果聚合为统一字典，攻击/人物脚本据此计算终值。

const TREES := {
	# ============ 短刃（近战连击，23 节点） ============
	"blade": [
		{ "id": "blade_range_1", "name": "范围扩大1", "desc": "攻击范围扩大10%", "prereq": "", "conflict": "", "effects": { "range_mult": 1.1 } },
		{ "id": "blade_range_2", "name": "范围扩大2", "desc": "攻击范围扩大20%", "prereq": "blade_range_1", "conflict": "", "effects": { "range_mult": 1.2 } },
		{ "id": "blade_range_3", "name": "范围扩大3", "desc": "攻击范围扩大20%", "prereq": "blade_range_2", "conflict": "", "effects": { "range_mult": 1.2 } },
		{ "id": "blade_range_4", "name": "范围扩大4", "desc": "攻击范围扩大20%", "prereq": "blade_range_3", "conflict": "", "effects": { "range_mult": 1.2 } },
		{ "id": "blade_sharp_1", "name": "利刃出鞘1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "blade_sharp_2", "name": "利刃出鞘2", "desc": "攻击力加10%", "prereq": "blade_sharp_1", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "blade_sharp_3", "name": "利刃出鞘3", "desc": "攻击力加10%", "prereq": "blade_sharp_2", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "blade_sharp_4", "name": "利刃出鞘4", "desc": "攻击力加10%", "prereq": "blade_sharp_3", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "blade_swift_1", "name": "拔刀术1", "desc": "攻速加10%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "blade_swift_2", "name": "拔刀术2", "desc": "攻速加10%", "prereq": "blade_swift_1", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "blade_swift_3", "name": "拔刀术3", "desc": "攻速加10%", "prereq": "blade_swift_2", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "blade_air_blade", "name": "气刃斩", "desc": "攻击额外发射一枚弧形气刃（挥砍角度内均匀分布），伤害为挥砍的80%", "prereq": "", "conflict": "blade_berserk", "effects": { "counts": { "air_blade": 1 } } },
		{ "id": "blade_air_1", "name": "气刃专精1", "desc": "发射的气刃数量加1", "prereq": "blade_air_blade", "conflict": "", "effects": { "counts": { "air_blade": 1 } } },
		{ "id": "blade_air_2", "name": "气刃专精2", "desc": "发射的气刃数量加1", "prereq": "blade_air_1", "conflict": "", "effects": { "counts": { "air_blade": 1 } } },
		{ "id": "blade_air_3", "name": "气刃专精3", "desc": "发射的气刃数量加1", "prereq": "blade_air_2", "conflict": "", "effects": { "counts": { "air_blade": 1 } } },
		{ "id": "blade_air_4", "name": "气刃专精4", "desc": "发射的气刃数量加1", "prereq": "blade_air_3", "conflict": "", "effects": { "counts": { "air_blade": 1 } } },
		{ "id": "blade_grand_slash", "name": "气刃大回旋", "desc": "挥砍额外产生一个环形气刃波，造成二倍于挥砍的伤害", "prereq": "blade_air_4", "conflict": "", "effects": { "flags": { "grand_slash": true } } },
		{ "id": "blade_berserk", "name": "狂战", "desc": "移速加30%，挥砍伤害加20%，攻速加20%，体型变大50%", "prereq": "", "conflict": "blade_air_blade", "effects": { "dmg_mult": 1.2, "cd_mult": 0.8, "speed_mult": 1.3, "flags": { "berserk": true } } },
		{ "id": "blade_dual", "name": "双刀流", "desc": "快速产生两次挥砍", "prereq": "blade_berserk", "conflict": "", "effects": { "flags": { "combo_2": true } } },
		{ "id": "blade_triple", "name": "三刀流", "desc": "快速产生三次挥砍", "prereq": "blade_dual", "conflict": "", "effects": { "flags": { "combo_3": true } } },
		{ "id": "blade_quad", "name": "四刀流", "desc": "快速产生四次挥砍", "prereq": "blade_triple", "conflict": "", "effects": { "flags": { "combo_4": true } } },
		{ "id": "blade_maim", "name": "致残", "desc": "攻击到的敌人获得5秒流血效果（最多叠加30层），期间受到攻击时额外受到流血层数点伤害", "prereq": "blade_berserk", "conflict": "", "effects": { "flags": { "bleed": true }, "counts": { "bleed_max": 30 } } },
		{ "id": "blade_grief", "name": "郁色创伤", "desc": "流血效果最高可叠加至50层", "prereq": "blade_maim", "conflict": "", "effects": { "counts": { "bleed_max": 20 } } },
	],
	# ============ 左轮手枪（远程连射，15 节点） ============
	"revolver": [
		{ "id": "rev_bullet_1", "name": "弹头改良1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "rev_bullet_2", "name": "弹头改良2", "desc": "攻击力加10%", "prereq": "rev_bullet_1", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "rev_bullet_3", "name": "弹头改良3", "desc": "攻击力加10%", "prereq": "rev_bullet_2", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "rev_bullet_4", "name": "弹头改良4", "desc": "攻击力加10%", "prereq": "rev_bullet_3", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "rev_mag_1", "name": "弹匣扩容1", "desc": "额外连射一发子弹", "prereq": "", "conflict": "", "effects": { "counts": { "bullet": 1 } } },
		{ "id": "rev_mag_2", "name": "弹匣扩容2", "desc": "额外连射一发子弹", "prereq": "rev_mag_1", "conflict": "", "effects": { "counts": { "bullet": 1 } } },
		{ "id": "rev_mag_3", "name": "弹匣扩容3", "desc": "额外连射一发子弹", "prereq": "rev_mag_2", "conflict": "", "effects": { "counts": { "bullet": 1 } } },
		{ "id": "rev_mag_4", "name": "弹匣扩容4", "desc": "额外连射一发子弹", "prereq": "rev_mag_3", "conflict": "", "effects": { "counts": { "bullet": 1 } } },
		{ "id": "rev_quick_1", "name": "快枪手1", "desc": "攻速加10%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "rev_quick_2", "name": "快枪手2", "desc": "攻速加10%", "prereq": "rev_quick_1", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "rev_quick_3", "name": "快枪手3", "desc": "攻速加10%", "prereq": "rev_quick_2", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "rev_quick_4", "name": "快枪手4", "desc": "攻速加10%", "prereq": "rev_quick_3", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "rev_spinner", "name": "转盘枪手", "desc": "右键特殊攻击：扔出手枪到鼠标右键位置，手枪旋转攻击一周（子弹密度由攻速决定），期间无法主动攻击", "prereq": "", "conflict": "", "effects": { "flags": { "spinner": true } } },
		{ "id": "rev_homing_1", "name": "枪斗术", "desc": "子弹添加微弱追踪效果", "prereq": "", "conflict": "", "effects": { "flags": { "homing_weak": true } } },
		{ "id": "rev_homing_2", "name": "智能制导", "desc": "子弹追踪效果增强", "prereq": "rev_homing_1", "conflict": "", "effects": { "flags": { "homing_strong": true } } },
	],
	# ============ 鞭子（近战扇形连抽，10 节点） ============
	"whip": [
		{ "id": "whip_range_1", "name": "鞭梢1", "desc": "抽击范围扩大15%", "prereq": "", "conflict": "", "effects": { "range_mult": 1.15 } },
		{ "id": "whip_range_2", "name": "鞭梢2", "desc": "抽击范围扩大15%", "prereq": "whip_range_1", "conflict": "", "effects": { "range_mult": 1.15 } },
		{ "id": "whip_wide", "name": "裂空鞭", "desc": "抽击范围大幅扩大30%", "prereq": "whip_range_2", "conflict": "", "effects": { "range_mult": 1.3 } },
		{ "id": "whip_power_1", "name": "破风1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "whip_power_2", "name": "破风2", "desc": "攻击力加15%", "prereq": "whip_power_1", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "whip_swift_1", "name": "甩鞭术1", "desc": "攻速加10%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "whip_swift_2", "name": "甩鞭术2", "desc": "攻速加10%", "prereq": "whip_swift_1", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "whip_multi", "name": "连抽", "desc": "一次攻击连续抽击两次", "prereq": "whip_swift_2", "conflict": "whip_bleed", "effects": { "counts": { "sweep": 1 } } },
		{ "id": "whip_bleed", "name": "血鞭", "desc": "抽击到的敌人获得5秒流血效果（最多叠加20层）", "prereq": "whip_swift_2", "conflict": "whip_multi", "effects": { "flags": { "bleed": true }, "counts": { "bleed_max": 20 } } },
		{ "id": "whip_crit", "name": "致命抽击", "desc": "暴击率加20%", "prereq": "whip_power_2", "conflict": "", "effects": { "crit_chance": 20.0 } },
	],
	# ============ 法杖（远程散射，10 节点） ============
	"staff": [
		{ "id": "staff_bullets_1", "name": "星弹1", "desc": "散射弹数加1", "prereq": "", "conflict": "", "effects": { "counts": { "projectile": 1 } } },
		{ "id": "staff_bullets_2", "name": "星弹2", "desc": "散射弹数加1", "prereq": "staff_bullets_1", "conflict": "", "effects": { "counts": { "projectile": 1 } } },
		{ "id": "staff_bullets_3", "name": "星弹3", "desc": "散射弹数加1", "prereq": "staff_bullets_2", "conflict": "", "effects": { "counts": { "projectile": 1 } } },
		{ "id": "staff_power_1", "name": "法纹1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "staff_power_2", "name": "法纹2", "desc": "攻击力加10%", "prereq": "staff_power_1", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "staff_swift_1", "name": "咏唱1", "desc": "攻速加10%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "staff_swift_2", "name": "咏唱2", "desc": "攻速加10%", "prereq": "staff_swift_1", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "staff_pierce", "name": "贯穿", "desc": "子弹可穿透1名敌人", "prereq": "staff_bullets_2", "conflict": "staff_explode", "effects": { "counts": { "pierce": 1 } } },
		{ "id": "staff_explode", "name": "爆裂", "desc": "子弹命中后产生小范围爆炸", "prereq": "staff_bullets_2", "conflict": "staff_pierce", "effects": { "flags": { "explode": true } } },
		{ "id": "staff_focus", "name": "凝光", "desc": "散射角度收窄，弹幕更集中", "prereq": "staff_bullets_3", "conflict": "", "effects": { "flags": { "focus": true } } },
	],
	# ============ 分裂者（远程分裂弹，10 节点） ============
	"splitter": [
		{ "id": "split_power_1", "name": "爆破弹头1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "split_power_2", "name": "爆破弹头2", "desc": "攻击力加10%", "prereq": "split_power_1", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "split_power_3", "name": "爆破弹头3", "desc": "攻击力加15%", "prereq": "split_power_2", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "split_swift_1", "name": "快膛1", "desc": "攻速加10%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "split_swift_2", "name": "快膛2", "desc": "攻速加10%", "prereq": "split_swift_1", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "split_children_1", "name": "分裂1", "desc": "命中分裂的弹数加1", "prereq": "", "conflict": "", "effects": { "counts": { "split": 1 } } },
		{ "id": "split_children_2", "name": "分裂2", "desc": "命中分裂的弹数加1", "prereq": "split_children_1", "conflict": "", "effects": { "counts": { "split": 1 } } },
		{ "id": "split_children_3", "name": "分裂3", "desc": "命中分裂的弹数加1", "prereq": "split_children_2", "conflict": "", "effects": { "counts": { "split": 1 } } },
		{ "id": "split_homing", "name": "制导分裂", "desc": "分裂小弹带微弱追踪效果", "prereq": "split_children_2", "conflict": "split_poison", "effects": { "flags": { "homing_weak": true } } },
		{ "id": "split_poison", "name": "剧毒", "desc": "命中敌人施加持续毒伤（每层每秒1点，最多叠加5层）", "prereq": "split_children_2", "conflict": "split_homing", "effects": { "flags": { "poison": true } } },
	],
	# ============ 黑洞枪（远程控场，10 节点） ============
	"black_hole_gun": [
		{ "id": "bhg_power_1", "name": "奇点1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "bhg_power_2", "name": "奇点2", "desc": "攻击力加10%", "prereq": "bhg_power_1", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "bhg_power_3", "name": "奇点3", "desc": "攻击力加15%", "prereq": "bhg_power_2", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "bhg_swift", "name": "脉冲", "desc": "攻速加10%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "bhg_radius_1", "name": "引力场1", "desc": "黑洞半径扩大20%", "prereq": "", "conflict": "", "effects": { "counts": { "bhg_radius": 1 } } },
		{ "id": "bhg_radius_2", "name": "引力场2", "desc": "黑洞半径扩大20%", "prereq": "bhg_radius_1", "conflict": "", "effects": { "counts": { "bhg_radius": 1 } } },
		{ "id": "bhg_radius_3", "name": "引力场3", "desc": "黑洞半径扩大30%", "prereq": "bhg_radius_2", "conflict": "", "effects": { "counts": { "bhg_radius": 1 } } },
		{ "id": "bhg_pull", "name": "强吸", "desc": "黑洞吸附速度大幅提高", "prereq": "bhg_radius_2", "conflict": "bhg_collapse", "effects": { "flags": { "pull_strong": true } } },
		{ "id": "bhg_collapse", "name": "坍缩", "desc": "黑洞消失时产生一次圆形伤害爆炸", "prereq": "bhg_radius_2", "conflict": "bhg_pull", "effects": { "flags": { "collapse": true } } },
		{ "id": "bhg_duration", "name": "持久", "desc": "黑洞持续时间延长30%", "prereq": "bhg_radius_3", "conflict": "", "effects": { "flags": { "duration": true } } },
	],
	# ============ 回旋镖（远程往返穿透，10 节点） ============
	"boomerang": [
		{ "id": "boom_power_1", "name": "开刃1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "boom_power_2", "name": "开刃2", "desc": "攻击力加10%", "prereq": "boom_power_1", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "boom_power_3", "name": "开刃3", "desc": "攻击力加15%", "prereq": "boom_power_2", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "boom_swift_1", "name": "腕力1", "desc": "攻速加10%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "boom_swift_2", "name": "腕力2", "desc": "攻速加10%", "prereq": "boom_swift_1", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "boom_pierce_1", "name": "贯穿刃1", "desc": "回旋镖可多穿透1名敌人", "prereq": "", "conflict": "", "effects": { "counts": { "pierce": 1 } } },
		{ "id": "boom_pierce_2", "name": "贯穿刃2", "desc": "回旋镖可多穿透1名敌人", "prereq": "boom_pierce_1", "conflict": "", "effects": { "counts": { "pierce": 1 } } },
		{ "id": "boom_return", "name": "二段往返", "desc": "回旋镖折返后再次飞出往返（额外一次往返）", "prereq": "boom_pierce_2", "conflict": "boom_multi", "effects": { "counts": { "return": 1 } } },
		{ "id": "boom_multi", "name": "双镖", "desc": "额外发射一枚回旋镖", "prereq": "boom_swift_2", "conflict": "boom_return", "effects": { "counts": { "boomerang": 1 } } },
		{ "id": "boom_whirlwind", "name": "绞杀旋涡", "desc": "回旋镖折返时高速旋转，飞行路径造成多段伤害", "prereq": "boom_pierce_2", "conflict": "boom_multi", "effects": { "flags": { "whirlwind": true } } },
	],
	# ============ 人物天赋（22 节点，作用于所有武器） ============
	"player": [
		# 力量系（暴击流）
		{ "id": "person_brute", "name": "蛮力", "desc": "所有武器伤害加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "person_brute_2", "name": "蛮劲", "desc": "所有武器伤害加10%", "prereq": "person_brute", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "person_brute_3", "name": "巨力", "desc": "所有武器伤害加15%", "prereq": "person_brute_2", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "person_crit", "name": "锐眼", "desc": "暴击率加15%", "prereq": "person_brute_2", "conflict": "person_extra", "effects": { "crit_chance": 15.0 } },
		{ "id": "person_crit_dmg", "name": "致命一击", "desc": "暴击伤害加60%", "prereq": "person_crit", "conflict": "", "effects": { "crit_dmg": 60.0 } },
		# 攻速系（连珠流）
		{ "id": "person_haste", "name": "迅捷", "desc": "所有武器攻速加8%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "person_haste_2", "name": "疾风", "desc": "所有武器攻速加8%", "prereq": "person_haste", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "person_haste_3", "name": "幻影", "desc": "所有武器攻速加8%", "prereq": "person_haste_2", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "person_extra", "name": "连珠", "desc": "远程武器额外发射1枚弹幕", "prereq": "person_haste_2", "conflict": "person_crit", "effects": { "counts": { "extra_projectile": 1 } } },
		# 范围系
		{ "id": "person_range", "name": "延伸", "desc": "所有武器范围加10%", "prereq": "", "conflict": "", "effects": { "range_mult": 1.1 } },
		{ "id": "person_range_2", "name": "长臂", "desc": "所有武器范围加10%", "prereq": "person_range", "conflict": "", "effects": { "range_mult": 1.1 } },
		{ "id": "person_range_3", "name": "千里", "desc": "所有武器范围加10%", "prereq": "person_range_2", "conflict": "", "effects": { "range_mult": 1.1 } },
		{ "id": "person_pierce", "name": "贯穿", "desc": "所有弹幕可穿透1名敌人", "prereq": "person_range_2", "conflict": "", "effects": { "counts": { "pierce": 1 } } },
		# 疾跑系
		{ "id": "person_sprint", "name": "疾跑", "desc": "移动速度加10%", "prereq": "", "conflict": "", "effects": { "speed_mult": 1.1 } },
		{ "id": "person_sprint_2", "name": "踏风", "desc": "移动速度加10%", "prereq": "person_sprint", "conflict": "", "effects": { "speed_mult": 1.1 } },
		{ "id": "person_dodge", "name": "闪避", "desc": "受击时15%概率完全闪避", "prereq": "person_sprint_2", "conflict": "", "effects": { "dodge": 15.0 } },
		# 坚韧系
		{ "id": "person_vitality", "name": "强健", "desc": "生命上限加20", "prereq": "", "conflict": "", "effects": { "max_hp": 20 } },
		{ "id": "person_tough", "name": "铁皮", "desc": "防御加1", "prereq": "person_vitality", "conflict": "", "effects": { "defense": 1 } },
		{ "id": "person_lifesteal", "name": "血之渴望", "desc": "攻击命中回复5%伤害的血量", "prereq": "person_vitality", "conflict": "", "effects": { "lifesteal": 5.0 } },
		{ "id": "person_regen", "name": "再生", "desc": "每秒回复1点血量", "prereq": "person_tough", "conflict": "", "effects": { "counts": { "regen": 1 } } },
		# 富足系
		{ "id": "person_wealth", "name": "聚财", "desc": "获得金币加15%", "prereq": "", "conflict": "", "effects": { "gold_gain": 15.0 } },
		{ "id": "person_exp", "name": "慧眼", "desc": "获得经验加15%", "prereq": "person_wealth", "conflict": "", "effects": { "xp_gain": 15.0 } },
	],
}

## 玩家持有的天赋点（人物升级 +1）。
var points := 0
## 已拥有天赋：tree_id -> { talent_id: bool }。
var owned := {}

func _init() -> void:
	for tree_id: String in TREES.keys():
		owned[tree_id] = {}

## 当前攻击方式 id（"blade" / "revolver"）。v1.2.0 起 UI 改由武器槽位驱动，此字段保留未用。
var attack_id := ""

## 天赋定义查询。
func def(tree_id: String, talent_id: String) -> Dictionary:
	for t: Dictionary in TREES.get(tree_id, []):
		if t.id == talent_id:
			return t
	return {}

func is_owned(tree_id: String, talent_id: String) -> bool:
	return owned.get(tree_id, {}).get(talent_id, false)

## 当前可选天赋集合：前置已满足 && 未拥有 && 未与已拥有天赋互斥。
func selectable(tree_id: String) -> Array:
	var result: Array[String] = []
	for t: Dictionary in TREES.get(tree_id, []):
		if is_owned(tree_id, t.id):
			continue
		if t.prereq != "" and not is_owned(tree_id, t.prereq):
			continue
		if t.conflict != "" and is_owned(tree_id, t.conflict):
			continue
		result.append(t.id)
	return result

## 从可选集合随机抽 n 个（不足 n 个则全给）。
func draw_choices(tree_id: String, n: int = 3) -> Array:
	var pool: Array = selectable(tree_id).duplicate()
	pool.shuffle()
	return pool.slice(0, n)

## 解锁一个天赋（需在可选集合内且点数充足），返回是否成功。
func unlock(tree_id: String, talent_id: String) -> bool:
	if points <= 0:
		return false
	if not selectable(tree_id).has(talent_id):
		return false
	owned[tree_id][talent_id] = true
	points -= 1
	return true

## 某树已拥有天赋 id 列表。
func owned_ids(tree_id: String) -> Array:
	var tree_owned: Dictionary = owned.get(tree_id, {})
	return tree_owned.keys().filter(func(id: String) -> bool: return tree_owned[id])

## 某树是否已点满（没有可选项了）。
func is_fully_unlocked(tree_id: String) -> bool:
	return selectable(tree_id).is_empty()

## 聚合一棵树所有已点天赋的效果。
## 返回 { dmg_mult, cd_mult, range_mult, speed_mult, crit_chance, crit_dmg, lifesteal, dodge,
##        max_hp, defense, xp_gain, gold_gain, flags, counts }。
## 倍率键连乘、数值键累加、flags/counts 逐项合并。攻击/人物脚本据此计算终值。
func aggregate(tree_id: String) -> Dictionary:
	var res := {
		"dmg_mult": 1.0,
		"cd_mult": 1.0,
		"range_mult": 1.0,
		"speed_mult": 1.0,
		"crit_chance": 0.0,
		"crit_dmg": 0.0,
		"lifesteal": 0.0,
		"dodge": 0.0,
		"max_hp": 0,
		"defense": 0,
		"xp_gain": 0.0,
		"gold_gain": 0.0,
		"flags": {},
		"counts": {},
	}
	var tree_owned: Array = owned_ids(tree_id)
	for talent_id in tree_owned:
		var fx: Dictionary = def(tree_id, talent_id).get("effects", {})
		for key: Variant in fx.keys():
			match key:
				"dmg_mult", "cd_mult", "range_mult", "speed_mult":
					res[key] *= fx[key]
				"flags":
					var flag_map: Dictionary = fx["flags"]
					for fk: String in flag_map.keys():
						res["flags"][fk] = bool(flag_map[fk])
				"counts":
					var count_map: Dictionary = fx["counts"]
					for ck: String in count_map.keys():
						res["counts"][ck] = int(res["counts"].get(ck, 0)) + int(count_map[ck])
				_:
					if res.has(key):
						res[key] += fx[key]
	return res
