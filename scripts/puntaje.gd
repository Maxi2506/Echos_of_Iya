extends Node

signal score_changed(score: int)

var score = 0

func add_point():
	score += 1
	score_changed.emit(score)
