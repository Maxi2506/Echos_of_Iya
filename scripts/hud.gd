extends CanvasLayer
## Interfaz durante el juego: corazones, contador de cristales, avisos y botón de pausa.

signal pause_pressed

const HEART_FULL = preload("res://assets/img/ui/heart_full.png")
const HEART_EMPTY = preload("res://assets/img/ui/heart_empty.png")

@onready var hearts: HBoxContainer = $Hearts
@onready var crystals_label: Label = $CrystalsLabel
@onready var toast: Label = $Toast

var total_crystals := 0
var _toast_tween: Tween

func set_total_crystals(total: int) -> void:
	total_crystals = total

func update_score(score: int) -> void:
	crystals_label.text = "%s: %d/%d" % [tr("Crystals"), score, total_crystals]

func update_health(health: int, _max_health: int) -> void:
	for i in hearts.get_child_count():
		hearts.get_child(i).texture = HEART_FULL if i < health else HEART_EMPTY

# Mensaje corto arriba al centro que se desvanece solo (ej. "Punto de control")
func show_toast(text: String) -> void:
	toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.6)

func _on_pause_button_pressed() -> void:
	pause_pressed.emit()
