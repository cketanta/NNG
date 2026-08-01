# 测试项目1 — 类吸血鬼幸存者雏形

> 当前版本：**v1.0.0**（见 `VERSIONS.md` 版本日志；以后每次「记作版本」都在那里追加）

基于 **Godot 4.7** 的 2D 平面刷怪生存游戏框架。所有角色/弹幕/拾取物目前都是纯色占位，无需外部素材。

## 运行方式

1. 用 Godot 4.7 打开项目根目录（`C:\Users\ASUS\Documents\Godot\测试项目1`）
2. 按 **F5** 运行
3. 主场景：`scenes/main.tscn`

## 操作

| 按键 | 功能 |
|---|---|
| **WASD** | 移动 |
| **Tab** | 切换攻击模式：自动索敌（AUTO）/ 手动瞄准（MANUAL，按住左键射击） |
| **B** | 打开背包（暂停），查看道具/金币/已解锁天赋，可花攒下的天赋点 |
| **Esc** | 战斗中唤出暂停菜单（继续/重新开始/退出游戏）；其他界面返回上一级（选武面板→难度、商店/天赋/背包/菜单→战斗） |

## 玩法循环

**开局流程**：先选**难度**（简单/普通/困难，只影响刷怪速率、怪物血量、怪物攻击力），再选初始武器（鞭子/法杖），然后开战。

**暂停菜单**：战斗中按 **Esc** 唤出（背景暂停），可继续 / 重新开始 / 退出游戏。

**定时波**：每波 25 秒，敌人随时间变多变快。波结束后清场 → 自动进**商店**（暂停）→ 关店进入下一波。

- **打怪掉落**：经验宝石（青）+ 金币（黄），靠近自动磁吸拾取
- **经验**：满格升级 → 弹**天赋窗**（暂停）+1 天赋点，点数可攒
- **商店**（每波一次）：售卖 4 把武器，价格随等级递增；**重复购买叠加效果**
  - **鞭子（近战）**：每级 +1 挥砍段数 → 连斩逐段扇出，刀光前后分明
  - **法杖（远程）**：每级 +1 子弹数量（散射弹幕，相邻弹间隔 12°）
  - **分裂者（远程）**：命中后全向分裂小弹，每级分裂 +1 枚（基础 2）
  - **黑洞枪（远程）**：命中产生黑洞，吸附子弹与怪物（子弹在中心抽搐不消失、仍可互相造成伤害，黑洞本身 0 伤害，怪物只拖拽不击杀；黑洞范围随等级扩大）
- **天赋树**（升级弹出 / 背包内也可花点）：四条分支各 5 级
  - **疾跑**：移动速度 +10%/级
  - **迅捷**：攻击速度 +8%/级
  - **延伸**：攻击范围 +12%/级
  - **狂力**：伤害 +10%/级
  - 全部点满后升级不再弹天赋窗
- **背包**（B）：查看武器等级及**对应等级的效果**、金币、天赋点与已解锁天赋
- **游戏结束**：生命归零 → Game Over → 重新开始

## 自动化测试

10 个**无头冒烟测试**，改代码后一键验证核心逻辑：

```bash
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/gem_test.gd
godot --headless --path . --script res://tests/combat_test.gd
godot --headless --path . --script res://tests/shop_test.gd
godot --headless --path . --script res://tests/talent_test.gd
godot --headless --path . --script res://tests/backpack_test.gd
godot --headless --path . --script res://tests/start_test.gd
godot --headless --path . --script res://tests/weapons_test.gd
godot --headless --path . --script res://tests/difficulty_test.gd
godot --headless --path . --script res://tests/pause_test.gd
```

（godot 不在 PATH 时用完整路径，如 Steam 版：
`"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"`）

- `smoke_test`：输入动作 / 波次刷怪 / 武器击杀 / 掉宝石+金币
- `gem_test`：经验宝石→经验、金币→金币 的磁吸拾取链路
- `combat_test`：模式切换+HUD / 弹幕伤害 / 接触伤害 / Game Over
- `shop_test`：商店暂停 / 买武器叠等级扣金币 / 关店进下一波 / 武器节点同步
- `talent_test`：升级弹天赋窗+暂停 / 花点生效（含伤害分支）/ 关窗恢复
- `backpack_test`：背包暂停 / 显示金币道具 / 在背包内花攒下的天赋点
- `start_test`：开局流程（先难度后选武、START 暂停、选完开战、未选中武器 0 级）
- `weapons_test`：分裂者分裂 / 黑洞吸附 / 分裂数·黑洞半径随等级
- `difficulty_test`：难度流程 / 倍率下发 / 困难下怪血量攻击翻倍
- `pause_test`：Esc 暂停菜单开/关与暂停恢复

全部通过退出码 0，任一失败为 1。

## 项目结构

```
scenes/
  main.tscn            主场景（玩家 + 刷怪器 + HUD + 商店/天赋/背包/选武面板）
  player.tscn          玩家（含 4 把武器节点）
  enemies/             近战 / 远程敌人
  weapons/             鞭子 / 法杖 / 分裂者 / 黑洞枪 / 通用弹幕
  items/               经验宝石 / 金币 / 黑洞
scripts/
  main.gd              状态机(选武/战斗/商店/结束)、波次、暂停、购买/天赋接线
  spawner.gd           定时波刷怪
  player.gd            移动 / 受击 / 经验金币 / 武器等级 / 属性倍率
  enemies/             敌人基类（掉经验+金币、随波变强、可被黑洞拖拽）
  weapons/             武器管理器 + 四把武器 + 弹幕（分裂/黑洞/被吸抽搐）
  items/               宝石/金币磁吸拾取、黑洞吸附
  systems/talent_tree.gd  天赋树数据（四分支×5级、前置解锁）
  ui/                  选难度/选武/商店/天赋/背包/暂停面板 + 可复用天赋树控件
themes/cjk_theme.tres  中文默认字体主题
tests/                 10 个无头测试
```

## 碰撞层级（1~6）

| 层 | 掩码值 | 归属 |
|---|---|---|
| 2 | 2 | 玩家（身体 + 受击盒） |
| 3 | 4 | 敌人 |
| 4 | 8 | 友方弹幕 |
| 5 | 16 | 敌方弹幕 |
| 6 | 32 | 鞭子挥砍命中区 |

## 扩展方向（框架已预留）

- 商店每波随机上架（当前固定 4 把都上架）
- 更多武器/道具、武器每级差异化强化
- 黑洞升级（更大半径 / 更久）、分裂小弹二次分裂
- 敌人技能差异化、Boss 波
- 换真实美术（所有占位都是脚本 `_draw()` 画的，改成 Sprite2D 即可）

## 备注

- HUD / 面板文字用系统字体（微软雅黑等），跨平台显示异常可改 `themes/cjk_theme.tres`。
- 面板打开时 `get_tree().paused = true`，面板节点 `process_mode = WHEN_PAUSED`，所以暂停时按钮/关闭仍可用；`main.gd` 的 `auto_pause_menus` 可关（测试用）。
