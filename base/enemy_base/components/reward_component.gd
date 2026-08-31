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
