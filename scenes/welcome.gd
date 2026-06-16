extends Control

# Reemplaza "res://ValleDeIya.tscn" por la ruta real de la escena de tu juego
const GAME_SCENE_PATH = "res://game.tscn"

func _on_start_pressed() -> void:
	# Cambia a la escena del nivel principal
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_load_pressed() -> void:
	# Aquí irá tu lógica de cargar partida más adelante
	print("Cargando partida guardada...")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_exit_pressed() -> void:
	# Cierra el juego por completo (solo funciona en el juego exportado o ejecutado)
	get_tree().quit()
