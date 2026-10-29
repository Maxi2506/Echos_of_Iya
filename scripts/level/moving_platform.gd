extends AnimatableBody2D
## Plataforma que va y viene entre su posición inicial y la posición + travel.

@export var travel := Vector2(64, 0)
@export var duration := 2.0
## Pausa en cada extremo
@export var wait := 0.4

func _ready() -> void:
	var start := position
	var tween := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", start + travel, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(wait)
	tween.tween_property(self, "position", start, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(wait)
