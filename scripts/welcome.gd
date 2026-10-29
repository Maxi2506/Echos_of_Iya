extends Control

const GAME_SCENE_PATH = "res://scenes/game.tscn"
const OPTIONS_SCENE_PATH = "res://scenes/options.tscn"

@onready var start_button: Button = $ContenedorPrincipal/Start
@onready var load_button: Button = $ContenedorPrincipal/Load

func _ready() -> void:
	# "Load" solo se puede usar si hay una partida guardada
	load_button.disabled = not SaveGame.has_save()
	# Al pasar el mouse, el botón toma el foco: así el teclado y el mouse marcan el mismo botón
	for button in $ContenedorPrincipal.get_children():
		button.mouse_entered.connect(button.grab_focus)
	start_button.grab_focus()

func _on_start_pressed() -> void:
	SaveGame.load_pending = false
	SaveGame.checkpoint_active = false
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_load_pressed() -> void:
	SaveGame.load_pending = true
	SaveGame.checkpoint_active = true
	get_tree().change_scene_to_file(SaveGame.read().get("level", GAME_SCENE_PATH))

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE_PATH)

func _on_exit_pressed() -> void:
	get_tree().quit()
