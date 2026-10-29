extends CanvasLayer
## Menú de pausa. Se abre con Escape, con P o con el botón "II" del HUD.
## Tiene process_mode = Always para seguir funcionando con el juego pausado.

signal save_requested

const WELCOME_SCENE_PATH = "res://scenes/welcome.tscn"

@onready var resume_button: Button = $Menu/Resume
@onready var message_label: Label = $Menu/Message
@onready var controls_hint: Label = $ControlsHint

func _ready() -> void:
	hide()
	for button in $Menu.get_children():
		if button is Button:
			button.mouse_entered.connect(button.grab_focus)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	message_label.text = ""
	# Recordatorio de teclas; se arma acá para que salga en el idioma elegido
	controls_hint.text = "← → %s   •   %s %s   •   X %s   •   Shift %s   •   Esc %s" % [
		tr("Move"), tr("Space"), tr("Jump"), tr("Attack"), tr("Stealth"), tr("Resume")]
	show()
	get_tree().paused = true
	resume_button.grab_focus()

func close() -> void:
	hide()
	get_tree().paused = false

func show_message(text: String) -> void:
	message_label.text = text

func _on_resume_pressed() -> void:
	close()

func _on_save_pressed() -> void:
	save_requested.emit()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(WELCOME_SCENE_PATH)
