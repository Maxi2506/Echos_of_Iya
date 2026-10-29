extends Area2D

@onready var puntaje: Node = %Puntaje
@onready var animation_player = $AnimationPlayer

# Evita contarlo dos veces y permite saber qué cristales faltan al guardar la partida
var collected := false

func _ready() -> void:
	add_to_group("crystals")

func _on_body_entered(_body):
	if collected:
		return
	collected = true
	puntaje.add_point()
	animation_player.play("pickup")
