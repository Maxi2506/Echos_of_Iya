extends Control

@onready var volume_button: Button = $ContenedorPrincipal/Volume
@onready var difficulty_button: Button = $ContenedorPrincipal/Difficulty
@onready var language_button: Button = $ContenedorPrincipal/Language

func _ready() -> void:
	for button in $ContenedorPrincipal.get_children():
		button.mouse_entered.connect(button.grab_focus)
	_update_texts()
	volume_button.grab_focus()

func _on_volume_pressed() -> void:
	Settings.next_volume()
	_update_texts()

func _on_difficulty_pressed() -> void:
	Settings.next_difficulty()
	_update_texts()

func _on_language_pressed() -> void:
	Settings.next_language()
	_update_texts()

# Los botones con valor se arman a mano porque cambian; el resto se traduce solo
func _update_texts() -> void:
	volume_button.text = "%s: %d%%" % [tr("Volume"), Settings.volume]
	difficulty_button.text = "%s: %s" % [tr("Difficulty"), Settings.difficulty_name()]
	language_button.text = "%s: %s" % [tr("Language"), Settings.language_name()]

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/controls.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/welcome.tscn")
