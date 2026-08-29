class_name TowerVisual
extends Node2D

## 塔的视觉类：按模式/充能层数换外观，显示冷却倒计时
## 根脚本只调用这里的方法，不直接碰任何 Sprite/Label

func apply_visual(mode: int, level: int) -> void:
	# 按 mode（生产/攻击/充能）+ level（0~3）切换外观
	# 例：mode 决定颜色/图标，level 决定发光强度或层数角标
	pass

func show_cooling(seconds: float) -> void:
	# 更新冷却倒计时 Label 文本，<= 0 时隐藏
	pass
