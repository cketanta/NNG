# NNG — 类吸血鬼幸存者 2D 生存刷怪游戏
# NNG — Vampire-Survivors-like 2D Survival Shooter

> 当前版本 Current Version: **v1.3.0**
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

## 玩法循环 Gameplay Loop

**中文**：开局选**难度**（简单/普通/困难），以初始「破旧手枪」直接开战，武器环绕玩家旋转。每波 25 秒，敌人随时间变多变快；波末清场进入**商店**（买武器 / 买道具 / 出售 / 合成），点「开始下一波」继续。打怪掉落经验宝石与金币（靠近自动磁吸）、概率掉红心回血；升级获得**人物天赋点**；生命归零进入结算界面（难度 / 击杀 / 波次 / 等级 / 金币 / 时间）。

**EN**: Pick a difficulty (Easy/Normal/Hard) at start, then fight with the starter pistol while weapons orbit around you. Each wave lasts 25s and gets tougher; after clearing, enter the shop (buy weapons / items, sell, merge) then start the next wave. Enemies drop XP gems and coins (auto-magnet), sometimes hearts to heal. Leveling up grants **personal talent points**. Game over shows a summary (difficulty / kills / wave / level / gold / time).

## 武器系统 Weapon System

**中文**：最多持有 **8 把武器**（槽位），武器环绕玩家旋转、每把独立瞄准攻击，各有独立**等级**与**天赋树**。商店售卖**短刃**（近战挥砍）与**左轮**（远程高伤）：有空槽入槽，槽满且已有同名则自动合成升级。**合成**（仅商店）：在槽位点选两把同名武器，等级相加、保留高等级天赋树、多出等级转为天赋点。**出售**：可卖任意武器（含初始手枪），价格 = 购买价值一半。武器等级 Lv.N 提供 N 点该武器的天赋点。

**EN**: Hold up to **8 weapons** (slots) orbiting the player, each aiming and firing independently with its own **level** and **talent tree**. The shop sells **Blade** (melee slash) and **Revolver** (ranged heavy): empty slot = add; full slots with a same-name weapon = auto-merge. **Merge** (shop only): click two same-name weapons, levels sum up, keep the higher-level talent tree, excess levels become talent points. **Sell** any weapon (including the starter pistol) for half its value. Weapon level N grants N talent points for that weapon.

## 天赋系统 Talent System

**中文**：
- **人物天赋**（升级获得点数）：疾跑（移速 +10%/级）、迅捷（攻速 +8%/级）、延伸（范围 +12%/级）、狂力（伤害 +10%/级），各 5 级，加成作用于所有武器。
- **武器天赋**（每把武器独立，等级提供点数）：短刃——范围 / 伤害 / 攻速强化、气刃斩与大回旋、狂战（变大加速加伤）、多刀流、致残流血；左轮——弹头 / 弹匣（连续发射）/ 攻速强化、转盘枪手（右键扔枪旋转攻击）、子弹追踪。按 T 打开天赋界面，点选武器切换其天赋树，三选一加点。

**EN**:
- **Personal talents** (points from leveling): Sprint (+10% speed/level), Swift (+8% attack speed/level), Reach (+12% range/level), Power (+10% damage/level), 5 tiers each, applying to all weapons.
- **Weapon talents** (independent per weapon, points from weapon level): Blade — range/damage/speed boosts, Air Blade & Grand Slash, Berserk (bigger/faster/stronger), multi-slash, bleeding; Revolver — bullet/magazine (consecutive fire)/speed boosts, Spinner (RMB throws the gun), homing bullets. Press T to open the talent menu, click a weapon to switch its tree, pick 1 of 3 drawn talents.
