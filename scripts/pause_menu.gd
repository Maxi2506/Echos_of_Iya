extends CanvasLayer
## Menú de pausa. Se abre con Escape, con P o con el botón "II" del HUD.
## Tiene process_mode = Always para seguir funcionando con el juego pausado.

signal map_requested

const WELCOME_SCENE_PATH = "res://scenes/welcome.tscn"

@onready var resume_button: Button = $Menu/Resume
@onready var controls_hint: Label = $ControlsHint

# El nivel lo pone en false cuando el jugador muere, para no pausar sobre la pantalla de muerte
var enabled := true

func _ready() -> void:
	hide()
	for button in $Menu.get_children():
		if button is Button:
			button.mouse_entered.connect(button.grab_focus)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and (enabled or visible):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if not enabled:
		return
	# Recordatorio de teclas; se arma acá para que salga en el idioma elegido
	controls_hint.text = "← → %s  •  %s %s  •  X %s  •  Shift %s  •  M %s  •  Esc %s" % [
		tr("Move"), tr("Space"), tr("Jump"), tr("Attack"), tr("Stealth"), tr("Map"), tr("Resume")]
	show()
	get_tree().paused = true
	resume_button.grab_focus()

func close() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	close()

func _on_map_pressed() -> void:
	close()
	map_requested.emit()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(WELCOME_SCENE_PATH)
