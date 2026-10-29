extends CanvasLayer
## Pantalla de muerte: oscurece la pantalla y ofrece reintentar o volver al menú.
## "Reintentar" vuelve a la última fogata encendida (o al inicio si no hay ninguna).

const WELCOME_SCENE_PATH = "res://scenes/welcome.tscn"

@onready var fondo: ColorRect = $Fondo
@onready var menu: VBoxContainer = $Menu
@onready var retry_button: Button = $Menu/Retry

func _ready() -> void:
	for button in menu.get_children():
		if button is Button:
			button.mouse_entered.connect(button.grab_focus)

func open() -> void:
	fondo.color.a = 0.0
	menu.modulate.a = 0.0
	show()
	get_tree().paused = true
	var tween := create_tween()
	tween.tween_property(fondo, "color:a", 0.8, 0.6)
	tween.tween_property(menu, "modulate:a", 1.0, 0.4)
	retry_button.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	SaveGame.load_pending = SaveGame.checkpoint_active
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(WELCOME_SCENE_PATH)
