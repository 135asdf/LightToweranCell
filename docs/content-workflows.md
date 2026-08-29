# 内容制作流程

> 详细敌人制作步骤见 `docx/制作敌人流程.md`；本文档为资源驱动架构下的精简清单。

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
