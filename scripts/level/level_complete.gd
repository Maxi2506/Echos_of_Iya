extends CanvasLayer
## Pantalla de fin de nivel: título, estadísticas y botones.
## En el último nivel no hay "Continuar", solo "Menú principal".

signal continue_pressed

const WELCOME_SCENE_PATH = "res://scenes/welcome.tscn"

@onready var fondo: ColorRect = $Fondo
@onready var menu: VBoxContainer = $Menu
@onready var title_label: Label = $Menu/Title
@onready var stats_box: VBoxContainer = $Menu/Stats
@onready var continue_button: Button = $Menu/Continue
@onready var main_menu_button: Button = $Menu/MainMenu
@onready var sound: AudioStreamPlayer = $Sound

func _ready() -> void:
	for button in [continue_button, main_menu_button]:
		button.mouse_entered.connect(button.grab_focus)

## stats: lista de pares [texto, valor]
func open(title: String, stats: Array, is_final: bool) -> void:
	title_label.text = title
	for child in stats_box.get_children():
		child.queue_free()
	for entry in stats:
		var row := Label.new()
		row.text = "%s:  %s" % entry
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 30)
		stats_box.add_child(row)
	continue_button.visible = not is_final

	fondo.color.a = 0.0
	menu.modulate.a = 0.0
	show()
	get_tree().paused = true
	sound.play()
	var tween := create_tween()
	tween.tween_property(fondo, "color:a", 0.85, 0.8)
	tween.tween_property(menu, "modulate:a", 1.0, 0.5)
	(continue_button if not is_final else main_menu_button).grab_focus()

func _on_continue_pressed() -> void:
	get_tree().paused = false
	continue_pressed.emit()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(WELCOME_SCENE_PATH)
