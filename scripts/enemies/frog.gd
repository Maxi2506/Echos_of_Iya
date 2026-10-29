extends Enemy
## Rana: no camina, se mueve a saltos. Si ve al jugador, salta hacia él más seguido.

@export var hop_velocity := Vector2(75, -210)
@export var hop_interval := 1.6
@export var chase_hop_interval := 0.8

var _hop_wait := 0.0

func _ready() -> void:
	super()
	_hop_wait = randf_range(0.3, hop_interval)

func _patrol(delta: float) -> void:
	_hop(delta, hop_interval)
	if _can_see_player():
		_alert_player()

func _chase(delta: float) -> void:
	var player := _player()
	if player == null or player.is_dead or not _can_see_player():
		_lost_time += delta
		if _lost_time > 2.0:
			_alert.visible = false
			_change_state(State.PATROL)
	else:
		_lost_time = 0.0
		if is_on_floor():
			_set_facing(1 if player.global_position.x > global_position.x else -1)
	_hop(delta, chase_hop_interval)

func _hop(delta: float, interval: float) -> void:
	if not is_on_floor():
		return # en el aire conserva el impulso del salto
	velocity.x = 0
	_hop_wait -= delta
	if _hop_wait > 0:
		return
	_hop_wait = interval
	if _hits_wall() or not _floor_ahead(56):
		_set_facing(-direction)
		if not _floor_ahead(56):
			return # no hay piso de ningún lado: se queda quieta
	velocity = Vector2(direction * hop_velocity.x * _speed_multiplier(), hop_velocity.y)

func _update_animation() -> void:
	if state == State.DEAD:
		return
	var anim := "jump" if not is_on_floor() else "idle"
	if sprite.animation != anim:
		sprite.play(anim)
