# Resource-Driven Component Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有敌人和关卡迁移为可在 Godot 检查器中配置的 Resource 驱动、Node Component 组合架构，并保留一个可玩的第 1 关完整闭环。

**Architecture:** Resource 是静态配置的唯一来源，继承场景负责节点装配，Node Component 保存运行时状态并通过 signal 协作，根 Controller 只负责配置顺序和稳定外部接口。迁移按“可加载基线 → 资源模型 → 共享组件 → 敌人 → 关卡组件 → 塔接入 → 选关与清理”顺序执行，每个任务都产生独立可测试提交。

**Tech Stack:** Godot 4.6、GDScript 2.0、`.tscn` 场景、`.tres` Resource、Godot headless 自包含测试脚本、Git。

**Spec:** `docs/superpowers/specs/2026-08-29-resource-component-architecture-design.md`

## Global Constraints

- 使用 Godot 4.6；实施前确保可执行文件可通过 `godot` 命令调用。
- Resource 运行时按只读配置使用；当前生命、当前目标、波次索引、能量和格子占用不得写入 Resource。
- 需要检查器、signal、Timer 或帧处理的组件必须继承 Node，并作为场景子节点存在。
- 平衡字段只在一个强类型 Resource 中定义，Scene 与 Component 不复制同义字段。
- Component 不直接调用 HUD、SceneManager 或不相关兄弟组件；向外使用 signal。
- Controller 只负责依赖校验、配置顺序、信号连线和稳定兼容接口。
- 普通敌人使用 `enemy_base.tscn` 继承场景；普通关卡使用 `level_base.tscn` 继承场景。
- 新关卡不得复制 LevelController 或 WaveSpawner 脚本。
- 项目统一使用 `enemy` 分组；迁移完成后删除 `1_enemy`。
- 建造格使用坐标计算和占用 Dictionary，不为每个格子创建 Area2D。
- 每个任务只暂存其 Files 列表中的文件；不得暂存 `.reasonix`、删除的 README/CONTRIBUTING、设计表格或导出预设。
- 每个代码任务遵循失败测试 → 最小实现 → 通过测试 → 独立提交。

## Migration Phases

| 阶段 | 任务 | 可交付状态 |
|---|---|---|
| A. 基线 | Task 1 | 当前目录迁移形成可加载、可测试基线 |
| B. 数据与共享组件 | Tasks 2-3 | Resource 模型与通用 HealthComponent 可用 |
| C. 敌人 | Tasks 4-5 | 两种敌人完全由 Node Component 驱动 |
| D. 关卡基础能力 | Tasks 6-8 | 格子、经济、水晶、波次和胜负组件可独立测试 |
| E. 塔与可玩关卡 | Tasks 9-10 | 塔可从检查器建造，第 1 关具有胜负闭环 |
| F. 导航与收尾 | Tasks 11-12 | 选关由 Catalog 驱动，旧体系和旧路径清零 |

## Target File Map

### Shared components

- `base/components/health_component.gd`: 可复用生命、护甲、治疗和一次性死亡状态。
- `base/components/status_effect_component.gd`: 负面状态抗性与减速生命周期。

### Enemy domain

- `base/enemy_base/monster_data.gd`: 敌人静态配置 Resource。
- `base/enemy_base/monster_base.gd`: 敌人薄 Controller 与兼容接口。
- `base/enemy_base/enemy_base.tscn`: 标准敌人组件树。
- `base/enemy_base/components/target_component.gd`: 目标持有与失效通知。
- `base/enemy_base/components/movement_component.gd`: CharacterBody2D 移动与到达判定。
- `base/enemy_base/components/contact_damage_component.gd`: 到达目标后只结算一次接触伤害。
- `base/enemy_base/components/reward_component.gd`: 死亡奖励请求。
- `base/enemy_base/components/health_view_component.gd`: 血条与血量文本显示。
- `data/enemies/*.tres`: 每种敌人的 MonsterData。
- `scenes/enemies/*.tscn`: 继承 EnemyBase 的内容场景。

### Resource models and catalogs

- `base/level_base/resources/grid_config.gd`: 网格尺寸、间距和禁建格。
- `base/level_base/resources/enemy_spawn_entry.gd`: 单种敌人生成条目。
- `base/level_base/resources/wave_data.gd`: 一波的生成配置。
- `base/level_base/resources/level_data.gd`: 关卡静态配置。
- `base/catalogs/level_catalog_entry.gd`: 关卡目录条目。
- `base/catalogs/level_catalog.gd`: 可用关卡目录。
- `base/catalogs/tower_catalog_entry.gd`: 塔目录条目。
- `base/catalogs/tower_catalog.gd`: 可用塔目录。
- `data/catalogs/*.tres`: 实际目录资源。

### Level domain

- `base/level_base/components/build_grid_component.gd`: 坐标换算、禁建与占用。
- `base/level_base/components/economy_component.gd`: 能量收入和消费。
- `base/level_base/components/tower_placement_component.gd`: 选塔与建造事务。
- `base/level_base/components/wave_spawner_component.gd`: 有限波次生成。
- `base/level_base/components/level_goal_component.gd`: 一次性胜负判定。
- `base/level_base/crystal_controller.gd`: 水晶与 HealthComponent 的边界。
- `base/level_base/level_controller.gd`: 关卡薄 Controller。
- `base/level_base/level_base.tscn`: 标准关卡组件树。
- `base/level_base/level_hud.gd`: HUD 信号绑定与用户操作输出。
- `scenes/ui/result_panel.tscn`、`scripts/ui/result_panel.gd`: 可复用胜负面板。
- `data/levels/level_01.tres`: 第 1 关 LevelData。
- `data/waves/level_01_wave_01.tres`: 第 1 关首个有限波次。
- `scenes/levels/level_01.tscn`: 第 1 关继承场景。

### Navigation and tests

- `base/Managers/SceneManager.gd`: 正确 UI 路径、PackedScene 关卡切换和历史。
- `ui/LevelSelection/level_selection.gd`: 从 LevelCatalog 创建按钮。
- `ui/LevelSelection/level_selection.tscn`: 动态关卡按钮容器。
- `tests/support/test_suite.gd`: 自包含 headless 断言工具。
- `tests/**/*.gd`: 单元、资源、场景和端到端测试。

---

### Task 1: Establish a Runnable Migration Baseline

**Files:**
- Create: `tests/support/test_suite.gd`
- Create: `tests/smoke/test_resource_paths.gd`
- Modify: `base/Managers/SceneManager.gd`
- Modify: `level/1_level/1_level.gd`
- Modify: `scenes/enemies/enemy_streptococcus.tscn`
- Modify: `scenes/enemies/enemy_flagellate.tscn`
- Stage as baseline: intended old-to-new paths under `Enemies/`, `Managers/`, `Map/`, `Lab/`, `LevelSelection/`, `Main/`, `Towers/`, `Textures/images/`, `base/`, `data/`, `level/`, `scenes/`, `scripts/`, `ui/`, and moved `Textures/*` directories

**Interfaces:**
- Consumes: current working-tree directory migration.
- Produces: `TestSuite` helper contract, valid main/UI/level/enemy resource paths, and a committed migration baseline.

- [ ] **Step 1: Verify execution prerequisites and staging safety**

Run:

```powershell
godot --version
git diff --cached --name-only
git status --short
```

Expected: Godot reports `4.6`; staged file list is empty. If staged files exist, stop and ask the user before changing the index.

- [ ] **Step 2: Create the minimal test helper**

Create `tests/support/test_suite.gd`:

```gdscript
extends RefCounted

var failures: Array[String] = []

func expect_true(value: bool, message: String) -> void:
    if not value:
        failures.append(message)

func expect_eq(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        failures.append("%s: expected=%s actual=%s" % [message, expected, actual])

func finish(tree: SceneTree) -> void:
    for failure in failures:
        push_error(failure)
    tree.quit(0 if failures.is_empty() else 1)
```

- [ ] **Step 3: Write a failing resource-load smoke test**

Create `tests/smoke/test_resource_paths.gd`:

```gdscript
extends SceneTree

const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var required := [
        "res://ui/Main/main.tscn",
        "res://ui/LevelSelection/level_selection.tscn",
        "res://ui/Lab/lab.tscn",
        "res://level/1_level/1_level.tscn",
        "res://base/enemy_base/enemy_base.tscn",
        "res://scenes/enemies/enemy_streptococcus.tscn",
        "res://scenes/enemies/enemy_flagellate.tscn",
        "res://scenes/towers/light_tower.tscn",
    ]
    for path in required:
        suite.expect_true(ResourceLoader.exists(path), "missing resource: %s" % path)
        if ResourceLoader.exists(path):
            suite.expect_true(ResourceLoader.load(path) != null, "failed to load: %s" % path)
    suite.finish(self)
```

- [ ] **Step 4: Run the smoke test and verify it fails on current stale paths**

Run:

```powershell
godot --headless --path . -s res://tests/smoke/test_resource_paths.gd
```

Expected: non-zero exit caused by the broken enemy base reference or the stale level preload.

- [ ] **Step 5: Repair only the baseline paths**

In `base/Managers/SceneManager.gd`, set:

```gdscript
const SCENES := {
    "main": "res://ui/Main/main.tscn",
    "level_selection": "res://ui/LevelSelection/level_selection.tscn",
    "lab": "res://ui/Lab/lab.tscn",
}

func _level_path(id: int) -> String:
    return "res://level/%d_level/%d_level.tscn" % [id, id]
```

In `level/1_level/1_level.gd`, replace the stale texture with:

```gdscript
"texture": preload("res://Textures/towers/tower_plasma_cell/tower_plasma_cell.png"),
```

In both enemy content scenes, replace the base scene path with:

```text
res://base/enemy_base/enemy_base.tscn
```

- [ ] **Step 6: Run the smoke test and verify it passes**

Run:

```powershell
godot --headless --path . -s res://tests/smoke/test_resource_paths.gd
```

Expected: exit code 0 and no parse/load errors.

- [ ] **Step 7: Stage only the intended migration baseline**

Run:

```powershell
git add -A -- Enemies Managers Map Lab LevelSelection Main Towers Textures/images base data level scenes scripts ui Textures/backbutton Textures/enemies Textures/map Textures/towers project.godot tests
git diff --cached --check
git diff --cached --name-status
```

Expected: the staged list contains intended old-path deletions/new-path additions and the smoke test. It must not contain `.reasonix`, `README.md`, `CONTRIBUTING.md`, `Design/`, `export_presets.cfg`, or `reasonix.toml`.

- [ ] **Step 8: Commit the runnable baseline**

```powershell
git commit -m "chore: establish migrated project layout baseline"
```

---

### Task 2: Add Typed Resource Models and Catalogs

**Files:**
- Modify: `base/enemy_base/monster_data.gd`
- Modify: `base/tower_base/tower_data.gd`
- Create: `base/level_base/resources/grid_config.gd`
- Create: `base/level_base/resources/enemy_spawn_entry.gd`
- Create: `base/level_base/resources/wave_data.gd`
- Create: `base/level_base/resources/level_data.gd`
- Create: `base/catalogs/level_catalog_entry.gd`
- Create: `base/catalogs/level_catalog.gd`
- Create: `base/catalogs/tower_catalog_entry.gd`
- Create: `base/catalogs/tower_catalog.gd`
- Create: `tests/resources/test_resource_models.gd`

**Interfaces:**
- Consumes: `TestSuite` from Task 1.
- Produces: `MonsterData`, `GridConfig`, `EnemySpawnEntry`, `WaveData`, `LevelData`, `LevelCatalog`, and `TowerCatalog` contracts used by all later tasks.

- [ ] **Step 1: Write the failing resource-model test**

Create `tests/resources/test_resource_models.gd`:

```gdscript
extends SceneTree

const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var monster := MonsterData.new()
    suite.expect_eq(monster.monster_id, &"basic_monster", "monster id default")
    suite.expect_eq(monster.contact_damage, 10, "contact damage default")

    var grid := GridConfig.new()
    suite.expect_eq(grid.columns, 19, "grid columns")
    suite.expect_eq(grid.rows, 11, "grid rows")

    var spawn := EnemySpawnEntry.new()
    spawn.count = 3
    var wave := WaveData.new()
    wave.entries = [spawn]
    var level := LevelData.new()
    level.waves = [wave]
    suite.expect_eq(level.waves[0].entries[0].count, 3, "nested wave data")

    var level_entry := LevelCatalogEntry.new()
    level_entry.level_id = &"level_01"
    var catalog := LevelCatalog.new()
    catalog.entries = [level_entry]
    suite.expect_true(catalog.find_by_id(&"level_01") == level_entry, "catalog lookup")
    suite.finish(self)
```

- [ ] **Step 2: Run the test and verify missing classes fail**

Run:

```powershell
godot --headless --path . -s res://tests/resources/test_resource_models.gd
```

Expected: parse failure for `GridConfig`, `EnemySpawnEntry`, or another undefined resource class.

- [ ] **Step 3: Define MonsterData and TowerData static fields**

Replace the MonsterData exports with the following contract:

```gdscript
class_name MonsterData
extends Resource

enum MonsterType { NORMAL, ELITE, BOSS }

@export_group("Identity")
@export var monster_id: StringName = &"basic_monster"
@export var display_name: String = "Basic Monster"
@export var monster_type: MonsterType = MonsterType.NORMAL

@export_group("Health")
@export_range(1, 100000, 1) var max_health: int = 100
@export_range(0.0, 0.95, 0.01) var armor: float = 0.0

@export_group("Movement")
@export_range(0.0, 2000.0, 1.0, "suffix:px/s") var move_speed: float = 80.0

@export_group("Contact")
@export_range(0, 100000, 1) var contact_damage: int = 10
@export_range(1.0, 256.0, 1.0, "suffix:px") var reach_distance: float = 20.0

@export_group("Status")
@export_range(0.0, 1.0, 0.01) var negative_status_resistance: float = 0.0

@export_group("Reward")
@export_range(0, 100000, 1) var score_value: int = 10
@export_range(0, 100000, 1) var energy_reward: int = 0
```

Add identity/build exports to `TowerData`:

```gdscript
@export_group("Identity")
@export var tower_id: StringName = &"tower"
@export var display_name: String = "Tower"
@export var icon: Texture2D
@export_range(0, 100000, 1) var build_cost: int = 10
```

- [ ] **Step 4: Implement level resource classes**

Use these exact public fields:

```gdscript
# grid_config.gd
class_name GridConfig
extends Resource
@export_range(1, 128, 1) var columns: int = 19
@export_range(1, 128, 1) var rows: int = 11
@export_range(1.0, 256.0, 1.0, "suffix:px") var spacing: float = 64.0
@export var origin: Vector2 = Vector2(640, 360)
@export var blocked_cells: Array[Vector2i] = [Vector2i(9, 5)]

# enemy_spawn_entry.gd
class_name EnemySpawnEntry
extends Resource
@export var enemy_scene: PackedScene
@export_range(1, 10000, 1) var count: int = 1
@export_range(0.0, 60.0, 0.05, "suffix:s") var interval: float = 1.0
@export var spawn_point_id: StringName = &"north"

# wave_data.gd
class_name WaveData
extends Resource
@export_range(0.0, 120.0, 0.1, "suffix:s") var start_delay: float = 0.0
@export_range(0.0, 120.0, 0.1, "suffix:s") var end_delay: float = 1.0
@export var wait_for_clear: bool = true
@export var entries: Array[EnemySpawnEntry] = []

# level_data.gd
class_name LevelData
extends Resource
@export_group("Identity")
@export var level_id: StringName = &"level_01"
@export var display_name: String = "Level 1"
@export_group("Crystal")
@export_range(1, 100000, 1) var crystal_max_health: int = 100
@export_group("Economy")
@export_range(0, 100000, 1) var starting_energy: int = 100
@export_group("Build")
@export var grid_config: GridConfig
@export var allowed_tower_ids: Array[StringName] = []
@export_group("Waves")
@export var waves: Array[WaveData] = []
```

- [ ] **Step 5: Implement catalog resources**

Use these contracts:

```gdscript
# level_catalog_entry.gd
class_name LevelCatalogEntry
extends Resource
@export var level_id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var default_unlocked: bool = true
@export var preview: Texture2D

# level_catalog.gd
class_name LevelCatalog
extends Resource
@export var entries: Array[LevelCatalogEntry] = []
func find_by_id(id: StringName) -> LevelCatalogEntry:
    for entry in entries:
        if entry != null and entry.level_id == id:
            return entry
    return null

# tower_catalog_entry.gd
class_name TowerCatalogEntry
extends Resource
@export var tower_id: StringName
@export var data: TowerData
@export var scene: PackedScene

# tower_catalog.gd
class_name TowerCatalog
extends Resource
@export var entries: Array[TowerCatalogEntry] = []
func find_by_id(id: StringName) -> TowerCatalogEntry:
    for entry in entries:
        if entry != null and entry.tower_id == id:
            return entry
    return null
```

- [ ] **Step 6: Run the resource-model test**

Run:

```powershell
godot --headless --path . -s res://tests/resources/test_resource_models.gd
```

Expected: exit code 0.

- [ ] **Step 7: Commit the resource contracts**

```powershell
git add base/enemy_base/monster_data.gd base/tower_base/tower_data.gd base/level_base/resources base/catalogs tests/resources/test_resource_models.gd
git commit -m "feat: add typed content resource models"
```

---

### Task 3: Convert HealthComponent into a Shared Node Component

**Files:**
- Move: `base/enemy_base/health_component.gd` → `base/components/health_component.gd`
- Move: `base/enemy_base/health_component.gd.uid` → `base/components/health_component.gd.uid`
- Create: `tests/components/test_health_component.gd`

**Interfaces:**
- Consumes: normalized armor from MonsterData.
- Produces: `configure(max_health: int, armor: float = 0.0)`, `take_damage(amount: int) -> int`, `heal(amount: int) -> int`, getters, `health_changed`, and one-shot `died`.

- [ ] **Step 1: Write the failing Node-component test**

Create `tests/components/test_health_component.gd`:

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var health := HealthComponent.new()
    root.add_child(health)
    var death_count := 0
    health.died.connect(func(): death_count += 1)
    health.configure(100, 0.25)
    suite.expect_eq(health.take_damage(40), 30, "armor-adjusted damage")
    suite.expect_eq(health.get_health(), 70, "health after damage")
    suite.expect_eq(health.heal(100), 30, "healing is capped")
    health.take_damage(1000)
    health.take_damage(1000)
    suite.expect_eq(death_count, 1, "death emits once")
    suite.expect_true(health.is_dead(), "dead state")
    suite.finish(self)
```

- [ ] **Step 2: Run the test and verify the old RefCounted API fails**

```powershell
godot --headless --path . -s res://tests/components/test_health_component.gd
```

Expected: failure because the old component is not a Node and has no `configure()` return-value contract.

- [ ] **Step 3: Move and implement the shared component**

Move the script and UID using filesystem-safe project-relative paths, then implement:

```gdscript
class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal died

var _current_health: int = 0
var _max_health: int = 1
var _armor: float = 0.0
var _death_emitted: bool = false

func configure(max_health: int, armor: float = 0.0) -> void:
    _max_health = maxi(1, max_health)
    _current_health = _max_health
    _armor = clampf(armor, 0.0, 0.95)
    _death_emitted = false
    health_changed.emit(_current_health, _max_health)

func take_damage(amount: int) -> int:
    if amount <= 0 or is_dead():
        return 0
    var applied := maxi(1, roundi(amount * (1.0 - _armor)))
    applied = mini(applied, _current_health)
    _current_health -= applied
    health_changed.emit(_current_health, _max_health)
    if _current_health == 0 and not _death_emitted:
        _death_emitted = true
        died.emit()
    return applied

func heal(amount: int) -> int:
    if amount <= 0 or is_dead():
        return 0
    var before := _current_health
    _current_health = mini(_current_health + amount, _max_health)
    health_changed.emit(_current_health, _max_health)
    return _current_health - before

func get_health() -> int:
    return _current_health

func get_max_health() -> int:
    return _max_health

func is_dead() -> bool:
    return _current_health <= 0
```

- [ ] **Step 4: Run the component test**

```powershell
godot --headless --path . -s res://tests/components/test_health_component.gd
```

Expected: exit code 0.

- [ ] **Step 5: Commit the shared HealthComponent**

```powershell
git add -A -- base/enemy_base/health_component.gd base/enemy_base/health_component.gd.uid base/components tests/components/test_health_component.gd
git commit -m "refactor: make health a shared node component"
```

---

### Task 4: Add Enemy Target, Movement, and Contact Components

**Files:**
- Move: `base/enemy_base/movement_component.gd` → `base/enemy_base/components/movement_component.gd`
- Move: `base/enemy_base/movement_component.gd.uid` → `base/enemy_base/components/movement_component.gd.uid`
- Create: `base/enemy_base/components/target_component.gd`
- Create: `base/enemy_base/components/contact_damage_component.gd`
- Create: `tests/components/test_enemy_motion_components.gd`

**Interfaces:**
- Consumes: CharacterBody2D owner and MonsterData speed/contact fields.
- Produces: target storage, `MovementComponent.configure/start/stop/set_speed_multiplier`, `destination_reached`, and one-shot contact application.

- [ ] **Step 1: Write the failing motion-component test**

Create `tests/components/test_enemy_motion_components.gd` with a local damage target:

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

class DamageTarget extends Node2D:
    var received: int = 0
    func take_contact_damage(amount: int) -> void:
        received += amount

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var body := CharacterBody2D.new()
    var target := DamageTarget.new()
    var target_component := TargetComponent.new()
    var movement := MovementComponent.new()
    var contact := ContactDamageComponent.new()
    root.add_child(body)
    root.add_child(target)
    body.add_child(target_component)
    body.add_child(movement)
    body.add_child(contact)
    target.position = Vector2(10, 0)
    target_component.set_target(target)
    movement.configure(body, target_component, 100.0, 2.0)
    movement.start()
    contact.configure(target_component, 12)
    movement.tick(0.05)
    suite.expect_true(body.position.x > 0.0, "body moves toward target")
    contact.apply_once()
    contact.apply_once()
    suite.expect_eq(target.received, 12, "contact damage applies once")
    suite.finish(self)
```

- [ ] **Step 2: Run the test and verify missing classes fail**

```powershell
godot --headless --path . -s res://tests/components/test_enemy_motion_components.gd
```

Expected: parse failure for TargetComponent or ContactDamageComponent.

- [ ] **Step 3: Implement TargetComponent**

```gdscript
class_name TargetComponent
extends Node

signal target_changed(target: Node2D)
signal target_lost

var _target: Node2D

func set_target(target: Node2D) -> void:
    _target = target
    target_changed.emit(_target)

func get_target() -> Node2D:
    if _target != null and is_instance_valid(_target):
        return _target
    if _target != null:
        _target = null
        target_lost.emit()
    return null
```

- [ ] **Step 4: Convert MovementComponent to a Node with deterministic tick**

```gdscript
class_name MovementComponent
extends Node

signal destination_reached

var _body: CharacterBody2D
var _target_component: TargetComponent
var _speed: float
var _reach_distance: float
var _speed_multiplier: float = 1.0
var _running: bool = false
var _reached: bool = false

func configure(body: CharacterBody2D, target: TargetComponent, speed: float, reach_distance: float) -> void:
    _body = body
    _target_component = target
    _speed = maxf(0.0, speed)
    _reach_distance = maxf(1.0, reach_distance)
    _reached = false

func start() -> void:
    _running = true

func stop() -> void:
    _running = false
    if _body != null:
        _body.velocity = Vector2.ZERO

func set_speed_multiplier(value: float) -> void:
    _speed_multiplier = clampf(value, 0.0, 1.0)

func tick(delta: float) -> void:
    if not _running:
        return
    var target := _target_component.get_target() if _target_component != null else null
    if _body == null or target == null or _reached:
        return
    var distance := _body.global_position.distance_to(target.global_position)
    if distance <= _reach_distance:
        _reached = true
        stop()
        destination_reached.emit()
        return
    _body.velocity = _body.global_position.direction_to(target.global_position) * _speed * _speed_multiplier
    _body.move_and_slide()

func _physics_process(delta: float) -> void:
    if _running:
        tick(delta)
```

During implementation, keep `tick(delta)` callable by tests; do not special-case test mode elsewhere.

- [ ] **Step 5: Implement one-shot ContactDamageComponent**

```gdscript
class_name ContactDamageComponent
extends Node

signal contact_damage_applied(target: Node2D, amount: int)

var _target_component: TargetComponent
var _damage: int = 0
var _applied: bool = false

func configure(target: TargetComponent, damage: int) -> void:
    _target_component = target
    _damage = maxi(0, damage)
    _applied = false

func apply_once() -> bool:
    if _applied or _target_component == null:
        return false
    var target := _target_component.get_target()
    if target == null or not target.has_method("take_contact_damage"):
        return false
    _applied = true
    target.take_contact_damage(_damage)
    contact_damage_applied.emit(target, _damage)
    return true
```

- [ ] **Step 6: Run the motion-component test**

```powershell
godot --headless --path . -s res://tests/components/test_enemy_motion_components.gd
```

Expected: exit code 0.

- [ ] **Step 7: Commit the enemy motion components**

```powershell
git add -A -- base/enemy_base/movement_component.gd base/enemy_base/movement_component.gd.uid base/enemy_base/components tests/components/test_enemy_motion_components.gd
git commit -m "feat: add enemy target movement and contact components"
```

---

### Task 5: Assemble the Component-Driven Enemy Base

**Files:**
- Create: `base/components/status_effect_component.gd`
- Create: `base/enemy_base/components/reward_component.gd`
- Create: `base/enemy_base/components/health_view_component.gd`
- Modify: `base/enemy_base/monster_base.gd`
- Modify: `base/enemy_base/enemy_base.tscn`
- Modify: `data/enemies/enemy_streptococcus.tres`
- Modify: `data/enemies/enemy_flagellate.tres`
- Modify: `scenes/enemies/enemy_streptococcus.tscn`
- Modify: `scenes/enemies/enemy_flagellate.tscn`
- Create: `tests/enemies/test_enemy_base.gd`

**Interfaces:**
- Consumes: Tasks 2-4 resource and component contracts.
- Produces: stable `MonsterBase.setup_target/take_damage/heal`, `died`, `reached_target`, `reward_requested`, and inspector-visible EnemyBase component tree.

- [ ] **Step 1: Write the failing enemy integration test**

Create `tests/enemies/test_enemy_base.gd`:

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const EnemyScene = preload("res://scenes/enemies/enemy_streptococcus.tscn")

class DamageTarget extends Node2D:
    var received := 0
    func take_contact_damage(amount: int) -> void:
        received += amount

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var enemy := EnemyScene.instantiate() as MonsterBase
    var target := DamageTarget.new()
    root.add_child(target)
    root.add_child(enemy)
    suite.expect_true(enemy != null, "enemy scene root is MonsterBase")
    suite.expect_true(enemy.get_node_or_null("HealthComponent") is HealthComponent, "health node exists")
    suite.expect_true(enemy.get_node_or_null("MovementComponent") is MovementComponent, "movement node exists")
    enemy.setup_target(target)
    enemy.take_damage(25)
    suite.expect_eq(enemy.health_component.get_health(), 75, "damage delegates to health")
    suite.expect_true(enemy.is_in_group("enemy"), "canonical group")
    suite.expect_true(not enemy.is_in_group("1_enemy"), "legacy group removed")
    suite.finish(self)
```

- [ ] **Step 2: Run the test and verify the old runtime-created component design fails**

```powershell
godot --headless --path . -s res://tests/enemies/test_enemy_base.gd
```

Expected: non-zero exit because the base scene lacks Node components or data uses old field names.

- [ ] **Step 3: Implement the optional view, reward, and status components**

Use these public contracts:

```gdscript
# reward_component.gd
class_name RewardComponent
extends Node
signal reward_requested(score: int, energy: int)
var _score := 0
var _energy := 0
var _emitted := false
func configure(score: int, energy: int) -> void:
    _score = maxi(0, score)
    _energy = maxi(0, energy)
    _emitted = false
func request_once() -> void:
    if not _emitted:
        _emitted = true
        reward_requested.emit(_score, _energy)

# health_view_component.gd
class_name HealthViewComponent
extends Node
@export var health_bar: ProgressBar
@export var health_label: Label
func bind(health: HealthComponent) -> void:
    health.health_changed.connect(_on_health_changed)
    _on_health_changed(health.get_health(), health.get_max_health())
func _on_health_changed(current: int, maximum: int) -> void:
    if health_bar != null:
        health_bar.max_value = maximum
        health_bar.value = current
    if health_label != null:
        health_label.text = "%d/%d" % [current, maximum]

# status_effect_component.gd
class_name StatusEffectComponent
extends Node
signal speed_multiplier_changed(multiplier: float)
var _resistance := 0.0
var _slow_percent := 0.0
var _remaining := 0.0
func configure(resistance: float) -> void:
    _resistance = clampf(resistance, 0.0, 1.0)
func apply_slow(percent: float, duration: float) -> void:
    _slow_percent = clampf(percent * (1.0 - _resistance), 0.0, 0.8)
    _remaining = maxf(duration * (1.0 - _resistance), 0.0)
    speed_multiplier_changed.emit(1.0 - _slow_percent)
func _process(delta: float) -> void:
    if _remaining <= 0.0:
        return
    _remaining = maxf(0.0, _remaining - delta)
    if _remaining == 0.0:
        _slow_percent = 0.0
        speed_multiplier_changed.emit(1.0)
```

- [ ] **Step 4: Rewrite MonsterBase as the thin Controller**

The script must export `monster_data`, bind required child components by unique names, configure them once, and retain compatibility methods:

```gdscript
class_name MonsterBase
extends CharacterBody2D

signal died(enemy: MonsterBase)
signal reached_target(enemy: MonsterBase)
signal reward_requested(score: int, energy: int)

@export var monster_data: MonsterData
@onready var health_component: HealthComponent = %HealthComponent
@onready var target_component: TargetComponent = %TargetComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var contact_damage_component: ContactDamageComponent = %ContactDamageComponent
@onready var status_effect_component: StatusEffectComponent = %StatusEffectComponent
@onready var reward_component: RewardComponent = %RewardComponent
@onready var health_view_component: HealthViewComponent = %HealthViewComponent

var _finished := false
var damage: int:
    get: return monster_data.contact_damage if monster_data != null else 0

func _ready() -> void:
    add_to_group("enemy")
    if monster_data == null:
        push_error("MonsterBase requires MonsterData")
        set_physics_process(false)
        return
    health_component.configure(monster_data.max_health, monster_data.armor)
    movement_component.configure(self, target_component, monster_data.move_speed, monster_data.reach_distance)
    contact_damage_component.configure(target_component, monster_data.contact_damage)
    status_effect_component.configure(monster_data.negative_status_resistance)
    reward_component.configure(monster_data.score_value, monster_data.energy_reward)
    health_view_component.bind(health_component)
    health_component.died.connect(_on_died)
    movement_component.destination_reached.connect(_on_destination_reached)
    status_effect_component.speed_multiplier_changed.connect(movement_component.set_speed_multiplier)
    reward_component.reward_requested.connect(reward_requested.emit)

func setup_target(target: Node2D) -> void:
    target_component.set_target(target)
    movement_component.start()

func take_damage(amount: int) -> void:
    health_component.take_damage(amount)

func heal(amount: int) -> void:
    health_component.heal(amount)

func _on_died() -> void:
    if _finished:
        return
    _finished = true
    movement_component.stop()
    reward_component.request_once()
    died.emit(self)
    queue_free()

func _on_destination_reached() -> void:
    if _finished or not contact_damage_component.apply_once():
        return
    _finished = true
    reached_target.emit(self)
    queue_free()
```

Also implement `_get_configuration_warnings()` to report a missing MonsterData and missing required components by name.

- [ ] **Step 5: Rebuild EnemyBase as an inspector-visible component scene**

Edit `enemy_base.tscn` so the root contains unique-name nodes exactly named:

```text
HealthComponent
TargetComponent
MovementComponent
ContactDamageComponent
StatusEffectComponent
RewardComponent
HealthViewComponent
```

Keep Visual, CollisionShape2D, HealthBar, and HealthNumber. Bind HealthViewComponent exports to the two UI nodes in the inspector/scene resource.

- [ ] **Step 6: Migrate the two enemy resources and inherited scenes**

Set resource fields:

```text
enemy_streptococcus.tres:
  monster_id = &"streptococcus"
  display_name = "链球菌"
  max_health = 100
  move_speed = 80.0
  contact_damage = 10

enemy_flagellate.tres:
  monster_id = &"flagellate"
  display_name = "鞭毛虫"
  max_health = 150
  move_speed = 100.0
  contact_damage = 10
```

Both content scenes must inherit `res://base/enemy_base/enemy_base.tscn` and assign only MonsterData, visual texture/animation, scale, and collision override.

- [ ] **Step 7: Run enemy unit and smoke tests**

```powershell
godot --headless --path . -s res://tests/enemies/test_enemy_base.gd
godot --headless --path . -s res://tests/smoke/test_resource_paths.gd
```

Expected: both exit 0.

- [ ] **Step 8: Commit the component-driven enemy**

```powershell
git add base/components/status_effect_component.gd base/enemy_base data/enemies scenes/enemies tests/enemies/test_enemy_base.gd
git commit -m "refactor: assemble enemies from node components"
```

---

### Task 6: Implement BuildGrid and Economy Components

**Files:**
- Create: `base/level_base/components/build_grid_component.gd`
- Create: `base/level_base/components/economy_component.gd`
- Create: `tests/levels/test_build_grid_and_economy.gd`

**Interfaces:**
- Consumes: `GridConfig`.
- Produces: coordinate conversion, occupancy transaction methods, `configure(starting_energy)`, `try_spend`, `add_energy`, and change signals.

- [ ] **Step 1: Write the failing component test**

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var config := GridConfig.new()
    var grid := BuildGridComponent.new()
    var economy := EconomyComponent.new()
    root.add_child(grid)
    root.add_child(economy)
    grid.configure(config)
    suite.expect_eq(grid.world_to_cell(config.origin), Vector2i(9, 5), "center cell")
    suite.expect_true(not grid.can_build(Vector2i(9, 5)), "blocked crystal cell")
    suite.expect_true(grid.occupy(Vector2i(0, 0), Node2D.new()), "first occupancy")
    suite.expect_true(not grid.occupy(Vector2i(0, 0), Node2D.new()), "duplicate occupancy")
    economy.configure(20)
    suite.expect_true(economy.try_spend(15), "affordable spend")
    suite.expect_true(not economy.try_spend(10), "reject overspend")
    suite.expect_eq(economy.get_balance(), 5, "remaining balance")
    suite.finish(self)
```

- [ ] **Step 2: Run and verify missing classes fail**

```powershell
godot --headless --path . -s res://tests/levels/test_build_grid_and_economy.gd
```

Expected: parse failure.

- [ ] **Step 3: Implement BuildGridComponent**

Required API:

```gdscript
class_name BuildGridComponent
extends Node2D
signal occupancy_changed(cell: Vector2i, occupied: bool)

var _config: GridConfig
var _occupied: Dictionary[Vector2i, Node2D] = {}

func configure(config: GridConfig) -> void:
    _config = config
    _occupied.clear()

func world_to_cell(world_position: Vector2) -> Vector2i:
    var top_left := _config.origin - Vector2(_config.columns - 1, _config.rows - 1) * _config.spacing * 0.5
    var local := world_position - top_left
    return Vector2i(roundi(local.x / _config.spacing), roundi(local.y / _config.spacing))

func cell_to_world(cell: Vector2i) -> Vector2:
    var top_left := _config.origin - Vector2(_config.columns - 1, _config.rows - 1) * _config.spacing * 0.5
    return top_left + Vector2(cell) * _config.spacing

func is_inside(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < _config.columns and cell.y < _config.rows

func can_build(cell: Vector2i) -> bool:
    return is_inside(cell) and cell not in _config.blocked_cells and not _occupied.has(cell)

func occupy(cell: Vector2i, tower: Node2D) -> bool:
    if not can_build(cell):
        return false
    _occupied[cell] = tower
    occupancy_changed.emit(cell, true)
    return true

func release(cell: Vector2i) -> bool:
    if not _occupied.erase(cell):
        return false
    occupancy_changed.emit(cell, false)
    return true

func is_occupied(cell: Vector2i) -> bool:
    return _occupied.has(cell)

func get_occupant(cell: Vector2i) -> Node2D:
    return _occupied.get(cell) as Node2D
```

- [ ] **Step 4: Implement EconomyComponent**

```gdscript
class_name EconomyComponent
extends Node
signal balance_changed(balance: int)

var _balance := 0

func configure(starting_energy: int) -> void:
    _balance = maxi(0, starting_energy)
    balance_changed.emit(_balance)

func get_balance() -> int:
    return _balance

func try_spend(amount: int) -> bool:
    if amount < 0 or amount > _balance:
        return false
    _balance -= amount
    balance_changed.emit(_balance)
    return true

func add_energy(amount: int) -> void:
    if amount <= 0:
        return
    _balance += amount
    balance_changed.emit(_balance)
```

- [ ] **Step 5: Run and commit**

```powershell
godot --headless --path . -s res://tests/levels/test_build_grid_and_economy.gd
git add base/level_base/components/build_grid_component.gd base/level_base/components/economy_component.gd tests/levels/test_build_grid_and_economy.gd
git commit -m "feat: add build grid and economy components"
```

Expected: test exits 0 before commit.

---

### Task 7: Implement the Component-Driven Crystal

**Files:**
- Create: `base/level_base/crystal_controller.gd`
- Create: `base/level_base/crystal_base.tscn`
- Create: `tests/levels/test_crystal_controller.gd`

**Interfaces:**
- Consumes: shared HealthComponent.
- Produces: `configure(max_health)`, `take_contact_damage(amount)`, `crystal_destroyed`, and HealthComponent access for HUD/goal wiring.

- [ ] **Step 1: Write the failing crystal test**

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const CrystalScene = preload("res://base/level_base/crystal_base.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var crystal := CrystalScene.instantiate() as CrystalController
    root.add_child(crystal)
    var destroyed := 0
    crystal.crystal_destroyed.connect(func(): destroyed += 1)
    crystal.configure(20)
    crystal.take_contact_damage(7)
    suite.expect_eq(crystal.health_component.get_health(), 13, "contact damage")
    crystal.take_contact_damage(20)
    crystal.take_contact_damage(20)
    suite.expect_eq(destroyed, 1, "destroyed once")
    suite.finish(self)
```

- [ ] **Step 2: Run and verify missing scene/class fails**

```powershell
godot --headless --path . -s res://tests/levels/test_crystal_controller.gd
```

Expected: preload or class failure.

- [ ] **Step 3: Implement CrystalController and scene**

```gdscript
class_name CrystalController
extends Area2D

signal crystal_destroyed

@onready var health_component: HealthComponent = %HealthComponent

func _ready() -> void:
    health_component.died.connect(crystal_destroyed.emit)

func configure(max_health: int) -> void:
    health_component.configure(max_health)

func take_contact_damage(amount: int) -> void:
    health_component.take_damage(amount)
```

Create `crystal_base.tscn` with root CrystalController, CollisionShape2D, Sprite2D placeholder, and unique-name HealthComponent child. Set collision layer 2 and mask 1.

- [ ] **Step 4: Run and commit**

```powershell
godot --headless --path . -s res://tests/levels/test_crystal_controller.gd
git add base/level_base/crystal_controller.gd base/level_base/crystal_base.tscn tests/levels/test_crystal_controller.gd
git commit -m "feat: add component-driven crystal"
```

Expected: test exits 0.

---

### Task 8: Implement Finite Waves and One-Shot Level Goals

**Files:**
- Create: `base/level_base/components/wave_spawner_component.gd`
- Create: `base/level_base/components/level_goal_component.gd`
- Create: `tests/levels/test_wave_and_goal_components.gd`

**Interfaces:**
- Consumes: `Array[WaveData]`, Enemies container, Crystal target, and spawn-point dictionary.
- Produces: deterministic `tick(delta)`, `enemy_spawned`, wave signals, `all_waves_spawned`, `register_enemy`, `level_won`, and `level_lost`.

- [ ] **Step 1: Write the failing wave/goal test**

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const EnemyScene = preload("res://scenes/enemies/enemy_streptococcus.tscn")
const CrystalScene = preload("res://base/level_base/crystal_base.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var enemies := Node2D.new()
    var marker := Marker2D.new()
    var crystal := CrystalScene.instantiate() as CrystalController
    var spawner := WaveSpawnerComponent.new()
    var goal := LevelGoalComponent.new()
    root.add_child(enemies)
    root.add_child(marker)
    root.add_child(crystal)
    root.add_child(spawner)
    root.add_child(goal)
    crystal.configure(20)

    var entry := EnemySpawnEntry.new()
    entry.enemy_scene = EnemyScene
    entry.count = 1
    entry.interval = 0.0
    entry.spawn_point_id = &"north"
    var wave := WaveData.new()
    wave.start_delay = 0.0
    wave.end_delay = 0.0
    wave.wait_for_clear = false
    wave.entries = [entry]

    var spawned: Array[MonsterBase] = []
    var all_spawned := false
    var win_count := 0
    spawner.enemy_spawned.connect(func(enemy: MonsterBase): spawned.append(enemy))
    spawner.all_waves_spawned.connect(func(): all_spawned = true)
    goal.level_won.connect(func(): win_count += 1)
    spawner.configure([wave], enemies, crystal, {&"north": marker})
    goal.bind(spawner, crystal)
    spawner.start()
    for _step in range(4):
        spawner.tick(1.0)
    suite.expect_eq(spawned.size(), 1, "configured enemy count")
    suite.expect_true(all_spawned, "all waves signal")
    suite.expect_eq(win_count, 0, "no win while enemy is active")
    spawned[0].queue_free()
    await process_frame
    suite.expect_eq(win_count, 1, "win after final enemy exits")

    var loss_goal := LevelGoalComponent.new()
    var loss_spawner := WaveSpawnerComponent.new()
    var loss_crystal := CrystalScene.instantiate() as CrystalController
    root.add_child(loss_goal)
    root.add_child(loss_spawner)
    root.add_child(loss_crystal)
    loss_crystal.configure(5)
    var loss_count := 0
    loss_goal.level_lost.connect(func(): loss_count += 1)
    loss_goal.bind(loss_spawner, loss_crystal)
    loss_crystal.take_contact_damage(5)
    loss_crystal.take_contact_damage(5)
    suite.expect_eq(loss_count, 1, "loss emits once")
    suite.finish(self)
```

- [ ] **Step 2: Run and verify missing classes fail**

```powershell
godot --headless --path . -s res://tests/levels/test_wave_and_goal_components.gd
```

Expected: parse failure.

- [ ] **Step 3: Implement WaveSpawnerComponent**

The component must expose:

```gdscript
signal enemy_spawned(enemy: MonsterBase)
signal wave_started(index: int)
signal wave_completed(index: int)
signal all_waves_spawned

func configure(
    waves: Array[WaveData],
    enemies_container: Node2D,
    target: Node2D,
    spawn_points: Dictionary[StringName, Marker2D]
) -> void
func start() -> void
func stop() -> void
func tick(delta: float) -> void
```

Implement a single state machine with states `IDLE`, `START_DELAY`, `SPAWNING`, `END_DELAY`, `COMPLETE` and these exact transitions:

| Current state | Condition | Action and next state |
|---|---|---|
| IDLE | `start()` | set wave index 0, load start delay, enter START_DELAY |
| START_DELAY | timer reaches 0 | emit `wave_started`, select first entry, enter SPAWNING |
| SPAWNING | entry timer reaches 0 | spawn one enemy, increment unit index, reload entry interval |
| SPAWNING | current entry count complete | select next entry or emit `wave_completed` and enter END_DELAY |
| END_DELAY | timer reaches 0 and clear requirement satisfied | advance wave and enter START_DELAY, or enter COMPLETE |
| COMPLETE | first entry only | emit `all_waves_spawned`, stop processing |

Track `_active_spawned` by incrementing on spawn and connecting each enemy's `tree_exiting` with `CONNECT_ONE_SHOT`. When `wave.wait_for_clear` is true, END_DELAY may advance only when `_active_spawned == 0`. `_process(delta)` calls `tick(delta)` only while running.

For each spawn:

```gdscript
var enemy := entry.enemy_scene.instantiate() as MonsterBase
if enemy == null:
    push_error("EnemySpawnEntry scene root must be MonsterBase")
    return
_enemies_container.add_child(enemy)
enemy.global_position = spawn_point.global_position
enemy.setup_target(_target)
enemy_spawned.emit(enemy)
```

- [ ] **Step 4: Implement LevelGoalComponent**

```gdscript
class_name LevelGoalComponent
extends Node

signal level_won
signal level_lost

enum Outcome { RUNNING, WON, LOST }
var outcome := Outcome.RUNNING
var _all_waves_spawned := false
var _active_enemies := 0

func bind(spawner: WaveSpawnerComponent, crystal: CrystalController) -> void:
    spawner.enemy_spawned.connect(register_enemy)
    spawner.all_waves_spawned.connect(_on_all_waves_spawned)
    crystal.crystal_destroyed.connect(_on_crystal_destroyed)

func register_enemy(enemy: MonsterBase) -> void:
    _active_enemies += 1
    enemy.tree_exiting.connect(_on_enemy_exiting, CONNECT_ONE_SHOT)

func _on_enemy_exiting() -> void:
    _active_enemies = maxi(0, _active_enemies - 1)
    _evaluate_win()

func _on_all_waves_spawned() -> void:
    _all_waves_spawned = true
    _evaluate_win()

func _evaluate_win() -> void:
    if outcome == Outcome.RUNNING and _all_waves_spawned and _active_enemies == 0:
        outcome = Outcome.WON
        level_won.emit()

func _on_crystal_destroyed() -> void:
    if outcome == Outcome.RUNNING:
        outcome = Outcome.LOST
        level_lost.emit()
```

- [ ] **Step 5: Run and commit**

```powershell
godot --headless --path . -s res://tests/levels/test_wave_and_goal_components.gd
git add base/level_base/components/wave_spawner_component.gd base/level_base/components/level_goal_component.gd tests/levels/test_wave_and_goal_components.gd
git commit -m "feat: add finite waves and level goal components"
```

Expected: test exits 0.

---

### Task 9: Migrate Plasma Cell to TowerBase and Add Tower Placement

**Files:**
- Modify: `scripts/towers/tower_plasma_cell.gd`
- Modify: `scenes/towers/tower_plasma_cell.tscn`
- Modify: `base/tower_base/tower_base.tscn`
- Create: `data/towers/tower_plasma_cell_stats.tres`
- Modify: `data/towers/light_tower_stats.tres`
- Create: `data/catalogs/tower_catalog.tres`
- Create: `base/level_base/components/tower_placement_component.gd`
- Create: `tests/levels/test_tower_placement.gd`

**Interfaces:**
- Consumes: TowerCatalog, BuildGridComponent, EconomyComponent, and Towers container.
- Produces: canonical TowerBase plasma scene, `select_tower(id)`, `place_at_world(position)`, `tower_placed`, and `placement_failed`.

- [ ] **Step 1: Write the failing placement test**

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const PlasmaScene = preload("res://scenes/towers/tower_plasma_cell.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var grid := BuildGridComponent.new()
    var economy := EconomyComponent.new()
    var towers := Node2D.new()
    var placement := TowerPlacementComponent.new()
    root.add_child(grid)
    root.add_child(economy)
    root.add_child(towers)
    root.add_child(placement)
    var config := GridConfig.new()
    config.blocked_cells = []
    grid.configure(config)
    economy.configure(100)

    var data := TowerData.new()
    data.tower_id = &"plasma_cell"
    data.build_cost = 20
    var entry := TowerCatalogEntry.new()
    entry.tower_id = &"plasma_cell"
    entry.data = data
    entry.scene = PlasmaScene
    var catalog := TowerCatalog.new()
    catalog.entries = [entry]
    placement.configure(catalog, [&"plasma_cell"], grid, economy, towers)
    suite.expect_true(placement.select_tower(&"plasma_cell"), "tower selection")
    var placed := placement.place_at_world(grid.cell_to_world(Vector2i(0, 0)))
    suite.expect_true(placed is TowerBase, "placed root uses TowerBase")
    suite.expect_eq(economy.get_balance(), 80, "build cost deducted")
    suite.expect_true(grid.is_occupied(Vector2i(0, 0)), "cell occupied")
    suite.expect_true(placement.place_at_world(grid.cell_to_world(Vector2i(0, 0))) == null, "duplicate placement rejected")
    suite.finish(self)
```

- [ ] **Step 2: Run and verify the old plasma scene fails the TowerBase cast**

```powershell
godot --headless --path . -s res://tests/levels/test_tower_placement.gd
```

Expected: non-zero exit because the current plasma root is a standalone Node2D.

- [ ] **Step 3: Migrate plasma cell to TowerBase**

Change `tower_plasma_cell.gd` to:

```gdscript
class_name PlasmaCellTower
extends TowerBase

const BULLET_SCENE := preload("res://scenes/towers/tower_plasma_cell_bullet.tscn")

@export var bullet_speed: float = 320.0
@onready var projectile_origin: Marker2D = %ProjectileOrigin

func _fire(target: Node2D, mult: float) -> void:
    if target == null or not target.has_method("take_damage"):
        return
    var bullet := BULLET_SCENE.instantiate()
    get_tree().current_scene.add_child(bullet)
    bullet.global_position = projectile_origin.global_position
    bullet.setup(target, roundi(config.base_damage * mult), bullet_speed)
```

Rebuild the plasma scene from `tower_base.tscn` structure with ClickArea, Visual/Sprite2D, AttackTimer, ProductionTimer, and ProjectileOrigin. Assign `tower_plasma_cell_stats.tres` as config. Set plasma `TowerData` identity and `build_cost = 20`; set LightTower identity and a non-null config in its scene.

- [ ] **Step 4: Implement TowerPlacementComponent**

Required API and transaction order:

```gdscript
class_name TowerPlacementComponent
extends Node
signal tower_placed(tower: TowerBase, cell: Vector2i)
signal placement_failed(reason: String)

func configure(
    catalog: TowerCatalog,
    allowed_ids: Array[StringName],
    grid: BuildGridComponent,
    economy: EconomyComponent,
    towers_container: Node2D
) -> void
func select_tower(tower_id: StringName) -> bool
func place_at_world(world_position: Vector2) -> TowerBase
```

Store the five configured dependencies plus `_selected_tower_id`. Implement selection and placement with the following control flow:

```gdscript
func select_tower(tower_id: StringName) -> bool:
    if tower_id not in _allowed_ids or _catalog.find_by_id(tower_id) == null:
        placement_failed.emit("tower_not_allowed")
        return false
    _selected_tower_id = tower_id
    return true

func place_at_world(world_position: Vector2) -> TowerBase:
    var entry := _catalog.find_by_id(_selected_tower_id)
    if entry == null or entry.scene == null or entry.data == null:
        placement_failed.emit("invalid_tower_entry")
        return null
    var cell := _grid.world_to_cell(world_position)
    if not _grid.can_build(cell):
        placement_failed.emit("cell_unavailable")
        return null
    var tower := entry.scene.instantiate() as TowerBase
    if tower == null:
        placement_failed.emit("scene_root_not_tower_base")
        return null
    if not _economy.try_spend(entry.data.build_cost):
        tower.free()
        placement_failed.emit("insufficient_energy")
        return null
    tower.config = entry.data
    _towers_container.add_child(tower)
    tower.global_position = _grid.cell_to_world(cell)
    if not _grid.occupy(cell, tower):
        _economy.add_energy(entry.data.build_cost)
        tower.queue_free()
        placement_failed.emit("occupancy_race")
        return null
    tower_placed.emit(tower, cell)
    return tower
```

- [ ] **Step 5: Create the TowerCatalog resource**

Create `data/catalogs/tower_catalog.tres` with entries for `plasma_cell` and `light_tower`, each linking TowerData and its PackedScene.

- [ ] **Step 6: Run tower and placement tests**

```powershell
godot --headless --path . -s res://tests/levels/test_tower_placement.gd
godot --headless --path . -s res://tests/smoke/test_resource_paths.gd
```

Expected: both exit 0.

- [ ] **Step 7: Commit**

```powershell
git add scripts/towers/tower_plasma_cell.gd scenes/towers/tower_plasma_cell.tscn base/tower_base/tower_base.tscn data/towers data/catalogs/tower_catalog.tres base/level_base/components/tower_placement_component.gd tests/levels/test_tower_placement.gd
git commit -m "refactor: migrate plasma tower and add placement component"
```

---

### Task 10: Build LevelBase, HUD, Result Panel, and Level 1 Data

**Files:**
- Create: `base/level_base/level_controller.gd`
- Create: `base/level_base/level_hud.gd`
- Create: `base/level_base/level_base.tscn`
- Create: `scripts/ui/result_panel.gd`
- Create: `scenes/ui/result_panel.tscn`
- Create: `data/waves/level_01_wave_01.tres`
- Create: `data/levels/level_01.tres`
- Create: `scenes/levels/level_01.tscn`
- Create: `tests/integration/test_level_01_scene.gd`

**Interfaces:**
- Consumes: all resource, enemy, level, crystal, and tower components from Tasks 2-9.
- Produces: inspector-configured LevelBase, playable level 01 scene, HUD bindings, and reusable result panel.

- [ ] **Step 1: Write the failing Level 1 scene test**

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var packed := load("res://scenes/levels/level_01.tscn") as PackedScene
    suite.expect_true(packed != null, "Level 1 scene loads")
    var level := packed.instantiate() as LevelController if packed != null else null
    suite.expect_true(level != null, "Level 1 root is LevelController")
    if level != null:
        suite.expect_true(level.level_data != null, "LevelData assigned")
        suite.expect_true(level.get_node_or_null("World/BuildGrid") is BuildGridComponent, "grid component")
        suite.expect_true(level.get_node_or_null("World/Crystal") is CrystalController, "crystal controller")
        suite.expect_true(level.get_node_or_null("Systems/WaveSpawner") is WaveSpawnerComponent, "wave spawner")
        suite.expect_true(level.get_node_or_null("Systems/TowerPlacement") is TowerPlacementComponent, "placement component")
        suite.expect_true(level.get_node_or_null("Systems/LevelGoal") is LevelGoalComponent, "goal component")
        suite.expect_true(level.get_node_or_null("HUD/ResultPanel") != null, "result panel")
        root.add_child(level)
        await process_frame
        suite.expect_eq(level.build_grid.world_to_cell(level.level_data.grid_config.origin), Vector2i(9, 5), "configured grid")
    suite.finish(self)
```

- [ ] **Step 2: Run and verify the scene is missing**

```powershell
godot --headless --path . -s res://tests/integration/test_level_01_scene.gd
```

Expected: preload/load failure.

- [ ] **Step 3: Implement LevelController**

Required exports and dependencies:

```gdscript
class_name LevelController
extends Node2D

@export var level_data: LevelData
@export var tower_catalog: TowerCatalog
@onready var build_grid: BuildGridComponent = %BuildGrid
@onready var crystal: CrystalController = %Crystal
@onready var economy: EconomyComponent = %Economy
@onready var spawner: WaveSpawnerComponent = %WaveSpawner
@onready var placement: TowerPlacementComponent = %TowerPlacement
@onready var goal: LevelGoalComponent = %LevelGoal
@onready var hud: LevelHUD = %HUD
@onready var result_panel: ResultPanel = %ResultPanel
@onready var enemies: Node2D = %Enemies
@onready var towers: Node2D = %Towers

func _ready() -> void:
    if level_data == null or tower_catalog == null:
        push_error("LevelController requires LevelData and TowerCatalog")
        return
    build_grid.configure(level_data.grid_config)
    crystal.configure(level_data.crystal_max_health)
    economy.configure(level_data.starting_energy)
    placement.configure(tower_catalog, level_data.allowed_tower_ids, build_grid, economy, towers)
    spawner.configure(level_data.waves, enemies, crystal, _collect_spawn_points())
    goal.bind(spawner, crystal)
    hud.bind(self, crystal.health_component, economy, placement, goal)
    spawner.enemy_spawned.connect(_bind_enemy_reward)
    goal.level_won.connect(_finish_level.bind(true))
    goal.level_lost.connect(_finish_level.bind(false))
    result_panel.restart_requested.connect(SceneManager.reload)
    result_panel.level_select_requested.connect(SceneManager.goto.bind("level_selection"))
    result_panel.home_requested.connect(SceneManager.goto.bind("main"))
    spawner.start()

func _bind_enemy_reward(enemy: MonsterBase) -> void:
    enemy.reward_requested.connect(func(_score: int, energy: int): economy.add_energy(energy))

func _finish_level(won: bool) -> void:
    spawner.stop()
    result_panel.show_result(won)
    get_tree().paused = true

func _collect_spawn_points() -> Dictionary[StringName, Marker2D]:
    var result: Dictionary[StringName, Marker2D] = {}
    for child in %SpawnPoints.get_children():
        var marker := child as Marker2D
        if marker != null:
            result[StringName(marker.name.to_snake_case())] = marker
    return result

func _get_configuration_warnings() -> PackedStringArray:
    var warnings := PackedStringArray()
    if level_data == null:
        warnings.append("LevelData is required")
    if tower_catalog == null:
        warnings.append("TowerCatalog is required")
    return warnings
```

- [ ] **Step 4: Implement LevelHUD and ResultPanel**

`LevelHUD` uses these inspector references and bindings; it never calls SceneManager directly:

```gdscript
class_name LevelHUD
extends CanvasLayer

@export var crystal_health_bar: ProgressBar
@export var crystal_health_label: Label
@export var energy_label: Label
@export var plasma_button: Button
@export var light_button: Button

var _placement: TowerPlacementComponent

func bind(
    _level: LevelController,
    health: HealthComponent,
    economy: EconomyComponent,
    placement: TowerPlacementComponent,
    _goal: LevelGoalComponent
) -> void:
    _placement = placement
    health.health_changed.connect(_on_health_changed)
    economy.balance_changed.connect(_on_balance_changed)
    plasma_button.pressed.connect(placement.select_tower.bind(&"plasma_cell"))
    light_button.pressed.connect(placement.select_tower.bind(&"light_tower"))
    _on_health_changed(health.get_health(), health.get_max_health())
    _on_balance_changed(economy.get_balance())

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _placement.place_at_world(event.position)

func _on_health_changed(current: int, maximum: int) -> void:
    crystal_health_bar.max_value = maximum
    crystal_health_bar.value = current
    crystal_health_label.text = "%d/%d" % [current, maximum]

func _on_balance_changed(balance: int) -> void:
    energy_label.text = str(balance)
```

`ResultPanel` provides:

```gdscript
class_name ResultPanel
extends Control
signal restart_requested
signal level_select_requested
signal home_requested
@export var title_label: Label
@export var restart_button: Button
@export var level_select_button: Button
@export var home_button: Button
func _ready() -> void:
    restart_button.pressed.connect(restart_requested.emit)
    level_select_button.pressed.connect(level_select_requested.emit)
    home_button.pressed.connect(home_requested.emit)
    hide_result()
func show_result(won: bool) -> void:
    title_label.text = "胜利" if won else "失败"
    visible = true
func hide_result() -> void:
    visible = false
```

Set `process_mode = Node.PROCESS_MODE_ALWAYS` in the scene. LevelController responds to goal signals by pausing the tree, showing the panel, and connecting requests to SceneManager/reload in one place.

- [ ] **Step 5: Build LevelBase scene tree**

Create exactly the structure from the spec:

```text
LevelBase
├─ World
│  ├─ Background
│  ├─ BuildGrid
│  ├─ Crystal
│  ├─ Towers
│  ├─ Enemies
│  └─ SpawnPoints
├─ Systems
│  ├─ Economy
│  ├─ WaveSpawner
│  ├─ TowerPlacement
│  └─ LevelGoal
└─ HUD
   └─ ResultPanel
```

Background remains visual-only at scale 0.85. World logic nodes remain scale 1. Configure unique names for all Controller dependencies. Set enemy/crystal/projectile/tower/build collision layers according to the spec.

- [ ] **Step 6: Create Level 1 resources and inherited scene**

`level_01_wave_01.tres` contains one entry: streptococcus scene, count 5, interval 1.0, spawn point `north`; start delay 1.0, end delay 0.5, wait for clear true.

`level_01.tres` contains: ID `level_01`, display name `第 1 关`, crystal health 100, starting energy 100, 19×11 grid with center blocked, allowed tower IDs `plasma_cell` and `light_tower`, and the wave resource.

`level_01.tscn` inherits LevelBase, assigns LevelData and TowerCatalog, assigns map/crystal visuals, and defines north/south/east/west Marker2D nodes. It contains no unique Controller or Spawner script.

- [ ] **Step 7: Run Level 1 scene and prior component tests**

```powershell
godot --headless --path . -s res://tests/integration/test_level_01_scene.gd
godot --headless --path . -s res://tests/levels/test_wave_and_goal_components.gd
godot --headless --path . -s res://tests/levels/test_tower_placement.gd
```

Expected: all exit 0.

- [ ] **Step 8: Commit the playable LevelBase**

```powershell
git add base/level_base/level_controller.gd base/level_base/level_hud.gd base/level_base/level_base.tscn scripts/ui/result_panel.gd scenes/ui/result_panel.tscn data/waves data/levels scenes/levels tests/integration/test_level_01_scene.gd
git commit -m "feat: build resource-driven level base and level one"
```

---

### Task 11: Drive Level Selection and Navigation from LevelCatalog

**Files:**
- Create: `data/catalogs/level_catalog.tres`
- Modify: `base/Managers/SceneManager.gd`
- Modify: `base/Managers/scene_manager.tscn`
- Modify: `ui/LevelSelection/level_selection.gd`
- Modify: `ui/LevelSelection/level_selection.tscn`
- Create: `tests/navigation/test_level_catalog_navigation.gd`

**Interfaces:**
- Consumes: LevelCatalogEntry.scene from Task 2 and Level 1 scene from Task 10.
- Produces: `SceneManager.goto_level(entry)`, catalog-generated buttons, and no fixed LEVEL_COUNT/path guessing.

- [ ] **Step 1: Write the failing catalog navigation test**

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var catalog := load("res://data/catalogs/level_catalog.tres") as LevelCatalog
    suite.expect_true(catalog != null, "LevelCatalog loads")
    suite.expect_eq(catalog.entries.size(), 1, "one available level")
    suite.expect_true(catalog.entries[0].scene != null, "catalog scene assigned")
    suite.expect_true(SceneManager.resolve_level_scene(&"level_01") == catalog.entries[0].scene, "SceneManager resolves catalog scene")

    var selection_scene := load("res://ui/LevelSelection/level_selection.tscn") as PackedScene
    var selection := selection_scene.instantiate()
    root.add_child(selection)
    await process_frame
    var buttons := selection.get_node("VBoxContainer/LevelButtons").get_children()
    suite.expect_eq(buttons.size(), 1, "one generated level button")
    suite.expect_eq(buttons[0].get_meta("level_id"), &"level_01", "button level id")
    suite.expect_true(not buttons[0].disabled, "default level unlocked")
    suite.finish(self)
```

- [ ] **Step 2: Run and verify missing catalog/navigation APIs fail**

```powershell
godot --headless --path . -s res://tests/navigation/test_level_catalog_navigation.gd
```

Expected: missing resource or method failure.

- [ ] **Step 3: Create the LevelCatalog resource**

Create a single LevelCatalogEntry subresource with ID `level_01`, display name `第 1 关`, scene `res://scenes/levels/level_01.tscn`, and `default_unlocked = true`.

- [ ] **Step 4: Refactor SceneManager**

Replace `LEVEL_COUNT`, `_level_path()`, and level-name parsing with:

```gdscript
@export var level_catalog: LevelCatalog

func resolve_level_scene(level_id: StringName) -> PackedScene:
    var entry := level_catalog.find_by_id(level_id) if level_catalog != null else null
    return entry.scene if entry != null else null

func goto_level(entry: LevelCatalogEntry) -> void:
    if entry == null or entry.scene == null:
        push_error("SceneManager: invalid LevelCatalogEntry")
        return
    _remember_current_scene()
    get_tree().paused = false
    var err := get_tree().change_scene_to_packed(entry.scene)
    if err != OK:
        push_error("SceneManager: level change failed with %d" % err)
```

Keep UI scene aliases with their corrected `res://ui/...` paths. Store history as actual scene paths, not inferred logical level names.

Assign `data/catalogs/level_catalog.tres` to the SceneManager root's exported `level_catalog` property in `base/Managers/scene_manager.tscn`.

- [ ] **Step 5: Refactor the level-selection UI**

The scene keeps one GridContainer named `LevelButtons`, a title, and back button. The script exports LevelCatalog and builds buttons:

```gdscript
@export var catalog: LevelCatalog
@onready var level_buttons: GridContainer = %LevelButtons

func _ready() -> void:
    for child in level_buttons.get_children():
        child.queue_free()
    if catalog == null:
        push_error("LevelSelection requires LevelCatalog")
        return
    for entry in catalog.entries:
        if entry == null or entry.scene == null:
            continue
        var button := Button.new()
        button.text = entry.display_name
        button.set_meta("level_id", entry.level_id)
        button.disabled = not entry.default_unlocked
        button.pressed.connect(SceneManager.goto_level.bind(entry))
        level_buttons.add_child(button)
```

Assign `data/catalogs/level_catalog.tres` in the scene inspector.

- [ ] **Step 6: Run navigation and smoke tests**

```powershell
godot --headless --path . -s res://tests/navigation/test_level_catalog_navigation.gd
godot --headless --path . -s res://tests/smoke/test_resource_paths.gd
```

Expected: both exit 0.

- [ ] **Step 7: Commit catalog-driven navigation**

```powershell
git add data/catalogs/level_catalog.tres base/Managers/SceneManager.gd base/Managers/scene_manager.tscn ui/LevelSelection tests/navigation/test_level_catalog_navigation.gd
git commit -m "refactor: drive level navigation from catalog"
```

---

### Task 12: Remove Legacy Paths and Verify the Complete Game Loop

**Files:**
- Delete: `level/1_level/1_level.gd`
- Delete: `level/1_level/1_level.gd.uid`
- Delete: `level/1_level/1_level_spawner.gd`
- Delete: `level/1_level/1_level_spawner.gd.uid`
- Delete: `level/1_level/1_level.tscn`
- Modify: `project.godot`
- Create: `tests/integration/test_complete_game_loop.gd`
- Create: `docs/content-workflows.md`

**Interfaces:**
- Consumes: complete component-driven enemy, tower, level, and navigation stack.
- Produces: no legacy enemy/level contracts, configured physics layers, passing end-to-end loop, and a short content-author workflow derived from the approved spec.

- [ ] **Step 1: Write the end-to-end test before deleting the old level**

```gdscript
extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const LevelScene = preload("res://scenes/levels/level_01.tscn")
const EnemyScene = preload("res://scenes/enemies/enemy_streptococcus.tscn")

func _init() -> void:
    call_deferred("_run")

func _single_enemy_level_data(source: LevelData) -> LevelData:
    var data := source.duplicate(true) as LevelData
    var entry := EnemySpawnEntry.new()
    entry.enemy_scene = EnemyScene
    entry.count = 1
    entry.interval = 0.0
    entry.spawn_point_id = &"north"
    var wave := WaveData.new()
    wave.start_delay = 0.0
    wave.end_delay = 0.0
    wave.wait_for_clear = false
    wave.entries = [entry]
    data.waves = [wave]
    data.starting_energy = 100
    return data

func _run() -> void:
    var suite := TestSuite.new()
    var level := LevelScene.instantiate() as LevelController
    level.level_data = _single_enemy_level_data(level.level_data)
    root.add_child(level)
    await process_frame
    suite.expect_true(level.placement.select_tower(&"plasma_cell"), "select plasma tower")
    var build_cell := Vector2i(0, 0)
    var placed_tower := level.placement.place_at_world(level.build_grid.cell_to_world(build_cell))
    suite.expect_true(placed_tower is TowerBase, "tower placed through component")
    for _step in range(4):
        level.spawner.tick(1.0)
    var enemies := get_nodes_in_group("enemy")
    suite.expect_eq(enemies.size(), 1, "one enemy spawned")
    (enemies[0] as MonsterBase).take_damage(100000)
    await process_frame
    await process_frame
    suite.expect_eq(level.goal.outcome, LevelGoalComponent.Outcome.WON, "level reaches win")
    suite.expect_eq(get_nodes_in_group("1_enemy").size(), 0, "legacy group absent")

    paused = false
    level.queue_free()
    await process_frame
    var loss_level := LevelScene.instantiate() as LevelController
    loss_level.level_data = _single_enemy_level_data(loss_level.level_data)
    root.add_child(loss_level)
    await process_frame
    var loss_count := 0
    loss_level.goal.level_lost.connect(func(): loss_count += 1)
    loss_level.crystal.take_contact_damage(100000)
    loss_level.crystal.take_contact_damage(100000)
    suite.expect_eq(loss_count, 1, "level loss emits once")
    suite.expect_eq(loss_level.goal.outcome, LevelGoalComponent.Outcome.LOST, "loss blocks later win")
    paused = false
    suite.finish(self)
```

- [ ] **Step 2: Run the end-to-end test**

```powershell
godot --headless --path . -s res://tests/integration/test_complete_game_loop.gd
```

Expected: exit 0 before legacy deletion; if it fails, fix only the newly integrated public contracts, not the old level.

- [ ] **Step 3: Remove the superseded level implementation**

Delete the five `level/1_level` files listed above. Do not delete textures or content resources now referenced by `scenes/levels/level_01.tscn`.

- [ ] **Step 4: Configure named physics layers**

In `project.godot`, add 2D physics layer names:

```text
layer_1 = EnemyBody
layer_2 = Crystal
layer_3 = Projectile
layer_4 = TowerInteraction
layer_5 = BuildArea
```

Verify scenes use only necessary masks: crystal and projectiles detect EnemyBody; tower attack areas detect EnemyBody; build grid has no physics monitoring.

- [ ] **Step 5: Run zero-tolerance legacy scans**

Run:

```powershell
rg -n "EnemyStats|1_enemy|LEVEL_COUNT|res://(Enemies|Map|Main|Lab|LevelSelection|Towers|Textures/images)|CELL_TYPES|ENEMY_TYPES|slot_occupied" -g "*.gd" -g "*.tscn" -g "*.tres" -g "project.godot"
rg -n "HealthComponent\.new\(|MovementComponent\.new\(" -g "*.gd"
```

Expected: no matches. References in documentation describing removed legacy names are allowed; source/resource files are not.

- [ ] **Step 6: Write the concise content-author workflow**

Create `docs/content-workflows.md` with two checklists:

```markdown
## 新敌人
1. 创建 MonsterData。
2. 继承 enemy_base.tscn。
3. 指定资源、视觉和碰撞体。
4. 只为特殊行为添加组件。
5. 加入 EnemySpawnEntry 并运行敌人测试。

## 新关卡
1. 创建 WaveData 和 LevelData。
2. 继承 level_base.tscn。
3. 指定资源、背景、水晶与出生点。
4. 创建 LevelCatalogEntry。
5. 运行关卡场景与完整循环测试。
```

- [ ] **Step 7: Run the full verification suite**

```powershell
$tests = @(
  'res://tests/smoke/test_resource_paths.gd',
  'res://tests/resources/test_resource_models.gd',
  'res://tests/components/test_health_component.gd',
  'res://tests/components/test_enemy_motion_components.gd',
  'res://tests/enemies/test_enemy_base.gd',
  'res://tests/levels/test_build_grid_and_economy.gd',
  'res://tests/levels/test_crystal_controller.gd',
  'res://tests/levels/test_wave_and_goal_components.gd',
  'res://tests/levels/test_tower_placement.gd',
  'res://tests/integration/test_level_01_scene.gd',
  'res://tests/navigation/test_level_catalog_navigation.gd',
  'res://tests/integration/test_complete_game_loop.gd'
)
foreach ($test in $tests) {
  godot --headless --path . -s $test
  if ($LASTEXITCODE -ne 0) { throw "Failed: $test" }
}
```

Expected: every command exits 0.

- [ ] **Step 8: Manually verify the standard user paths in Godot 4.6**

Run the project and verify:

1. 首页 → 关卡选择只显示第 1 关；
2. 第 1 关可以选择并放置两种塔；
3. 敌人生成、移动、受伤、死亡和接触水晶正确；
4. 最后一波清空后只显示一次胜利；
5. 水晶归零后只显示一次失败；
6. 重开、返回选关、返回首页均解除暂停且不保留上一局状态。

- [ ] **Step 9: Commit the cleanup and acceptance state**

```powershell
git add -A -- level project.godot base data scenes scripts ui tests docs/content-workflows.md
git diff --cached --check
git commit -m "refactor: complete resource component migration"
```

Expected: final commit contains only legacy removal, physics configuration, final fixes, end-to-end test, and workflow documentation. Unrelated pre-existing working-tree changes remain unstaged.

---

## Final Acceptance Gate

Implementation is complete only when all conditions are true:

- Godot loads main, level selection, both enemy scenes, both tower scenes, and level 01 without parse/resource errors.
- Inspector-visible Node components own enemy and level runtime behavior.
- MonsterData, TowerData, LevelData, WaveData and catalogs own static values.
- No runtime state is written into Resource objects.
- No old resource paths, EnemyStats, `1_enemy`, fixed LEVEL_COUNT, CELL_TYPES, ENEMY_TYPES, or per-cell Area2D grid remain.
- Both enemies use inherited EnemyBase scenes without ordinary custom Controller scripts.
- Level 01 uses inherited LevelBase with no copied Controller or Spawner script.
- Plasma and Light towers both instantiate as TowerBase.
- All headless tests and the manual standard user paths pass.
- Every migration task is an independent commit and unrelated user changes remain untouched.
