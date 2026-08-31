class_name GridCell
extends Node2D

var cell: Vector2

func setup(c: Vector2) -> void:
	cell = c
	name = "GridCell_%d_%d" %[c.x, c.y]
