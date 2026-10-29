extends Area2D
## Zona que lastima al jugador.
## Los enemigos la usan para el daño por contacto (quita un corazón).
## Con instant_kill (pozos y abismos) mata de una.

@export var instant_kill := false

func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	# Se revisa en cada cuadro, no solo al entrar: si el jugador sigue tocando
	# al enemigo cuando se le termina la invencibilidad, vuelve a recibir daño.
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if instant_kill:
			body.die(true)
		else:
			body.hurt(global_position)
