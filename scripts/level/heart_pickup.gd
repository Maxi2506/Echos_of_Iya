extends Area2D
## Corazón que recupera 1 de vida. Si el jugador tiene la vida llena, no se consume.
## Algunos están puestos en el nivel y otros los sueltan los enemigos al morir.

@onready var sprite: Sprite2D = $Sprite2D

var _time := randf() * TAU
var _taken := false

func _ready() -> void:
	add_to_group("hearts")

func _physics_process(delta: float) -> void:
	_time += delta
	sprite.position.y = -6 + sin(_time * 3.0) * 2.0
	if _taken:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.heal(1):
			_taken = true
			var tween := create_tween()
			tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
			tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
			tween.tween_callback(queue_free)
