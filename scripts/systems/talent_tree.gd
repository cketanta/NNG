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
		# 剑舞斩击：攻速与范围混合强化
		{ "id": "bd_dance_1", "name": "剑舞1", "desc": "攻速加8%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "bd_dance_2", "name": "剑舞2", "desc": "攻速加8%", "prereq": "bd_dance_1", "conflict": "", "effects": { "cd_mult": 0.92 } },
		# 暴击剑心：暴击流派（与防御流互斥）
		{ "id": "bc_crit_1", "name": "剑心1", "desc": "暴击率加10%", "prereq": "", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "bc_crit_2", "name": "剑心2", "desc": "暴击率加10%", "prereq": "bc_crit_1", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "bc_crit_dmg", "name": "致命剑", "desc": "暴击伤害加50%", "prereq": "bc_crit_1", "conflict": "", "effects": { "crit_dmg": 50.0 } },
		{ "id": "bc_sword_heart", "name": "无我剑心", "desc": "暴击率加10%，伤害加5%", "prereq": "bc_crit_2", "conflict": "bd_parry", "effects": { "crit_chance": 10.0, "dmg_mult": 1.05 } },
		# 剑术防御：招架/剑盾/剑墙（与暴击流互斥）
		{ "id": "bd_parry", "name": "招架", "desc": "闪避加8%", "prereq": "", "conflict": "bc_sword_heart", "effects": { "dodge": 8.0 } },
		{ "id": "bg_guard", "name": "剑盾1", "desc": "防御加1", "prereq": "bd_parry", "conflict": "", "effects": { "defense": 1 } },
		{ "id": "bg_guard_2", "name": "剑盾2", "desc": "防御加1", "prereq": "bg_guard", "conflict": "", "effects": { "defense": 1 } },
		# 血流成河：流血深化（需致残）
		{ "id": "bl_flow", "name": "血流成河", "desc": "流血上限加10", "prereq": "blade_maim", "conflict": "", "effects": { "counts": { "bleed_max": 10 } } },
		{ "id": "bl_blood", "name": "血染", "desc": "受击时流血额外伤害加3", "prereq": "bl_flow", "conflict": "", "effects": { "counts": { "bleed_bonus": 3 } } },
		# 斩击减速：命中减速（剑伤难行）
		{ "id": "bsl_slow_1", "name": "斩肌", "desc": "命中减速敌人", "prereq": "", "conflict": "", "effects": { "flags": { "slow": true } } },
		{ "id": "bsl_slow_2", "name": "断筋", "desc": "减速效果加深", "prereq": "bsl_slow_1", "conflict": "", "effects": { "counts": { "slow_tier": 1 } } },
		{ "id": "bsl_cripple", "name": "致残斩", "desc": "命中减速并额外流血", "prereq": "bsl_slow_2", "conflict": "", "effects": { "counts": { "slow_tier": 1 } } },
		# 终焉斩：处决/大斩
		{ "id": "bf_execute", "name": "处决", "desc": "暴击伤害加30%", "prereq": "bc_sword_heart", "conflict": "", "effects": { "crit_dmg": 30.0 } },
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
		# 精准暴击：暴击/穿透（与双持流互斥）
		{ "id": "rc_eye_1", "name": "鹰眼1", "desc": "暴击率加10%", "prereq": "", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "rc_eye_2", "name": "鹰眼2", "desc": "暴击率加10%", "prereq": "rc_eye_1", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "rc_deadly", "name": "致命射击", "desc": "暴击伤害加50%", "prereq": "rc_eye_1", "conflict": "", "effects": { "crit_dmg": 50.0 } },
		{ "id": "rc_pierce", "name": "穿甲弹", "desc": "子弹可穿透1名敌人", "prereq": "rc_eye_2", "conflict": "", "effects": { "counts": { "pierce": 1 } } },
		{ "id": "rc_sniper", "name": "狙击", "desc": "暴击率加10%，子弹穿透1名", "prereq": "rc_pierce", "conflict": "rr_dual_1", "effects": { "crit_chance": 10.0, "counts": { "pierce": 1 } } },
		# 燃烧弹：命中点燃
		{ "id": "rb_burn", "name": "燃烧弹", "desc": "命中点燃敌人（每秒燃烧伤害）", "prereq": "", "conflict": "", "effects": { "flags": { "burn": true } } },
		{ "id": "rb_burn_t1", "name": "烈焰1", "desc": "燃烧效果增强", "prereq": "rb_burn", "conflict": "", "effects": { "counts": { "burn_tier": 1 } } },
		{ "id": "rb_burn_t2", "name": "烈焰2", "desc": "燃烧效果增强", "prereq": "rb_burn_t1", "conflict": "", "effects": { "counts": { "burn_tier": 1 } } },
		{ "id": "rb_ember", "name": "余烬", "desc": "攻击力加5%", "prereq": "rb_burn_t2", "conflict": "", "effects": { "dmg_mult": 1.05 } },
		# 转盘强化：转盘扩容/伤害/双转盘
		{ "id": "rs_count_1", "name": "转盘扩容1", "desc": "转盘子弹数量加1", "prereq": "rev_spinner", "conflict": "", "effects": { "counts": { "spin_extra": 1 } } },
		{ "id": "rs_count_2", "name": "转盘扩容2", "desc": "转盘子弹数量加1", "prereq": "rs_count_1", "conflict": "", "effects": { "counts": { "spin_extra": 1 } } },
		{ "id": "rs_dmg", "name": "转盘重锤", "desc": "转盘子弹伤害提升", "prereq": "rs_count_2", "conflict": "", "effects": { "counts": { "spin_dmg": 1 } } },
		{ "id": "rs_dual", "name": "双转盘", "desc": "额外扔出一个转盘", "prereq": "rs_dmg", "conflict": "", "effects": { "flags": { "spin_dual": true } } },
		{ "id": "rs_rapid_spin", "name": "急速转盘", "desc": "转盘发射更快", "prereq": "rs_dual", "conflict": "", "effects": { "cd_mult": 0.9 } },
		# 射速双持：额外弹/攻速（与狙击流互斥）
		{ "id": "rr_dual_1", "name": "双持1", "desc": "额外发射1枚子弹", "prereq": "", "conflict": "rc_sniper", "effects": { "counts": { "extra_projectile": 1 } } },
		{ "id": "rr_dual_2", "name": "双持2", "desc": "额外发射1枚子弹", "prereq": "rr_dual_1", "conflict": "", "effects": { "counts": { "extra_projectile": 1 } } },
		{ "id": "rr_haste", "name": "迅捷填装", "desc": "攻速加8%", "prereq": "rr_dual_2", "conflict": "", "effects": { "cd_mult": 0.92 } },
		# 锁定制导：追踪强化/死标
		{ "id": "rl_lock_1", "name": "锁定1", "desc": "子弹追踪增强", "prereq": "rev_homing_1", "conflict": "", "effects": { "counts": { "homing": 1 } } },
		{ "id": "rl_lock_2", "name": "锁定2", "desc": "子弹追踪增强", "prereq": "rl_lock_1", "conflict": "", "effects": { "counts": { "homing": 1 } } },
		{ "id": "rl_deathmark", "name": "死标", "desc": "命中标记敌人，暴击率加8%", "prereq": "rl_lock_2", "conflict": "", "effects": { "crit_chance": 8.0 } },
		# 枪术身法：闪避/换弹
		{ "id": "rt_dodge_1", "name": "滑步1", "desc": "闪避加8%", "prereq": "", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "rt_dodge_2", "name": "滑步2", "desc": "闪避加8%", "prereq": "rt_dodge_1", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "rt_reload", "name": "战术换弹", "desc": "攻速加10%", "prereq": "rt_dodge_2", "conflict": "", "effects": { "cd_mult": 0.9 } },
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
		# 鞭影横扫：范围/攻速/连段混合
		{ "id": "ww_shadow_1", "name": "鞭影1", "desc": "抽击范围扩大15%", "prereq": "", "conflict": "", "effects": { "range_mult": 1.15 } },
		{ "id": "ww_shadow_2", "name": "鞭影2", "desc": "抽击范围扩大15%", "prereq": "ww_shadow_1", "conflict": "", "effects": { "range_mult": 1.15 } },
		{ "id": "ww_wide", "name": "横扫", "desc": "抽击范围大幅扩大25%", "prereq": "ww_shadow_2", "conflict": "", "effects": { "range_mult": 1.25 } },
		{ "id": "ww_flurry", "name": "鞭舞", "desc": "攻速加10%", "prereq": "ww_wide", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "ww_mult", "name": "鞭影多重", "desc": "连抽次数加1", "prereq": "ww_flurry", "conflict": "", "effects": { "counts": { "sweep": 1 } } },
		# 缠绕控制：命中减速
		{ "id": "we_snare", "name": "缠绕", "desc": "命中减速敌人", "prereq": "", "conflict": "", "effects": { "flags": { "slow": true } } },
		{ "id": "we_bind_1", "name": "束缚1", "desc": "减速效果增强", "prereq": "we_snare", "conflict": "", "effects": { "counts": { "slow_tier": 1 } } },
		{ "id": "we_bind_2", "name": "束缚2", "desc": "减速效果增强", "prereq": "we_bind_1", "conflict": "", "effects": { "counts": { "slow_tier": 1 } } },
		{ "id": "we_chain", "name": "锁链", "desc": "减速并附带流血", "prereq": "we_bind_2", "conflict": "", "effects": { "counts": { "slow_tier": 1, "bleed_max": 10 }, "flags": { "bleed": true } } },
		{ "id": "we_thorn", "name": "荆棘", "desc": "减速敌人并伤害加深", "prereq": "we_chain", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		# 藤蔓召唤：连抽强化（藤蔓抽打）
		{ "id": "wv_vine_1", "name": "藤蔓抽击1", "desc": "连抽次数加1（藤蔓缠打）", "prereq": "", "conflict": "", "effects": { "counts": { "sweep": 1 } } },
		{ "id": "wv_vine_2", "name": "藤蔓抽击2", "desc": "连抽次数加1", "prereq": "wv_vine_1", "conflict": "", "effects": { "counts": { "sweep": 1 } } },
		{ "id": "wv_growth", "name": "生长", "desc": "连抽加1，伤害加5%", "prereq": "wv_vine_2", "conflict": "", "effects": { "counts": { "sweep": 1 }, "dmg_mult": 1.05 } },
		{ "id": "wv_bind", "name": "藤缠", "desc": "连抽时减速敌人", "prereq": "wv_growth", "conflict": "", "effects": { "flags": { "slow": true } } },
		{ "id": "wv_thorn_v", "name": "棘藤", "desc": "藤蔓带刺，流血上限加10", "prereq": "wv_bind", "conflict": "", "effects": { "counts": { "bleed_max": 10 }, "flags": { "bleed": true } } },
		# 吸血嗜血
		{ "id": "wm_vamp_1", "name": "吸血1", "desc": "命中回复伤害3%的血量", "prereq": "", "conflict": "", "effects": { "lifesteal": 3.0 } },
		{ "id": "wm_vamp_2", "name": "吸血2", "desc": "命中回复伤害3%的血量", "prereq": "wm_vamp_1", "conflict": "", "effects": { "lifesteal": 3.0 } },
		{ "id": "wm_blood", "name": "嗜血", "desc": "命中回复伤害4%的血量", "prereq": "wm_vamp_2", "conflict": "", "effects": { "lifesteal": 4.0 } },
		{ "id": "wm_bleed_heal", "name": "血疗", "desc": "吸血加3%，伤害加5%", "prereq": "wm_blood", "conflict": "", "effects": { "lifesteal": 3.0, "dmg_mult": 1.05 } },
		# 暴击处刑
		{ "id": "wc_crit_1", "name": "致命抽击1", "desc": "暴击率加10%", "prereq": "", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "wc_crit_2", "name": "致命抽击2", "desc": "暴击率加10%", "prereq": "wc_crit_1", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "wc_crit_dmg", "name": "处刑", "desc": "暴击伤害加50%", "prereq": "wc_crit_2", "conflict": "", "effects": { "crit_dmg": 50.0 } },
		{ "id": "wc_execute", "name": "终结", "desc": "暴击伤害加30%", "prereq": "wc_crit_dmg", "conflict": "", "effects": { "crit_dmg": 30.0 } },
		{ "id": "wc_focus", "name": "鞭心", "desc": "暴击率加10%，伤害加5%", "prereq": "wc_execute", "conflict": "", "effects": { "crit_chance": 10.0, "dmg_mult": 1.05 } },
		# 身法
		{ "id": "ws_dodge_1", "name": "游走1", "desc": "闪避加8%", "prereq": "", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "ws_dodge_2", "name": "游走2", "desc": "闪避加8%", "prereq": "ws_dodge_1", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "ws_speed", "name": "疾鞭", "desc": "移动速度加8%", "prereq": "ws_dodge_2", "conflict": "", "effects": { "speed_mult": 1.08 } },
		{ "id": "ws_agile", "name": "敏捷", "desc": "闪避加8%，攻速加5%", "prereq": "ws_speed", "conflict": "", "effects": { "dodge": 8.0, "cd_mult": 0.95 } },
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
		# 奥术强化：伤害/爆炸
		{ "id": "sa_arcane_1", "name": "奥术1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "sa_arcane_2", "name": "奥术2", "desc": "攻击力加15%", "prereq": "sa_arcane_1", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "sa_blast", "name": "奥术爆破", "desc": "爆裂伤害加5%并扩大", "prereq": "sa_arcane_2", "conflict": "", "effects": { "flags": { "explode": true }, "dmg_mult": 1.05 } },
		{ "id": "sa_charge", "name": "蓄能", "desc": "伤害加10%，攻速加5%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1, "cd_mult": 0.95 } },
		{ "id": "sa_overload", "name": "过载", "desc": "伤害加15%", "prereq": "sa_charge", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		# 冰霜控制：减速/冻结
		{ "id": "sf_frost", "name": "冰霜", "desc": "命中冻结敌人（短暂定身）", "prereq": "", "conflict": "", "effects": { "flags": { "freeze": true } } },
		{ "id": "sf_freeze", "name": "冻结术", "desc": "冻结效果增强", "prereq": "sf_frost", "conflict": "", "effects": { "counts": { "freeze_tier": 1 } } },
		{ "id": "sf_cold", "name": "寒冷", "desc": "命中减速敌人", "prereq": "", "conflict": "", "effects": { "flags": { "slow": true } } },
		{ "id": "sf_glacier", "name": "冰川", "desc": "命中同时减速并冻结", "prereq": "sf_cold", "conflict": "", "effects": { "flags": { "freeze": true, "slow": true } } },
		{ "id": "sf_ice", "name": "寒刺", "desc": "攻击力加10%", "prereq": "sf_glacier", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		# 闪电连锁：命中弹射
		{ "id": "sc_chain_1", "name": "连锁1", "desc": "命中弹射到附近敌人", "prereq": "", "conflict": "", "effects": { "flags": { "chain": true } } },
		{ "id": "sc_chain_2", "name": "连锁2", "desc": "弹射次数加1", "prereq": "sc_chain_1", "conflict": "", "effects": { "counts": { "chain": 1 } } },
		{ "id": "sc_bolt", "name": "雷击", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "sc_field", "name": "静电场", "desc": "弹射次数加1", "prereq": "sc_chain_2", "conflict": "", "effects": { "counts": { "chain": 1 } } },
		{ "id": "sc_storm", "name": "雷暴", "desc": "弹射次数加1", "prereq": "sc_field", "conflict": "", "effects": { "counts": { "chain": 1 } } },
		# 元素精通：混合元素增伤
		{ "id": "se_fire", "name": "火元素", "desc": "命中点燃敌人", "prereq": "", "conflict": "", "effects": { "flags": { "burn": true } } },
		{ "id": "se_frost_mix", "name": "冰元素", "desc": "命中减速敌人", "prereq": "se_fire", "conflict": "", "effects": { "flags": { "slow": true } } },
		{ "id": "se_thunder", "name": "雷元素", "desc": "命中弹射1次", "prereq": "se_fire", "conflict": "", "effects": { "counts": { "chain": 1 } } },
		{ "id": "se_mastery", "name": "元素精通", "desc": "攻击力加15%", "prereq": "se_thunder", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		# 施法极速：攻速/双法
		{ "id": "ss_cast_1", "name": "咏唱1", "desc": "攻速加8%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "ss_cast_2", "name": "咏唱2", "desc": "攻速加8%", "prereq": "ss_cast_1", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "ss_dual", "name": "双法", "desc": "额外发射1枚弹幕", "prereq": "ss_cast_2", "conflict": "", "effects": { "counts": { "extra_projectile": 1 } } },
		{ "id": "ss_echo", "name": "法术回响", "desc": "攻速加10%", "prereq": "ss_cast_2", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "ss_haste", "name": "极速咏唱", "desc": "攻速加10%，伤害加5%", "prereq": "ss_echo", "conflict": "", "effects": { "cd_mult": 0.9, "dmg_mult": 1.05 } },
		# 奥术护盾：防御/闪避
		{ "id": "sg_shield_1", "name": "护盾1", "desc": "防御加1", "prereq": "", "conflict": "", "effects": { "defense": 1 } },
		{ "id": "sg_shield_2", "name": "护盾2", "desc": "防御加1", "prereq": "sg_shield_1", "conflict": "", "effects": { "defense": 1 } },
		{ "id": "sg_ward", "name": "奥术屏障", "desc": "闪避加8%", "prereq": "sg_shield_2", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "sg_protect", "name": "守护", "desc": "防御加1，闪避加8%", "prereq": "sg_ward", "conflict": "", "effects": { "defense": 1, "dodge": 8.0 } },
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
		{ "id": "split_homing", "name": "制导分裂", "desc": "分裂小弹带微弱追踪效果", "prereq": "split_children_2", "conflict": "", "effects": { "flags": { "homing_weak": true } } },
		# 二次分裂：分裂小弹命中再分裂（分裂代数）
		{ "id": "sp2_tier_1", "name": "二次分裂", "desc": "分裂小弹命中后再分裂出小弹", "prereq": "", "conflict": "", "effects": { "counts": { "split_tier": 1 } } },
		{ "id": "sp2_tier_2", "name": "三次分裂", "desc": "二次分裂弹再多分裂一次", "prereq": "sp2_tier_1", "conflict": "", "effects": { "counts": { "split_tier": 1 } } },
		{ "id": "sp2_more", "name": "更多分裂", "desc": "初始分裂弹数加1", "prereq": "sp2_tier_1", "conflict": "", "effects": { "counts": { "split": 1 } } },
		{ "id": "sp2_deep", "name": "深层分裂", "desc": "分裂代数再加1", "prereq": "sp2_tier_2", "conflict": "", "effects": { "counts": { "split_tier": 1 } } },
		{ "id": "sp2_total", "name": "完全分裂", "desc": "初始分裂弹数加2", "prereq": "sp2_deep", "conflict": "", "effects": { "counts": { "split": 2 } } },
		# 破片溅射：命中小范围伤害（复用爆炸机制）
		{ "id": "spf_shard_1", "name": "破片1", "desc": "命中产生小范围破片伤害", "prereq": "", "conflict": "", "effects": { "counts": { "shard": 1 } } },
		{ "id": "spf_shard_2", "name": "破片2", "desc": "破片伤害提升", "prereq": "spf_shard_1", "conflict": "", "effects": { "counts": { "shard": 1 } } },
		{ "id": "spf_splash", "name": "溅射", "desc": "破片范围扩大", "prereq": "spf_shard_2", "conflict": "", "effects": { "counts": { "shard": 1 }, "dmg_mult": 1.05 } },
		{ "id": "spf_dmg", "name": "破片伤", "desc": "攻击力加10%", "prereq": "spf_splash", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "spf_storm", "name": "破片风暴", "desc": "破片数量加1", "prereq": "spf_dmg", "conflict": "", "effects": { "counts": { "shard": 1 } } },
		# 导弹制导：分裂追踪强化
		{ "id": "spm_lock_1", "name": "锁定1", "desc": "分裂小弹追踪增强", "prereq": "split_homing", "conflict": "", "effects": { "counts": { "homing": 1 } } },
		{ "id": "spm_lock_2", "name": "锁定2", "desc": "分裂小弹追踪增强", "prereq": "spm_lock_1", "conflict": "", "effects": { "counts": { "homing": 1 } } },
		{ "id": "spm_guidance", "name": "制导核心", "desc": "追踪大幅增强", "prereq": "spm_lock_2", "conflict": "", "effects": { "counts": { "homing": 2 } } },
		{ "id": "spm_hunt", "name": "猎杀", "desc": "攻击力加10%", "prereq": "spm_guidance", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		# 聚变：分裂合并增伤
		{ "id": "spu_fusion_1", "name": "聚变1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "spu_fusion_2", "name": "聚变2", "desc": "攻击力加15%", "prereq": "spu_fusion_1", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "spu_merge", "name": "合并", "desc": "分裂弹数量加1", "prereq": "spu_fusion_2", "conflict": "", "effects": { "counts": { "split": 1 } } },
		{ "id": "spu_core", "name": "聚变核心", "desc": "攻击力加10%", "prereq": "spu_merge", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "spu_nova", "name": "聚变新星", "desc": "攻击力加20%", "prereq": "spu_core", "conflict": "", "effects": { "dmg_mult": 1.2 } },
		# 充能超载：攻速
		{ "id": "spc_charge_1", "name": "充能1", "desc": "攻速加8%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "spc_charge_2", "name": "充能2", "desc": "攻速加8%", "prereq": "spc_charge_1", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "spc_overload", "name": "超载", "desc": "攻速加10%", "prereq": "spc_charge_2", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "spc_rapid", "name": "快速充能", "desc": "攻速加10%，伤害加5%", "prereq": "spc_overload", "conflict": "", "effects": { "cd_mult": 0.9, "dmg_mult": 1.05 } },
		{ "id": "spc_energy", "name": "能量", "desc": "攻击力加10%", "prereq": "spc_rapid", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		# 能量爆发：暴击
		{ "id": "spp_crit_1", "name": "能量暴1", "desc": "暴击率加10%", "prereq": "", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "spp_crit_2", "name": "能量暴2", "desc": "暴击率加10%", "prereq": "spp_crit_1", "conflict": "", "effects": { "crit_chance": 10.0 } },
		{ "id": "spp_crit_dmg", "name": "爆能", "desc": "暴击伤害加50%", "prereq": "spp_crit_2", "conflict": "", "effects": { "crit_dmg": 50.0 } },
		{ "id": "spp_burst", "name": "爆发", "desc": "暴击伤害加30%", "prereq": "spp_crit_dmg", "conflict": "", "effects": { "crit_dmg": 30.0 } },
		{ "id": "spp_power", "name": "能量核", "desc": "暴击率加5%，伤害加10%", "prereq": "spp_burst", "conflict": "", "effects": { "crit_chance": 5.0, "dmg_mult": 1.1 } },
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
		# 虚空侵蚀：黑洞内部持续伤害
		{ "id": "bv_erode_1", "name": "侵蚀1", "desc": "黑洞每秒对内部敌人造成伤害", "prereq": "", "conflict": "", "effects": { "counts": { "erode": 1 } } },
		{ "id": "bv_erode_2", "name": "侵蚀2", "desc": "黑洞侵蚀伤害提升", "prereq": "bv_erode_1", "conflict": "", "effects": { "counts": { "erode": 1 } } },
		{ "id": "bv_void_1", "name": "虚空1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "bv_void_2", "name": "虚空2", "desc": "攻击力加15%", "prereq": "bv_void_1", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "bv_corrupt", "name": "腐蚀", "desc": "黑洞侵蚀伤害提升", "prereq": "bv_erode_2", "conflict": "", "effects": { "counts": { "erode": 1 } } },
		# 引力掌控：吸附强化
		{ "id": "bq_well_1", "name": "引力井1", "desc": "黑洞吸附速度提升", "prereq": "", "conflict": "", "effects": { "counts": { "pull": 1 } } },
		{ "id": "bq_well_2", "name": "引力井2", "desc": "黑洞吸附速度提升", "prereq": "bq_well_1", "conflict": "", "effects": { "counts": { "pull": 1 } } },
		{ "id": "bq_orbit", "name": "轨道", "desc": "黑洞范围扩大10%", "prereq": "bq_well_2", "conflict": "", "effects": { "counts": { "bhg_radius": 1 } } },
		{ "id": "bq_mass", "name": "质量", "desc": "吸附提升，范围扩大", "prereq": "bq_orbit", "conflict": "", "effects": { "counts": { "pull": 1, "bhg_radius": 1 } } },
		{ "id": "bq_center", "name": "引力中心", "desc": "吸附大幅提升", "prereq": "bq_mass", "conflict": "", "effects": { "counts": { "pull": 2 } } },
		# 坍缩奇点：坍缩强化
		{ "id": "bc_collapse_1", "name": "坍缩强1", "desc": "坍缩爆炸伤害提升", "prereq": "bhg_collapse", "conflict": "", "effects": { "counts": { "collapse_dmg": 1 } } },
		{ "id": "bc_collapse_2", "name": "坍缩强2", "desc": "坍缩爆炸伤害提升", "prereq": "bc_collapse_1", "conflict": "", "effects": { "counts": { "collapse_dmg": 1 } } },
		{ "id": "bc_singularity", "name": "奇点", "desc": "坍缩伤害提升，范围扩大", "prereq": "bc_collapse_2", "conflict": "", "effects": { "counts": { "collapse_dmg": 1, "bhg_radius": 1 } } },
		{ "id": "bc_tear", "name": "撕裂", "desc": "坍缩伤害大幅提升", "prereq": "bc_singularity", "conflict": "", "effects": { "counts": { "collapse_dmg": 2 } } },
		{ "id": "bc_burst", "name": "爆缩", "desc": "坍缩伤害提升", "prereq": "bc_tear", "conflict": "", "effects": { "counts": { "collapse_dmg": 1 } } },
		# 时间停滞：黑洞内部减速/冻结
		{ "id": "bt_slow_1", "name": "迟缓1", "desc": "黑洞内部敌人减速", "prereq": "", "conflict": "", "effects": { "flags": { "slow": true } } },
		{ "id": "bt_slow_2", "name": "迟缓2", "desc": "减速效果增强", "prereq": "bt_slow_1", "conflict": "", "effects": { "counts": { "slow_tier": 1 } } },
		{ "id": "bt_freeze", "name": "冻结场", "desc": "黑洞内部敌人短暂冻结", "prereq": "bt_slow_2", "conflict": "", "effects": { "flags": { "freeze": true } } },
		{ "id": "bt_stasis", "name": "停滞", "desc": "减速增强，冻结增强", "prereq": "bt_freeze", "conflict": "", "effects": { "counts": { "slow_tier": 1, "freeze_tier": 1 } } },
		{ "id": "bt_arrest", "name": "时间冻结", "desc": "冻结效果大幅增强", "prereq": "bt_stasis", "conflict": "", "effects": { "counts": { "freeze_tier": 2 } } },
		# 毁灭吞噬：黑洞伤害
		{ "id": "bth_devour_1", "name": "吞噬1", "desc": "攻击力加10%", "prereq": "", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "bth_devour_2", "name": "吞噬2", "desc": "攻击力加15%", "prereq": "bth_devour_1", "conflict": "", "effects": { "dmg_mult": 1.15 } },
		{ "id": "bth_hunger", "name": "饥饿", "desc": "黑洞侵蚀伤害提升", "prereq": "bth_devour_2", "conflict": "", "effects": { "counts": { "erode": 1 } } },
		{ "id": "bth_oblivion", "name": "湮灭", "desc": "攻击力加20%", "prereq": "bth_hunger", "conflict": "", "effects": { "dmg_mult": 1.2 } },
		# 虚空护盾：防御/闪避
		{ "id": "bsh_guard_1", "name": "虚空盾1", "desc": "防御加1", "prereq": "", "conflict": "", "effects": { "defense": 1 } },
		{ "id": "bsh_guard_2", "name": "虚空盾2", "desc": "防御加1", "prereq": "bsh_guard_1", "conflict": "", "effects": { "defense": 1 } },
		{ "id": "bsh_ward", "name": "虚空屏障", "desc": "闪避加8%", "prereq": "bsh_guard_2", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "bsh_protect", "name": "虚空守护", "desc": "防御加1，闪避加8%", "prereq": "bsh_ward", "conflict": "", "effects": { "defense": 1, "dodge": 8.0 } },
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
		# 多镖风暴：镖数
		{ "id": "bm_dart_1", "name": "多镖1", "desc": "额外发射1枚回旋镖", "prereq": "", "conflict": "", "effects": { "counts": { "boomerang": 1 } } },
		{ "id": "bm_dart_2", "name": "多镖2", "desc": "额外发射1枚回旋镖", "prereq": "bm_dart_1", "conflict": "", "effects": { "counts": { "boomerang": 1 } } },
		{ "id": "bm_dart_3", "name": "多镖3", "desc": "额外发射1枚回旋镖", "prereq": "bm_dart_2", "conflict": "", "effects": { "counts": { "boomerang": 1 } } },
		{ "id": "bm_storm", "name": "镖雨", "desc": "额外1枚镖，伤害加5%", "prereq": "bm_dart_3", "conflict": "", "effects": { "counts": { "boomerang": 1 }, "dmg_mult": 1.05 } },
		{ "id": "bm_swarm", "name": "镖群", "desc": "额外发射2枚回旋镖", "prereq": "bm_storm", "conflict": "", "effects": { "counts": { "boomerang": 2 } } },
		# 旋涡绞杀：旋涡强化
		{ "id": "bw_whirl_1", "name": "旋涡1", "desc": "旋涡多段伤害提升", "prereq": "boom_whirlwind", "conflict": "", "effects": { "counts": { "whirl": 1 } } },
		{ "id": "bw_whirl_2", "name": "旋涡2", "desc": "旋涡多段伤害提升", "prereq": "bw_whirl_1", "conflict": "", "effects": { "counts": { "whirl": 1 } } },
		{ "id": "bw_tornado", "name": "龙卷", "desc": "旋涡大幅强化", "prereq": "bw_whirl_2", "conflict": "", "effects": { "counts": { "whirl": 2 } } },
		{ "id": "bw_grind", "name": "绞杀", "desc": "攻击力加10%", "prereq": "bw_tornado", "conflict": "", "effects": { "dmg_mult": 1.1 } },
		{ "id": "bw_slice", "name": "切片", "desc": "旋涡强化，伤害加5%", "prereq": "bw_grind", "conflict": "", "effects": { "counts": { "whirl": 1 }, "dmg_mult": 1.05 } },
		# 磁吸风暴：飞行吸附拖拽
		{ "id": "bmg_magnet_1", "name": "磁吸1", "desc": "飞行时缓慢吸附附近敌人", "prereq": "", "conflict": "", "effects": { "flags": { "magnet": true } } },
		{ "id": "bmg_magnet_2", "name": "磁吸2", "desc": "吸附效果增强", "prereq": "bmg_magnet_1", "conflict": "", "effects": { "counts": { "magnet": 1 } } },
		{ "id": "bmg_drag", "name": "拖拽", "desc": "吸附效果增强", "prereq": "bmg_magnet_2", "conflict": "", "effects": { "counts": { "magnet": 1 } } },
		{ "id": "bmg_center", "name": "风暴中心", "desc": "吸附增强，伤害加5%", "prereq": "bmg_drag", "conflict": "", "effects": { "counts": { "magnet": 1 }, "dmg_mult": 1.05 } },
		# 锋利破甲：穿透/破甲
		{ "id": "bp_sharp_1", "name": "开锋1", "desc": "穿透数加1", "prereq": "", "conflict": "", "effects": { "counts": { "pierce": 1 } } },
		{ "id": "bp_sharp_2", "name": "开锋2", "desc": "穿透数加1", "prereq": "bp_sharp_1", "conflict": "", "effects": { "counts": { "pierce": 1 } } },
		{ "id": "bp_armor_break", "name": "破甲", "desc": "命中削弱敌人防御（受击增伤）", "prereq": "bp_sharp_2", "conflict": "", "effects": { "flags": { "armor_break": true } } },
		{ "id": "bp_penetrate", "name": "穿甲", "desc": "穿透加1，伤害加5%", "prereq": "bp_armor_break", "conflict": "", "effects": { "counts": { "pierce": 1 }, "dmg_mult": 1.05 } },
		# 极速回旋：攻速
		{ "id": "bs_speed_1", "name": "极速1", "desc": "攻速加8%", "prereq": "", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "bs_speed_2", "name": "极速2", "desc": "攻速加8%", "prereq": "bs_speed_1", "conflict": "", "effects": { "cd_mult": 0.92 } },
		{ "id": "bs_ultra", "name": "超速", "desc": "攻速加10%", "prereq": "bs_speed_2", "conflict": "", "effects": { "cd_mult": 0.9 } },
		{ "id": "bs_rewind", "name": "回旋", "desc": "攻速加10%，伤害加5%", "prereq": "bs_ultra", "conflict": "", "effects": { "cd_mult": 0.9, "dmg_mult": 1.05 } },
		{ "id": "bs_blade_dance", "name": "刃舞", "desc": "攻速加8%，伤害加5%", "prereq": "bs_rewind", "conflict": "", "effects": { "cd_mult": 0.92, "dmg_mult": 1.05 } },
		# 刃舞身法：闪避/移速
		{ "id": "bb_dodge_1", "name": "游刃1", "desc": "闪避加8%", "prereq": "", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "bb_dodge_2", "name": "游刃2", "desc": "闪避加8%", "prereq": "bb_dodge_1", "conflict": "", "effects": { "dodge": 8.0 } },
		{ "id": "bb_swift", "name": "迅捷", "desc": "移动速度加8%", "prereq": "bb_dodge_2", "conflict": "", "effects": { "speed_mult": 1.08 } },
		{ "id": "bb_agile", "name": "轻灵", "desc": "闪避加8%，攻速加5%", "prereq": "bb_swift", "conflict": "", "effects": { "dodge": 8.0, "cd_mult": 0.95 } },
		{ "id": "bb_flawless", "name": "完美", "desc": "闪避加8%，伤害加5%", "prereq": "bb_agile", "conflict": "", "effects": { "dodge": 8.0, "dmg_mult": 1.05 } },
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
