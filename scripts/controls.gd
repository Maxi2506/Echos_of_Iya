extends Control
## Pantalla que muestra las teclas del juego. Se abre desde Opciones.
## Los textos se traducen solos (ver Settings.SPANISH).

@onready var back_button: Button = $Contenedor/Back

func _ready() -> void:
	back_button.grab_focus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")
