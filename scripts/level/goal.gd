extends Area2D
## Meta del nivel (el torii del nivel 1 o el Cristal del Eco del nivel 2).
## Cuando el jugador la toca, avisa al nivel una sola vez.

signal reached

## Si el sprite es una tira de cuadros (como el cristal), se anima solo
@export var animation_fps := 10.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = get_node_or_null("Luz")

var _done := false
var _time := 0.0

func _ready() -> void:
	add_to_group("goal")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	if sprite.hframes > 1:
		sprite.frame = int(_time * animation_fps) % sprite.hframes
	if light:
		light.energy = 0.9 + sin(_time * 2.5) * 0.25

func _on_body_entered(body: Node2D) -> void:
	if _done or not body.is_in_group("player") or body.is_dead:
		return
	_done = true
	reached.emit()
