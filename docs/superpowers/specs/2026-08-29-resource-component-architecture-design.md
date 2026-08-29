# LightTower 资源驱动组件架构设计规范

- 状态：待用户书面审阅
- 日期：2026-08-29
- 适用范围：敌人、关卡、塔、水晶、生成系统与 HUD 的后续制作和迁移
- 核心决策：采用“Resource 静态配置 + Scene 结构装配 + Node Component 运行行为 + 薄 Controller 协调”的架构

## 1. 背景

项目当前同时存在旧式大脚本、资源对象、场景继承和初步组件化代码。敌人侧已有 `MonsterData`、`MonsterBase`、`HealthComponent` 与 `MovementComponent`，关卡侧则仍由单个脚本同时管理关卡配置、刷怪、格子、水晶、HUD 和结算。目录迁移尚未完全收尾，部分场景和管理器仍引用旧路径。

现有 `HealthComponent` 和 `MovementComponent` 继承 `RefCounted`，由 `MonsterBase` 在运行时创建。这种方式能实现代码组合，但组件不会作为节点出现在场景树中，也无法直接在检查器里检查依赖、开关和配置。它不满足项目后续以 Godot 编辑器为主要内容制作入口的目标。

本规范统一资源、场景、组件和控制器的职责，并规定敌人与关卡的标准制作流程。迁移实施步骤不在本文件中展开，将在本规范批准后形成独立实施计划。

## 2. 目标

1. 所有可调平衡数值都能通过 `.tres` 和 Godot 检查器修改。
2. 所有核心功能都由职责明确的组件实现，并能在场景树中查看和替换。
3. 新增普通敌人时不修改关卡代码或敌人基类。
4. 新增关卡时不复制关卡控制器和刷怪器脚本。
5. 组件通过明确接口和信号协作，避免隐式父节点路径与跨模块直接访问。
6. 运行时状态与共享静态配置严格分离，避免 Resource 共享状态错误。
7. 迁移期间保持现有塔、子弹、水晶和刷怪器所需的敌人兼容接口。
8. 在编辑器中尽早发现资源缺失、组件缺失和非法配置。

## 3. 非目标

1. 本阶段不实现完整 ECS。
2. 本阶段不引入全局依赖注入框架或事件总线。
3. 本阶段不把每个辅助函数拆成单独组件。
4. 本阶段不强制把每组字段拆成独立 Resource 文件。
5. 本阶段不设计复杂路径寻找；敌人可继续使用直达水晶的移动方式。
6. 本阶段不重新设计全部塔玩法，但塔必须逐步接入相同的资源与组件边界。

## 4. 架构原则

### 4.1 四层职责

| 层 | 职责 | 可以保存的内容 | 不得保存的内容 |
|---|---|---|---|
| Resource | 定义静态配置和内容数据 | 最大生命、移速、波次、价格、贴图引用 | 当前生命、当前目标、当前波次 |
| Scene | 定义节点结构与组件装配 | 节点、碰撞体、组件、资源引用、编辑器布局 | 复杂规则和全局状态 |
| Component | 实现一个完整运行时职责 | 当前生命、移动状态、目标、计时器 | 无关模块的状态与 UI 细节 |
| Controller | 初始化、连线和提供稳定外部接口 | 必要的协调状态 | 组件内部算法与大量业务规则 |

### 4.2 单一事实来源

- 静态数值只在 Resource 中定义一次。
- 组件不得再导出一份与 Resource 同义的最大生命、速度或伤害字段。
- 场景只引用 Resource，不复制平衡数值。
- HUD 只监听信号，不维护第二份权威游戏状态。

### 4.3 组件粒度

组件必须满足以下至少两项条件：

- 拥有独立运行时状态；
- 拥有稳定输入与输出；
- 可以被其他对象复用；
- 可以被替换、禁用或单独测试；
- 负责一个可以清楚命名的业务能力。

仅被一个脚本使用的两三行辅助函数、单次文本格式化和纯粹为缩短文件而拆出的代码不作为组件。

### 4.4 通信方式

- Controller 可以调用其直接拥有组件的公共方法。
- Component 通过 signal 向外报告状态变化。
- Component 不直接调用 HUD、SceneManager 或不相关的兄弟组件。
- HUD 监听 Controller 或 Component 信号，不在 `_process()` 中轮询游戏状态。
- 不使用 `../../..` 形式寻找依赖；依赖通过检查器引用、唯一节点名或 Controller 注入。

## 5. Resource 规范

### 5.1 Resource 只保存静态配置

Resource 默认可能被多个场景实例共享。以下内容禁止写入 Resource：

- 当前生命；
- 当前目标；
- 已经受到的状态效果；
- 当前波次索引；
- 当前能量；
- 格子占用表；
- 本局击杀数。

这些内容必须保存在对应的 Node Component 实例中。

Resource 在运行时按只读配置使用。任何临时倍率、强化、难度修正或本局覆盖值都复制到组件状态中计算，不得回写原 Resource。确实需要运行时独立 Resource 副本时，必须显式 `duplicate(true)`，并由创建者负责其生命周期。

### 5.2 字段组织

第一阶段使用聚合 Resource，并通过 `@export_group` 按组件职责分组。只有满足以下条件时，才把一组字段提升为独立子 Resource：

- 该配置需要被不同对象独立复用；
- 字段数量已经妨碍检查器使用；
- 该配置具有独立版本或制作流程；
- 同一对象需要多个同类配置实例。

这样既保证检查器友好，也避免初期产生大量细碎 `.tres` 文件。

### 5.3 MonsterData

`MonsterData` 是敌人的静态内容资源，最低字段如下：

| 分组 | 字段 |
|---|---|
| Identity | `monster_id`、`display_name`、`monster_type` |
| Health | `max_health`、`armor` |
| Movement | `move_speed` |
| Contact | `contact_damage`、`reach_distance` |
| Status | `negative_status_resistance` |
| Reward | `score_value`、可选能量奖励 |
| Presentation | 可选图标、场景展示信息 |

`monster_id` 使用稳定的 snake_case 标识，例如 `streptococcus`。显示名称允许本地化，不作为代码标识。

速度单位统一为像素/秒，距离单位统一为像素。护甲和负面状态抗性使用归一化的 `0.0～1.0` 比例，并由对应组件限制合法范围；Resource 不自行执行承伤或状态计算。

### 5.4 LevelData

`LevelData` 定义关卡内容，不保存本局进度：

| 分组 | 字段 |
|---|---|
| Identity | `level_id`、`display_name` |
| Crystal | `crystal_max_health` |
| Economy | `starting_energy` |
| Build | `grid_config`、`allowed_towers` |
| Waves | `waves: Array[WaveData]` |
| Presentation | 背景、音乐或描述引用 |

### 5.5 WaveData 与 EnemySpawnEntry

`WaveData` 保存：

- 波次开始延迟；
- 波次结束后延迟；
- `Array[EnemySpawnEntry]`；
- 是否等待场上敌人清空再进入下一波。

`EnemySpawnEntry` 保存：

- `enemy_scene: PackedScene`；
- 数量；
- 单位生成间隔；
- 出生点 ID；
- 可选生成权重或批次间隔。

敌人出现波次属于关卡配置，不属于 `MonsterData`。

### 5.6 TowerData

现有 `TowerData` 继续作为塔静态配置来源。关卡只保存允许使用的塔场景或塔目录条目，不在关卡脚本中复制伤害、射速和子弹速度。

### 5.7 LevelCatalog 与 TowerCatalog

`LevelCatalog` 是选关界面的唯一关卡来源。每个条目至少保存：

- 稳定关卡 ID；
- 显示名称；
- 关卡 PackedScene；
- 是否默认解锁；
- 可选预览图。

选关界面从 LevelCatalog 生成或配置按钮，不使用固定 `LEVEL_COUNT` 推测文件存在，也不显示没有 PackedScene 的条目。

`TowerCatalog` 用于实验室、建造菜单和解锁系统共享塔目录。每个条目保存稳定塔 ID、TowerData 与 PackedScene。LevelData 的 `allowed_towers` 引用塔 ID 或目录条目，不复制 TowerData 字段。

## 6. Component 规范

### 6.1 基类选择

- 需要检查器、节点依赖、signal、Timer、`_process()` 或 `_physics_process()` 的组件继承 `Node`。
- 纯计算且无状态的工具可以使用静态函数或 `RefCounted`，但不称为场景组件。
- `HealthComponent` 和 `MovementComponent` 的目标形态为场景树中的 Node 组件。

### 6.2 生命周期

组件遵循统一生命周期：

1. 编辑器阶段：通过导出属性绑定必要资源与节点依赖；
2. `_ready()`：验证依赖，但不主动访问不相关系统；
3. `configure(...)`：由 Controller 注入静态配置或本局上下文；
4. `start()`：在所有组件完成配置后开始计时或处理；
5. 运行阶段：只处理本组件职责；
6. 退出阶段：停止计时器并解除必要连接。

组件不得依赖兄弟节点 `_ready()` 的偶然执行顺序。需要顺序时由 Controller 显式执行 `configure()` 和 `start()`。

### 6.3 配置校验

每个可在场景中使用的组件必须：

- 对缺失的必需资源给出 `_get_configuration_warnings()`；
- 对运行时不可恢复的缺失依赖使用 `push_error()`；
- 对可选节点使用明确的空值处理；
- 对范围型配置使用检查器范围提示，并在运行时再次限制边界。

### 6.4 公共组件目录

以下组件可跨敌人、水晶或其他可受伤对象复用：

- `HealthComponent`；
- `StatusEffectComponent`；
- 可选 `HitboxComponent` / `HurtboxComponent`；
- 可选 `LifetimeComponent`。

只属于特定域的组件保存在对应域目录，例如敌人移动、关卡波次和建造格子。

## 7. 敌人架构

### 7.1 标准场景树

```text
EnemyBase (CharacterBody2D, MonsterBase)
├─ Visual (Node2D)
│  └─ AnimatedSprite2D 或 Sprite2D
├─ CollisionShape2D
├─ HealthComponent
├─ MovementComponent
├─ TargetComponent
├─ ContactDamageComponent
├─ StatusEffectComponent          [可选]
├─ RewardComponent               [可选]
└─ HealthViewComponent           [可选]
```

普通敌人只需要继承基础场景、指定 `MonsterData`、配置视觉与碰撞体。只有真正不同的能力才新增组件，例如分裂、护盾、治疗或远程攻击。

### 7.2 组件职责

| 组件 | 输入 | 输出 | 不负责 |
|---|---|---|---|
| HealthComponent | 最大生命、伤害、治疗 | `health_changed`、`died` | 移动、奖励、删除节点 |
| MovementComponent | 速度、目标位置、减速倍率 | `destination_reached` | 选择目标、伤害水晶 |
| TargetComponent | 初始目标、目标切换规则 | `target_changed`、`target_lost` | 实际移动 |
| ContactDamageComponent | 接触伤害、目标 | `contact_damage_applied` | 目标生命实现 |
| StatusEffectComponent | 状态申请、抗性 | 状态添加、刷新、移除信号 | 基础生命 |
| RewardComponent | 奖励配置、死亡事件 | `reward_requested` | 直接修改 HUD |
| HealthViewComponent | HealthComponent 信号 | 更新血条与数字 | 修改生命 |

### 7.3 MonsterBase 职责

`MonsterBase` 是薄 Controller，只负责：

- 导出并验证 `MonsterData`；
- 获取必要组件引用；
- 按顺序配置组件；
- 连接核心信号；
- 加入统一的 `enemy` 分组；
- 提供外部兼容接口。

标准外部接口：

- `setup_target(target: Node2D)`；
- `take_damage(amount: int)`；
- `heal(amount: int)`；
- `died` 信号；
- `reached_target` 信号。

迁移期间可以保留只读 `damage` 兼容属性，供旧水晶代码读取。所有关卡迁移完成后，标准接口改为 `ContactDamageComponent` 或 `reached_target` 事件，随后删除兼容属性。

项目统一只使用 `enemy` 分组；旧 `1_enemy` 分组在迁移完成后删除。

### 7.4 死亡与到达目标

- HealthComponent 只发出一次 `died`。
- MonsterBase 或独立生命周期组件负责响应死亡并最终释放敌人。
- RewardComponent 监听死亡并请求结算奖励。
- 到达目标由 MovementComponent 发出事件，ContactDamageComponent 完成伤害申请，随后敌人进入已结算状态并释放。
- 死亡与到达目标必须互斥，任何敌人只能产生一种最终结算。

## 8. 关卡架构

### 8.1 标准场景树

```text
LevelBase (Node2D, LevelController)
├─ World (Node2D)
│  ├─ Background (Sprite2D)
│  ├─ BuildGrid (BuildGridComponent)
│  ├─ Crystal (Area2D, CrystalController)
│  │  ├─ CollisionShape2D
│  │  ├─ HealthComponent
│  │  └─ CrystalViewComponent
│  ├─ Towers (Node2D)
│  ├─ Enemies (Node2D)
│  └─ SpawnPoints (Node2D)
│     ├─ SpawnPointNorth (Marker2D)
│     └─ ...
├─ Systems (Node)
│  ├─ WaveSpawnerComponent
│  ├─ EconomyComponent
│  ├─ TowerPlacementComponent
│  └─ LevelGoalComponent
└─ HUD (CanvasLayer, LevelHUD)
```

Background 只负责视觉，不作为 Grid、Crystal 或其他游戏逻辑节点的父节点。缩放背景不得改变碰撞体、格子与世界坐标。

### 8.2 LevelController 职责

LevelController 只负责：

- 导出并验证 `LevelData`；
- 获取场景中的核心组件；
- 把 LevelData 配置传给组件；
- 连接胜利、失败与场景状态信号；
- 控制关卡启动、暂停和结束状态；
- 向 HUD 提供稳定信号。

LevelController 不负责直接生成每个格子、计算刷怪间隔、维护水晶生命、动态构建结算面板或实现建塔规则。

### 8.3 关卡组件职责

| 组件 | 主要职责 | 关键输出 |
|---|---|---|
| WaveSpawnerComponent | 顺序执行 WaveData，在出生点生成敌人 | `wave_started`、`wave_completed`、`all_waves_spawned` |
| BuildGridComponent | 坐标换算、合法性、禁建区、占用表 | `cell_selected`、`occupancy_changed` |
| TowerPlacementComponent | 选塔、价格检查、建造与拆除 | `tower_placed`、`placement_failed` |
| EconomyComponent | 当前能量、收入和消费 | `balance_changed` |
| LevelGoalComponent | 汇总波次、敌人数量与水晶状态 | `level_won`、`level_lost` |
| CrystalController | 协调水晶碰撞与 HealthComponent | `crystal_destroyed` |
| LevelHUD | 监听关卡信号并更新界面 | 用户操作信号 |

### 8.4 建造格子

标准实现使用坐标换算和 `Dictionary[Vector2i, Node2D]` 保存占用状态，不为每个格子创建默认开启监控的 Area2D。需要可视化时由 BuildGridComponent 绘制网格或使用 TileMapLayer。

BuildGridComponent 必须提供：

- 世界坐标转格子坐标；
- 格子坐标转世界坐标；
- 越界检查；
- 禁建区检查；
- 占用、释放与查询；
- 可选网格显示开关。

### 8.5 波次与胜负

关卡胜利条件固定为：

1. 所有 WaveData 已经生成完成；
2. `enemy` 分组中没有仍处于有效状态的敌人；
3. 水晶仍然存活。

关卡失败条件为水晶 HealthComponent 发出 `died`。胜利与失败只允许结算一次。

### 8.6 关卡实例方式

采用基础场景继承方案：

- `level_base.tscn` 保存公共节点与组件；
- 每一关创建轻量继承场景；
- 继承场景只指定 LevelData、背景、出生点与必要的地图布局差异；
- 不创建关卡专用 Controller 或 Spawner 脚本，除非该关卡确实包含独有机制；
- 独有机制以附加组件实现，不通过复制公共脚本实现。

## 9. 塔与关卡的边界

- 关卡只允许或禁止某种塔，不保存塔的战斗数值副本。
- TowerData 是塔数值的唯一来源。
- TowerPlacementComponent 只实例化塔场景并处理经济与格子占用。
- 塔自行负责模式、索敌和攻击。
- 旧 `tower_plasma_cell` 与新 `TowerBase` 体系不得长期并存；其迁移属于后续计划中的独立阶段。

## 10. 数据流

### 10.1 敌人生成

```text
LevelData
  → WaveSpawnerComponent 读取 WaveData
  → 实例化 Enemy PackedScene
  → MonsterBase 读取 MonsterData
  → MonsterBase 配置各 Node Component
  → TargetComponent 接收 Crystal
  → MovementComponent 开始移动
```

### 10.2 敌人受伤与死亡

```text
Tower / Projectile
  → MonsterBase.take_damage()
  → HealthComponent.take_damage()
  → health_changed → HealthViewComponent
  → died → RewardComponent + MonsterBase
  → LevelGoalComponent 通过敌人退出或事件重新判断胜利
```

### 10.3 敌人到达水晶

```text
MovementComponent.destination_reached
  → ContactDamageComponent
  → CrystalController / HealthComponent
  → enemy reached_target
  → 敌人结束并释放
```

### 10.4 建塔

```text
HUD 选择塔
  → TowerPlacementComponent 接收点击
  → BuildGridComponent 检查格子
  → EconomyComponent 尝试消费
  → 实例化 Tower PackedScene
  → BuildGridComponent 标记占用
  → HUD 通过信号刷新
```

## 11. 检查器制作规范

### 11.1 导出属性

- 必需 Resource 使用强类型导出。
- 必需节点依赖使用强类型节点引用或唯一节点名。
- 可选组件提供明确启用开关或允许为空。
- 数值字段使用范围、步长与后缀提示。
- 字段按 Identity、Health、Movement、Reward 等职责分组。
- 导出字段名称说明含义和单位，例如秒、像素/秒或百分比。

### 11.2 场景制作

- 公共场景通过继承复用，不复制节点树。
- 普通内容场景不得附加空的“占位脚本”。
- 特殊行为通过附加组件实现。
- 场景根节点、资源和文件使用稳定英文 snake_case 命名；编辑器显示名可以使用中文。
- 移动文件时优先使用 Godot 编辑器，保留 UID 与引用。

## 12. 目录规范

目标目录结构如下：

```text
base/
├─ components/
│  ├─ health_component.gd
│  └─ status_effect_component.gd
├─ enemy_base/
│  ├─ enemy_base.tscn
│  ├─ monster_base.gd
│  └─ components/
├─ level_base/
│  ├─ level_base.tscn
│  ├─ level_controller.gd
│  └─ components/
└─ tower_base/

data/
├─ enemies/
├─ levels/
├─ waves/
└─ towers/

scenes/
├─ enemies/
├─ levels/
├─ towers/
└─ ui/

scripts/
├─ enemies/abilities/
├─ levels/mechanics/
└─ towers/abilities/
```

共享组件放在 `base/components`；领域专用组件放在该领域的 `components` 子目录；仅某个内容使用的特殊能力放在 `scripts/<domain>/abilities` 或 `mechanics`。

## 13. 物理层规范

| 层 | 内容 | 典型检测对象 |
|---|---|---|
| 1 | EnemyBody | 世界障碍或水晶触发区 |
| 2 | Crystal | EnemyBody |
| 3 | Projectile | EnemyBody |
| 4 | TowerInteraction | 鼠标与塔交互 |
| 5 | BuildArea | 建造系统，不检测敌人 |

子弹、攻击范围和水晶只开启必要 mask。建造格子默认不参与敌人物理检测。

## 14. 错误处理

### 14.1 编辑器错误

以下情况必须产生配置警告：

- Controller 未指定主 Resource；
- 必需 Component 不存在；
- WaveData 没有生成条目；
- EnemySpawnEntry 未指定 PackedScene；
- 出生点 ID 无法解析；
- LevelData 没有波次；
- 塔或敌人场景不继承规定基础类型。

### 14.2 运行时错误

- 非法场景实例化应记录包含资源路径的错误并跳过该条目，不得产生空引用连锁错误。
- 重复死亡、重复到达目标和重复结算必须被状态守卫阻止。
- 资源缺失导致关卡无法继续时进入明确的失败状态或返回菜单，不静默卡住。
- UI 不负责吞掉业务错误，只显示 Controller 提供的用户可理解信息。

## 15. 标准内容制作流程

### 15.1 通用工作流

| 阶段 | 操作 | 产物 | 通过标准 |
|---|---|---|---|
| 1. 定义需求 | 明确定位、数值、特殊行为和成功条件 | 简短内容说明 | 不混入实现细节 |
| 2. 划分职责 | 区分 Resource、Scene、Component、Controller | 职责表 | 每项只有一个权威负责人 |
| 3. 检查复用 | 查找现有组件与基础场景 | 复用选择 | 不重复实现相同能力 |
| 4. 创建 Resource | 创建并填写 `.tres` | 内容数据 | 平衡数值可在检查器修改 |
| 5. 创建继承场景 | 从基础场景创建内容场景 | `.tscn` | 不复制公共脚本和节点 |
| 6. 组装组件 | 添加必要与特殊组件 | 场景组件树 | 每组件职责单一 |
| 7. 绑定依赖 | 在检查器关联资源和节点 | 完整配置 | 无脆弱父路径查找 |
| 8. 连接事件 | 使用 signal 建立数据流 | 事件关系 | UI 与业务解耦 |
| 9. 编辑器校验 | 查看配置警告与资源引用 | 无警告场景 | 缺失项在运行前可见 |
| 10. 单体测试 | 单独运行场景或组件测试 | 测试结果 | 输入输出符合契约 |
| 11. 集成测试 | 放入测试关卡运行完整循环 | 集成结果 | 生成、交互和结算正确 |
| 12. 内容注册 | 加入 WaveData、LevelCatalog 或 TowerCatalog | 正式内容入口 | 不在多个脚本重复登记 |
| 13. 回归测试 | 测试暂停、重开、返回和批量实例 | 验收记录 | 不破坏已有内容 |
| 14. 提交 | 按组件、迁移和内容拆分提交 | 可回滚提交 | 不混入无关目录重排 |

### 15.2 新敌人制作流程

1. 创建 MonsterData；
2. 从 `enemy_base.tscn` 创建继承场景；
3. 在检查器指定 MonsterData；
4. 配置视觉和碰撞体；
5. 仅为特殊能力添加新组件；
6. 加入 EnemySpawnEntry；
7. 通过敌人测试场景；
8. 在正式波次中进行批量验证。

### 15.3 新关卡制作流程

1. 创建 LevelData；
2. 创建 WaveData 与 EnemySpawnEntry；
3. 从 `level_base.tscn` 创建继承场景；
4. 指定 LevelData；
5. 配置背景、水晶、出生点和禁建区；
6. 设置允许的塔与初始资源；
7. 验证每一波、胜利和失败；
8. 注册到 LevelCatalog，由选关界面读取可用状态。

## 16. 测试策略

### 16.1 组件测试

- HealthComponent：受伤、治疗、边界、死亡只触发一次；
- MovementComponent：移动、减速、目标失效、到达事件只触发一次；
- WaveSpawnerComponent：空波次、顺序、数量、间隔、非法场景；
- BuildGridComponent：坐标往返、边界、禁建区、重复占用；
- EconomyComponent：余额不足、消费、奖励与信号；
- LevelGoalComponent：只胜利一次、只失败一次、二者互斥。

### 16.2 场景测试

- 敌人基础测试场景：出生、移动、受伤、死亡、到达目标；
- 关卡基础测试场景：生成、建塔、消费、水晶、波次和结算；
- 检查器测试：移除一个必需资源后出现明确配置警告；
- 批量测试：至少几十个敌人同时存在时，无明显错误或无效碰撞开销。

### 16.3 回归路径

标准回归路径为：

```text
首页 → 关卡选择 → 第 1 关 → 建塔 → 完成波次 → 胜利
首页 → 关卡选择 → 第 1 关 → 水晶被毁 → 失败 → 重开
关卡 → 返回选关 → 返回首页
```

## 17. 完成标准

架构迁移完成必须同时满足：

1. 敌人和关卡核心功能以 Node Component 出现在场景树中；
2. 所有平衡值来自强类型 Resource；
3. 运行时状态不保存在共享 Resource；
4. 普通敌人不需要专用控制脚本；
5. 新关卡不复制 LevelController 或 Spawner；
6. 关卡选择只显示或启用实际存在的关卡；
7. 项目不存在旧 `EnemyStats`、旧敌人基类或旧 `1_enemy` 分组引用；
8. 敌人死亡和到达目标不会重复结算；
9. 关卡具有可验证的胜利与失败条件；
10. 场景和 Resource 无缺失路径、无配置警告；
11. 标准回归路径全部通过；
12. 新敌人和新关卡可以只通过资源、继承场景与检查器完成常规制作。

## 18. 已确认的架构决定

1. 使用 Resource 驱动静态内容。
2. 使用 Node Component 承载需要检查器和运行时状态的能力。
3. 使用薄 Controller 装配组件并维持稳定外部接口。
4. 使用场景继承制作敌人和关卡变体。
5. 使用信号连接组件、Controller 与 HUD。
6. 使用 LevelData、WaveData 和 EnemySpawnEntry 取代关卡脚本中的硬编码数组。
7. 使用坐标式 BuildGrid 取代每格 Area2D。
8. 使用有限波次和“全部生成且场上敌人清空”作为胜利基础。
9. 迁移期间保留必要兼容接口，完成后删除旧接口与旧体系。
