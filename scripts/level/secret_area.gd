extends Area2D
## Zona secreta: una pared (o piso) que parece sólida pero se puede atravesar.
## Los tiles falsos están en el TileMapLayer hijo "Tiles", sin colisión.
## Al entrar, la pared se vuelve casi transparente y cuenta como secreto encontrado.

signal found(area: Area2D)

@onready var tiles: TileMapLayer = $Tiles
@onready var sound: AudioStreamPlayer = $FoundSound

var is_found := false

func _ready() -> void:
	add_to_group("secrets")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_found or not body.is_in_group("player"):
		return
	set_found(true)
	sound.play()
	found.emit(self)

## animate = false al cargar una partida (ya estaba descubierto)
func set_found(value: bool, animate := true) -> void:
	is_found = value
	var alpha := 0.25 if value else 1.0
	if animate:
		create_tween().tween_property(tiles, "modulate:a", alpha, 0.4)
	else:
		tiles.modulate.a = alpha
