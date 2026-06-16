extends Area2D

@onready var puntaje: Node = %Puntaje
@onready var animation_player = $AnimationPlayer

func _on_body_entered(body): 
	puntaje.add_point()
	animation_player.play("pickup")
