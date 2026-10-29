extends Area2D
## Fogata: punto de control.
## Arranca apagada (con humo) y se enciende cuando pasa el jugador.
## Cada vez que el jugador la toca avisa al nivel, que guarda la partida y lo cura.

signal activated(campfire: Area2D)

# Dónde reaparece el jugador respecto de la fogata (al costado, no encima del fuego)
@export var respawn_offset := Vector2(20, 0)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $Luz
@onready var smoke: CPUParticles2D = $Humo
@onready var embers: CPUParticles2D = $Brasas
@onready var ignite_sound: AudioStreamPlayer2D = $IgniteSound

var lit := false
var _time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_lit(false)

func _process(delta: float) -> void:
	# Parpadeo suave de la luz del fuego
	if lit:
		_time += delta
		light.energy = 0.85 + sin(_time * 9.0) * 0.08 + sin(_time * 23.0) * 0.05

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or body.is_dead:
		return
	if not lit:
		set_lit(true)
		ignite_sound.play()
	activated.emit(self)

func set_lit(value: bool) -> void:
	lit = value
	sprite.play("idle" if lit else "off")
	light.enabled = lit
	smoke.emitting = not lit
	embers.emitting = lit

func respawn_position() -> Vector2:
	return global_position + respawn_offset
