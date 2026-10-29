extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body):
	print("You died...")
	Engine.time_scale = 0.5
	body.get_node("CollisionShape2D").queue_free()
	timer.start()


func _on_timer_timeout():
	Engine.time_scale = 1.0
	# Si hay un punto guardado en esta partida, se reaparece ahí; si no, desde el principio
	SaveGame.load_pending = SaveGame.checkpoint_active
	get_tree().reload_current_scene()
