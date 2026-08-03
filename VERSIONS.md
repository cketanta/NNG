# 版本日志

本文件记录每个版本的快照信息，用于随时回退到历史版本。

**约定**：每次说「记作版本」，就按下面的格式在顶部追加一条记录（版本号递增，如 1.0.0 → 1.0.1 → 1.1.0），并保留此说明。

**导出约定**（2026-08-01 起）：每次「记作版本」的同时，自动执行一次导出并存档（无需另说）：
- 导出目录：项目根目录 `exports/`，每次导出的文件放在 `exports/v{版本号}/` 文件夹下（如 `exports/v1.1.2/`）
- 导出文件名沿用已有命名：`NNG_Ver{版本号}.exe`（Windows Desktop，`script_export_mode=2` 源码编译，`embed_pck=true` **单文件**，资源内嵌 exe、无外置 `.pck`）
- 命令：`godot --headless --export-release "Windows Desktop" exports/v{版本号}/NNG_Ver{版本号}.exe`
- 同时在导出文件夹内生成 `readme.txt`：最上方为当前版本的游戏操作介绍（随版本自行更新），下方按从新到旧记录 v1.0.0 → 当前版本的更新内容摘要（面向玩家，只写内容、不写代码与原理）
- 不做 zip 压缩（2026-08-01 取消）
- `export_presets.cfg` 的 `export_path` 同步更新到当前版本路径（保证编辑器内导出一致）

---

## v1.4.0

**日期**：2026-08-03
**状态**：天赋系统效果驱动重构 + 武器库扩充（8 把武器全满槽、110 天赋节点）+ UI 精致化（真树布局 + 9-patch 贴图）+ 分辨率 1920×1080 适配 + 美术全面强化（图标/特效/HUD/主菜单/结算）。

**包含内容**：
- **天赋系统重构**：`TalentTree` 节点加 `effects` 字段 + `aggregate()` 效果驱动聚合；人物天赋从 4 分支线性改为**树状多维**（暴击/暴击伤害/吸血/闪避/再生/防御/生命上限/经验/金币加成，暴击流↔连珠流互斥）；武器等级 N = N 点武器天赋点不变
- **武器库扩充**：重新接入鞭子/法杖/分裂者/黑洞枪 + 新造**回旋镖**（往返穿透弹），商店可购武器达 7 把 + 初始手枪共 8 槽全满；每把 10 节点天赋树；武器节点总数 88 + 人物 22 = **110 天赋节点**
- **修复**：左轮转盘枪手无法触发（改监听右键输入）；武器侧道具加成失效（火药/磨刀石/咒戒等，新增 `player.weapon_item_effects`）；狂战覆盖人物移速（改乘算叠加）
- **新机制**：暴击/吸血/穿透/额外弹/闪避/再生/经验金币加成/毒 DOT/黑洞坍缩/回旋镖往返
- **UI 精致化**：天赋树重写为**真树布局**（父子垂直对齐 + 贝塞尔连线 + 圆角节点 + 可滚动）；全 UI 换 **9-patch 贴图边框背景**（`assets/ui/`）；卡片矩形化；商店三列布局 + 新增「已有道具」区
- **分辨率**：项目窗口 1280×720 → **1920×1080**（canvas_items 自适应缩放），全局字号/间距/面板宽度按 1080p 放大
- **美术强化**：武器/子弹/道具 SVG 重绘（渐变+描边+高光）；敌人/玩家/掉落物代码绘制升级（渐变身体/独眼朝向/光晕/旋转高光）；HUD 渐变血条+状态栏浮层+低血量闪烁；战斗特效（命中爆闪/上飘伤害数字/死亡粒子/受击闪白/暴击屏幕震动）；主菜单浮动星光+艺术标题+入场动画；结算页逐条浮现动画

**关键文件**（回退时对照）：
- `scripts/systems/talent_tree.gd` / `player_talent.gd`：效果驱动天赋 + 人物树状天赋
- `scripts/attacks/*.gd`、`scripts/weapons/*.gd`：whip/staff/splitter/black_hole_gun 重写为天赋驱动、`boomerang.gd`/`boomerang_projectile.gd` 新增、`projectile.gd` 扩展（暴击/吸血/穿透/毒/黑洞参数）
- `scripts/player.gd`、`scripts/main.gd`、`scripts/weapons/weapon_manager.gd`
- `scripts/ui/*.gd`、`assets/ui/`（panel_bg/button/title_bar/bg_full/hp_xp 条）、`assets/items/`（14 道具图标）、`assets/weapons/`、`assets/projectiles/`
- `scripts/effects/fx.gd` / `hit_fx.gd` / `damage_number.gd` / `death_fx.gd` / `starfield.gd`（战斗特效）
- `scripts/enemies/enemy_base.gd`、`scripts/items/xp_gem|coin|heart.gd`、`scripts/hud.gd`
- `themes/cjk_theme.tres`、`scenes/main.tscn`、`project.godot`（分辨率）
- `tests/`：新增 talent_tree/whip/staff/splitter/bhg/boomerang 测试，重写 player_talent/talent

**导出**：`exports/v1.4.0/NNG_Ver1.4.0.exe`（单文件，`embed_pck=true`）+ `readme.txt`。

**备注**：23 个无头测试全过。遗留 `attack_select_panel.gd`/`talent_tree_ui.gd`/`start_panel.gd` 孤儿脚本保留未删。

## v1.3.0

**日期**：2026-08-02
**状态**：武器商店化重构：武器改为商店售卖 + 恢复等级系统 + 武器环绕玩家（8 槽位）+ 同名合成；每武器独立天赋树（等级=点数）；人物天赋恢复 v1.0 原方案（升级发点）；商店恢复道具售卖 + 武器出售；UI 全屏化。

**包含内容**：
- 武器库存：8 个武器槽位，每把武器独立等级与天赋树；初始破旧手枪 Lv.1；**武器环绕玩家旋转**（半径 34、缓慢自转），每把独立瞄准、独立开火
- 商店售卖武器（短刃/左轮）：有空槽 → 入槽；槽满且已有同名 → **自动合成**；槽满且无同名 → 禁止购买；武器等级恢复（购买价值 = 基础价 ×(1+0.5×(等级-1))）
- **合成（仅商店）**：商店武器槽位点选两把同名武器 → 等级相加、保留高等级武器天赋树与已点天赋、点数 = 新等级 − 已点天赋数
- 每武器独立天赋树：短刃/左轮两棵树数据不变，但**每把武器独立一份**（owned + points）；**武器等级 N = N 点武器天赋点**；天赋界面点选武器切换其天赋树，三选一加点
- 人物天赋恢复 v1.0 原方案：疾跑/迅捷/延伸/狂力 4 分支线性树，**升级 +1 人物天赋点**（与经验挂钩）；人物天赋倍率作用于所有武器
- 商店恢复道具售卖（每波 5 个随机）+ **武器出售**（售价 = 当前购买价值一半，含初始手枪；商店不卖手枪）
- 左轮「弹匣扩容」改为**连续发射**（一次冷却内沿瞄准方向连射多枚，非齐发散射）
- UI 全屏：背包（属性/武器[无天赋]/道具）；天赋界面（属性/人物天赋/武器天赋）；商店（槽位合成出售/武器购买/道具购买）

**关键文件**（回退时对照）：
- `scripts/systems/player_talent.gd`（新增）：人物天赋
- `scripts/player.gd`：`weapon_slots` 槽位、`add_weapon/combine_slots/remove_slot`
- `scripts/weapons/weapon_manager.gd`：多武器环绕 + 按槽位动态实例化
- `scripts/attacks/pistol|blade|revolver.gd`：per-weapon 天赋树 + 左轮连射
- `scripts/main.gd`：商店购买/合成/出售、升级发人物天赋点
- `scripts/ui/shop_panel|talent_panel|backpack_panel.gd`（重写）、`debug_panel.gd`
- `scenes/player.tscn`（移除固定武器节点）、`scenes/main.tscn`（移除 AttackSelectPanel）
- `tests/`：新增 `player_talent_test`/`synthesis_test`，重写 shop/talent/backpack/start/debug/weapons/blade/revolver

**导出**：`exports/v1.3.0/NNG_Ver1.3.0.exe`（单文件，`embed_pck=true`）+ `readme.txt`（操作介绍 + 各版本更新摘要）。

**备注**：17 个无头测试全过。**遗留**：`attack_select_panel.gd`（v1.2.0 停用）、`talent_tree_ui.gd`/`start_panel.gd`（孤儿脚本）保留未删。

## v1.2.0

**日期**：2026-08-02
**状态**：武器与天赋系统重做：单一攻击方式（初始破旧手枪，首次升级二选一短刃/左轮）+ 围绕攻击方式的树状天赋（三选一加点、T 键面板）+ 空商店（道具系统暂停使用）+ 分裂者/黑洞枪游戏内移除。

**包含内容**：
- 攻击方式系统：玩家只持有一把攻击方式，发射中心 = 玩家自身；初始「破旧手枪」（单发子弹），首次升级二选一「短刃」（近战挥砍）/「左轮手枪」（远程高伤）；旧多武器环绕旋转停用（WeaponManager 框架保留，改单攻击控制）
- 首次升级主动弹出「选择攻击方式」（短刃/左轮二选一），选中后固定；之后升级只发 1 天赋点 + 屏幕下方一行文字提示（不弹窗），T 键随时打开天赋树面板加点
- 天赋树重做（`talent_tree.gd`）：两棵树（短刃 23 天赋 / 左轮 15 天赋），每天赋支持前置（prereq）与互斥（conflict，气刃斩↔狂战）；「可选集合」+ 每次加点从可选天赋抽 3 选 1
- 短刃天赋：范围扩大 / 利刃出鞘 / 拔刀术 线性分支；气刃斩 + 气刃专精 + 气刃大回旋（环形波 2× 伤害）；狂战（移速+30%/伤害+20%/攻速+20%/体型+50%）；双/三/四刀流；致残（流血叠 30 层，郁色创伤 → 50 层，受击额外流血层数伤害）
- 左轮天赋：弹头改良 / 弹匣扩容 / 快枪手 线性分支；转盘枪手（右键特殊攻击：扔出手枪到右键位置旋转攻击一周，子弹密度由攻速决定，期间无法主动攻击）；枪斗术（微弱追踪）/ 智能制导（追踪增强）
- 商店改为空商店：删除武器升级区与道具出售（道具系统暂停使用，`ItemDefs`/`buy_item` 框架保留）；只显示金币/玩家状态 + 「开始下一波」
- 背包改为 属性 / 攻击方式（含已点天赋概览）/ 道具 三列
- 分裂者、黑洞枪游戏内移除（脚本与贴图保留框架）
- 新增 input：`toggle_talent`（T）、`special_attack`（鼠标右键）
- 新贴图：`pistol.svg / blade.svg / revolver.svg` + `pistol_bullet / revolver_bullet / blade_air_wave` 子弹

**关键文件**（回退时对照）：
- `scripts/attacks/pistol.gd|blade.gd|revolver.gd|spinner.gd`（新增）：攻击方式实现
- `scripts/systems/talent_tree.gd`（重写）：两棵树 + 前置/冲突/抽三
- `scripts/ui/talent_panel.gd`（重写，树概览+三选一）、`scripts/ui/attack_select_panel.gd`（新增）
- `scripts/weapons/weapon_manager.gd`：多武环绕 → 单攻击控制（保留瞄准/halt）
- `scripts/main.gd`：攻击方式选择/升级发点/天赋/空商店流程
- `scripts/player.gd`：天赋树注入、体型倍率、移速倍率
- `scripts/enemies/enemy_base.gd`：流血系统（`add_bleed`）
- `scripts/weapons/projectile.gd`：子弹追踪 + 新视觉类型
- `scripts/ui/shop_panel.gd|backpack_panel.gd`（重做）、`scripts/hud.gd`（天赋提示行）
- `scenes/player.tscn|main.tscn`、`scenes/weapons/pistol|blade|revolver.tscn`（新增）
- `project.godot`：T / 右键 action

**导出**：`exports/v1.2.0/NNG_Ver1.2.0.exe`（单文件，`embed_pck=true`）+ `readme.txt`（操作介绍 + 各版本更新摘要）。

**备注**：15 个无头测试全过（新增 `blade_test`/`revolver_test`；重写 `talent/shop/start/backpack/weapons/debug_test`；适配 `smoke/combat/difficulty`；`item_test` 移除已删武器公式断言；`hang_probe` 保留）。**遗留**：`start_panel.gd`、`talent_tree_ui.gd` 因系统重做成为未引用孤儿脚本（保留未删，如需删除另说）。

## v1.1.2

**日期**：2026-08-01
**状态**：道具块状卡片显示 + 测试模式调试面板（L 键）+ 背包/武器/玩家渲染优化 + 游戏结束整链停火 + 导出存档体系（单文件 + readme）+ 程序图标（玩家占位）。

**包含内容**：
- 道具显示块状化：`UiStyle.item_card()/card_label()` 新增，背包道具区、商店左侧道具栏、商店右侧购买区全部改为每道具一张圆角卡片（稀有度色名称×数量 + 描述），上下堆叠以卡片边框区分
- 测试模式：难度面板新增第 4 项「测试模式」，直接进选武器开局（普通倍率），本局可按 L 打开调试面板
- 调试面板（`debug_panel.gd`，L 唤出、暂停态、ScrollContainer 滚动）：调 当前波数（立即清怪重开）/ 每波时间 / 金币 / 角色等级 / 角色属性（移速/防御/血量/幸运）/ 武器等级（下一帧由 WeaponManager 自动同步）；道具区每行 [-1][数量输入][+1]，可无限增/减/直接输入数量
- 背包武器区：只显示已获得（level>=1）武器，未获得武器不占行（空时显示「暂无武器」）
- 渲染优化：武器贴图由 `const preload` 改懒加载（首次可见绘制时才 load 并缓存，未装备武器不加载）；武器与玩家初始 `visible=false`，开局菜单（难度/选武）阶段不渲染，进入战斗才显示
- 游戏结束停火（真实根因）：子武器节点独立 `_process` 会保留最后的 `_firing` 继续开火；新增 `WeaponManager.halt()` 停整条武器链（WeaponManager + 所有子武器），`player.die()` 与 `main.end_game()`（死亡/主动结束）均调用
- 背包道具卡片移除「总加成」显示行
- 调试用 setter：`player.gd` 新增 `set_gold/set_level/set_max_hp/set_defense/set_speed/set_luck/set_weapon_level/remove_item`，各自 emit 信号自动刷 HUD；`main.debug_set_item_count` 按差额逐次增减保证玩家侧效果与计数一致
- 导出存档体系（2026-08-01）：项目根新增 `exports/` 目录存放导出物；`export_presets.cfg` 导出路径改到项目内 `exports/v{版本号}/`、`embed_pck=true` **单文件**（资源内嵌 exe、无外置 pck）；约定「记作版本」时自动导出，并在版本文件夹内生成 `readme.txt`（顶部操作介绍 + 各版本更新摘要，面向玩家不写代码/原理），详见文件头「导出约定」
- 程序图标（2026-08-01）：`assets/icon.svg`（复现玩家占位外观：深蓝/亮蓝同心圆 + 白心）+ 工具 `scripts/tools/icon_gen.gd`（SVG → 256×256 PNG）生成 `assets/icon.png`；`export_presets.cfg application/icon` 与 `project.godot config/icon` 均指向它，导出 exe 与编辑器运行时的窗口标题栏/任务栏图标均为玩家图标

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
- `project.godot`：新增 `toggle_debug` action（L 键）；`config/name="NNG"`、`config/icon`
- `assets/icon.svg`（新增）、`assets/icon.png`（新增）：程序图标（玩家占位外观）
- `scripts/tools/icon_gen.gd`（新增）：SVG→PNG 图标生成工具
- `export_presets.cfg`：导出路径入 `exports/`、`embed_pck=true`、`application/icon`
- `.gitignore`：忽略 `exports/`（导出产物不入库）
- `tests/debug_test.gd`（新增）、`combat/result/difficulty/start/debug` 断言扩展

**已知问题（本版本不带）**：
- 分裂者分裂小弹出生即被母弹命中点敌人消耗（实际存活数偏少）——1.0.0 已知，未修
- 分裂者全向环密度饱和后视觉难分辨数量——按用户选择不改
- 高密度+满级武器长时间下存在物理引擎卡死隐患——1.0.0 已知，未修

**导出**：`exports/v1.1.2/NNG_Ver1.1.2.exe`（单文件，`embed_pck=true`，2026-08-01 重新导出；含程序图标 `assets/icon.png`，玩家占位外观：深蓝/亮蓝同心圆+白心）+ `exports/v1.1.2/readme.txt`（操作介绍 + 各版本更新摘要）。

**备注**：全量 13 个无头测试全过（新增 debug_test；扩展 combat/result/difficulty/start/debug 断言）。导出存档体系、程序图标、`config/name="NNG"` 并入 v1.1.2 后重新提交 git；导出产物 `exports/` 不入库（随时可一键重新导出）。

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
