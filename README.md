# NNG — 类吸血鬼幸存者 2D 生存刷怪游戏
# NNG — Vampire-Survivors-like 2D Survival Shooter

> 当前版本 Current Version: **v1.5.0**
>
> 🤖 **纯 AI 项目 / Pure AI Project**：本游戏由 Claude（Anthropic AI）全程编写生成，代码、场景、贴图、测试均为 AI 产出。
> This game is entirely written by AI (Claude) — code, scenes, art and tests are all AI-generated.

---

## 操作 Controls

| 按键 Key | 功能 Function |
|---|---|
| **WASD** | 移动 Move |
| **Tab** | 切换攻击模式：自动索敌 / 手动瞄准 Toggle auto / manual aim |
| **鼠标左键 LMB** | 手动模式下射击 Fire (manual mode) |
| **鼠标右键 RMB** | 左轮「转盘枪手」特殊攻击 Revolver spinner special attack |
| **T** | 天赋界面（人物天赋 + 武器天赋） Talent menu (personal + weapon) |
| **B** | 背包 Backpack |
| **L** | 调试面板（仅测试模式） Debug panel (test mode only) |
| **Esc** | 暂停 / 关闭菜单 Pause / Close menu |
| **图鉴 Bestiary** | 开局难度面板点击「图鉴」查看 怪物 / 武器 / 道具 / 天赋树（on the difficulty screen） |

## 玩法循环 Gameplay Loop

**中文**：开局选**难度**（简单/普通/困难），以初始「破旧手枪」直接开战，武器环绕玩家旋转。每波 **50 秒**，敌人随时间变多变快；**每 5 波出现 BOSS**（7 种轮换，击杀 BOSS 才能结束该波）；第 3 波起出现 **5 种独立精英**。波末清场进入**商店**（买武器 / 买道具 / 出售 / 合成；道具越买越贵），点「开始下一波」继续。打怪掉落经验宝石与金币（靠近自动磁吸）、概率掉红心回血；升级获得**人物天赋点**；生命归零进入结算界面（难度 / 击杀 / 波次 / 等级 / 金币 / 时间）。

**EN**: Pick a difficulty (Easy/Normal/Hard) at start, then fight with the starter pistol while weapons orbit around you. Each wave lasts **50s** and gets tougher; a **BOSS appears every 5 waves** (7 rotating kinds, the wave only ends when the BOSS dies); independent elites appear from wave 3. After clearing, enter the shop (buy weapons / items, sell, merge; items get pricier the more you own) then start the next wave. Enemies drop XP gems and coins (auto-magnet), sometimes hearts to heal. Leveling up grants **personal talent points**. Game over shows a summary (difficulty / kills / wave / level / gold / time).

## 武器系统 Weapon System

**中文**：最多持有 **8 把武器**（槽位），武器环绕玩家旋转、每把独立瞄准攻击，各有独立**等级**与**天赋树**。商店售卖 **7 种武器**（短刃/左轮/鞭子/法杖/分裂者/黑洞枪/回旋镖）：有空槽入槽，槽满且已有同名则自动合成升级。**合成**（仅商店）：在槽位点选两把同名武器，等级相加、保留高等级天赋树、多出等级转为天赋点。**出售**：可卖任意武器（含初始手枪），价格 = 购买价值一半。武器等级 Lv.N 提供 N 点该武器的天赋点。

**EN**: Hold up to **8 weapons** (slots) orbiting the player, each aiming and firing independently with its own **level** and **talent tree**. The shop sells **7 weapons** (Blade/Revolver/Whip/Staff/Splitter/Black Hole Gun/Boomerang): empty slot = add; full slots with a same-name weapon = auto-merge. **Merge** (shop only): click two same-name weapons, levels sum up, keep the higher-level talent tree, excess levels become talent points. **Sell** any weapon (including the starter pistol) for half its value. Weapon level N grants N talent points for that weapon.

## 天赋系统 Talent System

**中文**：
- **人物天赋**（升级获得点数）：**树状多维**六系——力量（伤害/暴击）/ 攻速（连珠）/ 范围（贯穿）/ 疾跑（闪避）/ 坚韧（吸血/再生/防御）/ 富足（经验/金币），含互斥流派选择。
- **武器天赋**（每把武器独立 **38 节点主题化**，等级提供点数）：短刃（切割/剑气/流血/暴击）、左轮（连射/转盘/燃烧/锁定）、鞭子（连抽/缠绕/吸血）、法杖（元素散射/冰霜/闪电连锁）、分裂者（分裂/二次分裂/破片）、黑洞枪（引力/坍缩/虚空侵蚀）、回旋镖（往返穿透/多镖/磁吸/破甲）。按 T 打开天赋界面，点选武器切换其天赋树，三选一加点。

**EN**:
- **Personal talents** (points from leveling): a **tree-like** 6-branch system — Power (damage/crit) / Haste (multi-shot) / Range (pierce) / Sprint (dodge) / Vitality (lifesteal/regen/defense) / Wealth (xp/gold), with mutually-exclusive build choices.
- **Weapon talents** (independent per weapon, **38 thematic nodes** each, points from weapon level): Blade (slash/air-blade/bleed/crit), Revolver (burst/spinner/burn/lock-on), Whip (multi-lash/entangle/lifesteal), Staff (elemental scatter/frost/lightning chain), Splitter (split/secondary split/shrapnel), Black Hole Gun (gravity/collapse/void erosion), Boomerang (return-pierce/multi/magnet/armor-break). Press T to open the talent menu, click a weapon to switch its tree, pick 1 of 3 drawn talents.
