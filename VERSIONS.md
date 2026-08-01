# 版本日志

本文件记录每个版本的快照信息，用于随时回退到历史版本。

**约定**：每次说「记作版本」，就按下面的格式在顶部追加一条记录（版本号递增，如 1.0.0 → 1.0.1 → 1.1.0），并保留此说明。

---

## v1.1.2

**日期**：2026-08-01
**状态**：道具块状卡片显示 + 测试模式调试面板（L 键）+ 背包/武器/玩家渲染优化 + 游戏结束整链停火。

**包含内容**：
- 道具显示块状化：`UiStyle.item_card()/card_label()` 新增，背包道具区、商店左侧道具栏、商店右侧购买区全部改为每道具一张圆角卡片（稀有度色名称×数量 + 描述），上下堆叠以卡片边框区分
- 测试模式：难度面板新增第 4 项「测试模式」，直接进选武器开局（普通倍率），本局可按 L 打开调试面板
- 调试面板（`debug_panel.gd`，L 唤出、暂停态、ScrollContainer 滚动）：调 当前波数（立即清怪重开）/ 每波时间 / 金币 / 角色等级 / 角色属性（移速/防御/血量/幸运）/ 武器等级（下一帧由 WeaponManager 自动同步）；道具区每行 [-1][数量输入][+1]，可无限增/减/直接输入数量
- 背包武器区：只显示已获得（level>=1）武器，未获得武器不占行（空时显示「暂无武器」）
- 渲染优化：武器贴图由 `const preload` 改懒加载（首次可见绘制时才 load 并缓存，未装备武器不加载）；武器与玩家初始 `visible=false`，开局菜单（难度/选武）阶段不渲染，进入战斗才显示
- 游戏结束停火（真实根因）：子武器节点独立 `_process` 会保留最后的 `_firing` 继续开火；新增 `WeaponManager.halt()` 停整条武器链（WeaponManager + 所有子武器），`player.die()` 与 `main.end_game()`（死亡/主动结束）均调用
- 背包道具卡片移除「总加成」显示行
- 调试用 setter：`player.gd` 新增 `set_gold/set_level/set_max_hp/set_defense/set_speed/set_luck/set_weapon_level/remove_item`，各自 emit 信号自动刷 HUD；`main.debug_set_item_count` 按差额逐次增减保证玩家侧效果与计数一致

**关键文件**（回退时对照）：
- `scripts/ui/debug_panel.gd`（新增）：测试模式调试面板
- `scripts/weapons/weapon_manager.gd`：新增 `halt()` 停整条武器链
- `scripts/player.gd`：调试 setter + `remove_item` + `die()` 停武器链
- `scripts/ui/backpack_panel.gd`：道具卡片化、武器区动态只显示已获得、移除总加成
- `scripts/ui/shop_panel.gd`：库存区/购买区卡片化
- `scripts/ui/ui_style.gd`：新增 `item_card/card_label`
- `scripts/ui/difficulty_panel.gd`：新增「测试模式」按钮
- `scripts/weapons/whip/staff/splitter/black_hole_gun.gd`：贴图懒加载 + 初始隐藏
- `scenes/main.tscn`：新增 DebugPanel 节点
- `project.godot`：新增 `toggle_debug` action（L 键）
- `tests/debug_test.gd`（新增）、`combat/result/difficulty/start/debug` 断言扩展

**已知问题（本版本不带）**：
- 分裂者分裂小弹出生即被母弹命中点敌人消耗（实际存活数偏少）——1.0.0 已知，未修
- 分裂者全向环密度饱和后视觉难分辨数量——按用户选择不改
- 高密度+满级武器长时间下存在物理引擎卡死隐患——1.0.0 已知，未修

**备注**：全量 13 个无头测试全过（新增 debug_test；扩展 combat/result/difficulty/start/debug 断言）。

## v1.1.1

**日期**：2026-08-01
**状态**：UI 暗色主题美化 + 结算界面（含暂停菜单「结束该局」）+ Esc 交互修复。

**包含内容**：
- UI 美化：新增 `scripts/ui/ui_style.gd` 程序化 StyleBoxFlat 工厂（面板/分节/标题栏），`themes/cjk_theme.tres` 统一暗色主题（Panel/Button/ProgressBar/Label），HUD 血条/经验条填充色、金币底框、悬浮文字阴影一并配套
- 结算界面：增强 `GameOverPanel`（加 `process_mode=3`，暂停态下可点按钮），死亡与主动结束共用，显示 难度/击杀/到达波次/玩家等级/金币/存活时间，新增「退出游戏」按钮
- 暂停菜单「结束该局」：暂停菜单新增按钮 → `end_game_from_pause()` → 统一结算流程 `end_game(reason)`（死亡=「游戏结束」，主动结束=「本局结束」）
- Esc 交互修复（真实根因）：Godot 输入分发为「深度优先逆序」——面板先于 main 收到同一事件；各面板处理 Esc 后加 `get_viewport().set_input_as_handled()` 阻断事件继续传给 main，避免 main 随后再弹暂停菜单（原表现为：暂停按 Esc 关掉又弹回、背包按 Esc 跳到暂停菜单）
- Esc 效果：暂停菜单按 Esc → 回到游戏；背包/商店/天赋等面板按 Esc → 返回上一级（回到游戏），不弹暂停菜单

**关键文件**（回退时对照）：
- `scripts/ui/ui_style.gd`（新增）：StyleBoxFlat 工厂
- `themes/cjk_theme.tres`：暗色主题
- `scripts/hud.gd` + `scenes/main.tscn`：结算面板 + HUD 美化
- `scripts/main.gd`：`end_game`/`end_game_from_pause` + `_unhandled_input` handled 标记
- `scripts/ui/pause_panel.gd`：新增「结束该局」按钮 + Esc handled
- `scripts/ui/backpack_panel.gd` / `shop_panel.gd` / `start_panel.gd` / `talent_panel.gd`：Esc handled 标记
- `tests/result_test.gd`（新增）、`tests/pause_test.gd`（重写为真实分发顺序）

**已知问题（本版本不带）**：
- 分裂者分裂小弹出生即被母弹命中点敌人消耗（实际存活数偏少）——1.0.0 已知，未修
- 分裂者全向环密度饱和后视觉难分辨数量——按用户选择不改
- 高密度+满级武器长时间下存在物理引擎卡死隐患——1.0.0 已知，未修

**备注**：13 个无头测试全过（新增 result_test；重写 pause_test 按真实输入分发顺序模拟 Esc，修复前该测试掩盖了双开 bug）。

## v1.1.0

**日期**：2026-08-01
**状态**：属性系统 + 14 道具系统 + 商店/背包 UI 重做 + 红心机制 + 天赋树停用 + 法杖散射扇角封顶。

**包含内容**：
- 属性系统：人物（移速/防御/血量/幸运）、武器（攻击/射速/弹速/攻击距离）；数值规则「先加算后乘算」→ `最终 = (基础 + Σ加算) × Π乘算`，公式集中在 `ItemDefs.weapon_final_stats`
- 14 个道具（`scripts/systems/item_defs.gd`）：稀有度 普通6/优质12/史诗15/传说25，咒戒为唯一物品（刷怪效率×2 + 全武器攻击×1.5）；加算类（爆破弹/好钢/瞄准镜/跑鞋/盔甲/试剂/绷带/幸运草）、乘算类（火药/磨刀石/润滑剂/刀柄/锻锤×1.1）
- 道具获取：每波商店随机刷 5 个不重复道具，**每个道具本波仅可购买一次**（跨波可重复），唯一道具购买后不再刷出；武器侧效果由 WeaponManager 每帧算终值下发，玩家侧效果购买即生效
- 防御减伤：每点防御减 1 点伤害，最低 1 点
- 红心机制：新增 `heart.gd/heart.tscn`，打怪掉率 = 5% + 5%×幸运值，拾取回 1 血
- 商店 UI 重做：左展示区（玩家属性｜武器｜道具栏）+ 右购买区（武器升级｜道具购买），整体包 ScrollContainer 纵向滚动
- 背包 UI 重做：横向三列（玩家属性｜武器｜道具），整体包 ScrollContainer 纵向滚动
- 天赋树停用：升级不再发天赋点、不弹天赋窗；框架/场景保留待后续重做，背包内天赋树移除
- 法杖散射扇角封顶：相邻角 = min(12°, 360°/弹数)，绕满一圈后子弹在 360° 内均匀变密、方向永不重叠（修复「绕一周后升级视觉不再提升」）
- 武器 `set_stats` 重构：签名改为 `(final_damage, final_cooldown, final_speed, final_range)`，由 WeaponManager 按道具计算

**关键文件**（回退时对照）：
- `scripts/systems/item_defs.gd`（新增）：道具数据表 + 武器终值公式
- `scripts/items/heart.gd` + `scenes/items/heart.tscn`（新增）：红心
- `tests/item_test.gd`（新增）：道具系统测试
- `scripts/player.gd`：道具持有/防御/幸运/治疗/移速加算
- `scripts/main.gd`：红心掉落、道具购买、商店刷新、天赋停用
- `scripts/weapons/weapon_manager.gd`：武器属性终值计算
- `scripts/weapons/whip/staff/splitter/black_hole_gun.gd`：统一 base_* 字段 + set_stats 新签名
- `scripts/ui/shop_panel.gd`、`backpack_panel.gd`：UI 重做

**已知问题（本版本不带）**：
- 分裂者分裂小弹出生即被母弹命中点敌人消耗（实际存活数偏少）——1.0.0 已知，未修
- 分裂者全向环密度饱和后视觉难分辨数量——按用户选择不改
- 高密度+满级武器长时间下存在物理引擎卡死隐患——1.0.0 已知，未修

**备注**：12 个无头测试全过（新增 item_test，适配 weapons/shop/talent/backpack）。git 提交 `a634608` 为 v1.0.1。

## v1.0.1

**日期**：2026-08-01
**状态**：给武器/子弹/黑洞加区分度贴图，武器环绕玩家旋转，子弹独立瞄准，鞭子改扇环。

**包含内容**：
- 新增 `assets/` 目录 10 个 SVG 占位贴图：4 武器（鞭子/法杖/分裂者/黑洞枪）、5 子弹（法杖蓝菱形/分裂者黄橙六角/分裂小弹/黑洞枪深紫/敌方绿）、黑洞核心；换正式美术只需替换对应 SVG 文件
- 武器本体可见：四把武器贴图随瞄准方向旋转；未装备（level 0）时隐藏
- 武器环绕玩家：WeaponManager 把武器均匀分布在半径 34 的圆周上缓慢自转（0.5 rad/s），避免贴图堆叠
- 子弹从武器枪口发射（发射点 = 武器位置 + 瞄准方向 30）
- 每把武器独立瞄准：各自从自身位置指向目标（最近敌人/鼠标），子弹汇聚不平行；无敌人时不开火
- 鞭子挥砍区改为扇环（内径 8 → 外径 base_range），以武器位置为出发点
- 黑洞核心贴图随半径（等级）略微变大：核心半径 = 12 + (radius - 130) * 0.03

**关键文件**（回退时对照）：
- `assets/weapons|projectiles|effects/*.svg`：新增贴图资源
- `scripts/weapons/weapon_manager.gd`：武器环布局 + 每武器独立瞄准
- `scripts/weapons/whip.gd`：扇环攻击区
- `scripts/weapons/projectile.gd`：子弹按类型贴图
- `scripts/items/black_hole.gd`：核心贴图随等级变大

**已知问题（本版本不带）**：
- 分裂者分裂小弹仍会立刻命中母弹刚打中的怪（分裂数略少）——1.0.0 已知，未修复
- 高密度+满级武器长时间下存在物理引擎卡死隐患——1.0.0 已知，未修复
- 分裂弹在 body_entered 里实例化会打印 `area_set_shape_disabled` 警告，无害

**备注**：git 首次提交 `7318397` 为 v1.0.0 基线；本版本改动未破坏无头测试（weapons/smoke/combat 已验证通过）。

## v1.0.0

**日期**：2026-07-31
**状态**：回退到今天工作开始前（仅保留「注释全部转中文」），作为干净的可玩基线。

**包含内容**：
- 基础框架：玩家（WASD 移动 + 自动索敌/手动瞄准 Tab 切换）、近战/远程两种敌人、定时波刷怪、HUD、Game Over
- 武器 4 把：鞭子（连斩段数）、法杖（散射弹数）、分裂者（全向分裂）、黑洞枪（命中产生黑洞）
- 黑洞：旋转粒子指示吸引范围（随等级扩大）、吸附子弹与怪物、怪物核心翻搅、黑洞 0 伤害、怪物只拖拽控场
- 经济：经验宝石+金币、经验升级弹天赋窗、商店买武器重复叠加、天赋树（疾跑/迅捷/延伸/狂力）、背包（B）
- 难度：简单/普通/困难；开局先选难度再选武器；Esc 暂停菜单（继续/重开/退出）
- 全部脚本/测试注释为中文

**关键文件**（回退时对照）：
- `scripts/main.gd`：状态机 + 难度（仅 easy/normal/hard）+ 商店/天赋/背包/暂停
- `scripts/enemies/enemy_base.gd`：黑洞拉拽用 velocity 驱动 + 核心瞬移翻搅（非幽灵体）
- `scripts/weapons/projectile.gd`：物理碰撞命中（body_entered）+ 被黑洞吸到核心抽搐
- `scenes/main.tscn`：含 DifficultyPanel / PausePanel 节点

**已知问题（本版本不带）**：
- 分裂者分裂小弹会立刻命中母弹刚打中的怪（分裂数略少）——这是后来修复的，但为保持基线已回退
- 高密度+满级武器长时间下存在物理引擎卡死隐患（后续单独排查，不在此版本修复）

**备注**：回退时保留了今天的「注释转中文」，并移除了测试模式、分裂者修复、防卡死实验性修改。
