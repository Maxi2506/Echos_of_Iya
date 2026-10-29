extends CanvasLayer
## Interfaz durante el juego: corazones, contador de cristales, avisos y botón de pausa.

signal pause_pressed

const HEART_FULL = preload("res://assets/img/ui/heart_full.png")
const HEART_EMPTY = preload("res://assets/img/ui/heart_empty.png")

@onready var hearts: HBoxContainer = $Hearts
@onready var crystals_label: Label = $CrystalsLabel
@onready var toast: Label = $Toast

var total_crystals := 0
var _toast_queue: Array[String] = []
var _toast_busy := false

func set_total_crystals(total: int) -> void:
	total_crystals = total

func update_score(score: int) -> void:
	crystals_label.text = "%s: %d/%d" % [tr("Crystals"), score, total_crystals]

func update_health(health: int, _max_health: int) -> void:
	for i in hearts.get_child_count():
		hearts.get_child(i).texture = HEART_FULL if i < health else HEART_EMPTY

# Mensaje corto arriba al centro que se desvanece solo (ej. "Punto de control").
# Si ya hay uno en pantalla, el nuevo espera su turno.
func show_toast(text: String) -> void:
	_toast_queue.append(text)
	if not _toast_busy:
		_show_next_toast()

func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_busy = false
		return
	_toast_busy = true
	toast.text = _toast_queue.pop_front()
	toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.finished.connect(_show_next_toast)

func _on_pause_button_pressed() -> void:
	pause_pressed.emit()
