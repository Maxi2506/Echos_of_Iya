extends CanvasLayer
## Interfaz durante el juego: contador de cristales y botón de pausa.

signal pause_pressed

@onready var crystals_label: Label = $CrystalsLabel

var total_crystals := 0

func set_total_crystals(total: int) -> void:
	total_crystals = total

func update_score(score: int) -> void:
	crystals_label.text = "%s: %d/%d" % [tr("Crystals"), score, total_crystals]

func _on_pause_button_pressed() -> void:
	pause_pressed.emit()
