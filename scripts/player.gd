extends CharacterBody2D
## Jugador: movimiento, ataque, vida (corazones), daño y muerte.

signal health_changed(health: int, max_health: int)
signal died

const SPEED = 150.0
const WALK_SPEED = 65.0 # Velocidad reducida para el sigilo
const JUMP_VELOCITY = -345.0

# Distancia horizontal de la hitbox del ataque respecto al centro del jugador
const ATTACK_REACH = 26.0
# Cuadros de la animación "attack" en los que se ve el corte de la espada (0, 1 y 2)
const ATTACK_ACTIVE_FRAMES = 3

const MAX_HEALTH = 3
const INVULNERABLE_TIME = 1.0 # Segundos sin recibir daño después de un golpe
const KNOCKBACK = Vector2(170, -190)
const STUN_TIME = 0.3 # Segundos sin control durante el empujón
# Cuánto puede bajar por debajo del borde inferior de la cámara antes de morir por caída
const FALL_MARGIN = 16.0
# Margen para saltar justo después de salir de un borde, y para que un salto apretado
# un poquito antes de tocar el piso igual cuente
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.12
# Al soltar el salto antes de tiempo, la subida se corta (salto corto)
const JUMP_CUT = 0.45

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound
@onready var block_sound: AudioStreamPlayer2D = $BlockSound
@onready var heal_sound: AudioStreamPlayer2D = $HealSound
@onready var block_sparks: CPUParticles2D = $BlockSparks
@onready var camera: Camera2D = get_node_or_null("Camera2D")

var is_attacking := false
# Defendiéndose con la espada (tecla C): frena los golpes que vienen de frente
var is_blocking := false
# Caminando con Shift: los enemigos te ven solo de muy cerca
var is_sneaking := false
var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var health := MAX_HEALTH
var is_dead := false
var invulnerable := false
var stun_left := 0.0

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_dead:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	# Caída a un pozo: muere apenas sale de la vista, sin esperar
	if camera and global_position.y > camera.limit_bottom + FALL_MARGIN:
		die(true)
		return

	# Durante el empujón de un golpe no se puede controlar al personaje
	if stun_left > 0:
		stun_left -= delta
		move_and_slide()
		return

	var direction := Input.get_axis("ui_left", "ui_right")

	# DEFENSA: tecla C (acción "block"). Solo en el piso; mientras se defiende no camina,
	# pero puede darse vuelta para cubrirse del otro lado.
	is_blocking = Input.is_action_pressed("block") and is_on_floor() and not is_attacking
	if is_blocking:
		if direction != 0:
			_face(direction)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("block")
		move_and_slide()
		return

	# ATAQUE: tecla X (acción "attack"). En el aire también se puede.
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		if is_on_floor():
			velocity.x = 0
		attack_shape.set_deferred("disabled", false)
		attack_sound.play()

	# SALTO: barra espaciadora (acción "jump"), con margen de coyote y de anticipación
	_coyote_left = COYOTE_TIME if is_on_floor() else _coyote_left - delta
	_jump_buffer_left = JUMP_BUFFER_TIME if Input.is_action_just_pressed("jump") else _jump_buffer_left - delta
	if _jump_buffer_left > 0 and _coyote_left > 0 and not (is_attacking and is_on_floor()):
		velocity.y = JUMP_VELOCITY
		_jump_buffer_left = 0
		_coyote_left = 0
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT

	# Caminar en sigilo con Shift, solo tocando el suelo
	is_sneaking = Input.is_action_pressed("walk")
	var is_walking: bool = is_sneaking and is_on_floor()

	if not is_attacking:
		if direction != 0:
			_face(direction)

		if direction:
			var current_speed = WALK_SPEED if is_walking else SPEED
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	elif is_on_floor():
		velocity.x = 0
	else:
		velocity.x = direction * SPEED # en el aire se puede seguir moviendo mientras ataca

	if is_attacking:
		animated_sprite.play("attack")
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		elif is_walking:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("run")
	elif velocity.y < 0:
		animated_sprite.play("jump")
	else:
		animated_sprite.play("fall")

	move_and_slide()


func _face(direction: float) -> void:
	var right := direction > 0
	animated_sprite.flip_h = not right
	attack_shape.position.x = ATTACK_REACH if right else -ATTACK_REACH
	block_sparks.position.x = absf(block_sparks.position.x) * (1 if right else -1)
	block_sparks.direction.x = absf(block_sparks.direction.x) * (1 if right else -1)


# --- Vida y daño ---

func heal_full() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)

## Corazones del nivel: devuelve false si ya estaba con la vida llena (y no se consume)
func heal(amount: int) -> bool:
	if is_dead or health >= MAX_HEALTH:
		return false
	health = mini(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)
	heal_sound.play()
	var tween := create_tween()
	animated_sprite.modulate = Color(0.6, 1.4, 0.7)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.35)
	return true

## ¿El golpe viene de adelante? (la defensa solo cubre el frente)
func _blocks_from(from_position: Vector2) -> bool:
	var facing := -1.0 if animated_sprite.flip_h else 1.0
	var dx := from_position.x - global_position.x
	return is_blocking and (absf(dx) < 4.0 or signf(dx) == facing)

# Lo llaman las zonas de daño (enemigos). from_position sirve para empujar hacia el lado contrario;
# source es el enemigo que pegó (si se bloquea, se lo empuja hacia atrás).
func hurt(from_position: Vector2, source: Node = null) -> void:
	if is_dead or invulnerable:
		return
	if _blocks_from(from_position):
		_on_blocked(from_position, source)
		return
	health -= 1
	health_changed.emit(health, MAX_HEALTH)
	_cancel_attack()
	hurt_sound.play()
	if health <= 0:
		die(false)
		return
	var push_dir := signf(global_position.x - from_position.x)
	if push_dir == 0:
		push_dir = 1.0 if animated_sprite.flip_h else -1.0
	velocity = Vector2(push_dir * KNOCKBACK.x, KNOCKBACK.y)
	stun_left = STUN_TIME
	_hit_stop(0.06)
	_shake(2.0)
	_blink_invulnerable()

# fell = true cuando cae a un pozo: no hay animación porque ya no se lo ve
func die(fell: bool) -> void:
	if is_dead:
		return
	is_dead = true
	health = 0
	health_changed.emit(health, MAX_HEALTH)
	_cancel_attack()
	# Las zonas de daño y los cristales dejan de detectarlo
	set_deferred("collision_layer", 0)
	if fell:
		died.emit()
		return
	velocity = Vector2.ZERO
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play("death")
	_hit_stop(0.12)
	_shake(3.0)
	await animated_sprite.animation_finished
	died.emit()


func _on_blocked(from_position: Vector2, source: Node) -> void:
	block_sound.play()
	block_sparks.restart()
	velocity.x = signf(global_position.x - from_position.x) * 90.0
	_shake(1.0)
	if source and source.has_method("blocked"):
		source.blocked(global_position)
	# un instante sin recibir golpes para que el mismo ataque no se procese de nuevo
	invulnerable = true
	await get_tree().create_timer(0.25, false).timeout
	invulnerable = false


# --- Efectos ---

# Congela el juego un instante para que el golpe se sienta
func _hit_stop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _shake(strength: float) -> void:
	if camera == null:
		return
	var tween := create_tween()
	for i in 6:
		var shake_offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(camera, "offset", shake_offset, 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)

# Parpadea en rojo mientras dura la invencibilidad
func _blink_invulnerable() -> void:
	invulnerable = true
	var tween := create_tween().set_loops(int(INVULNERABLE_TIME / 0.1))
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.4, 0.4, 0.4), 0.05)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.05)
	await get_tree().create_timer(INVULNERABLE_TIME, false).timeout
	tween.kill()
	if not is_dead:
		animated_sprite.modulate = Color.WHITE
	invulnerable = false


# --- Ataque ---

func _cancel_attack() -> void:
	is_attacking = false
	attack_shape.set_deferred("disabled", true)

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		_cancel_attack()

# Apaga la hitbox cuando termina el corte de la espada
func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack" and animated_sprite.frame >= ATTACK_ACTIVE_FRAMES:
		attack_shape.set_deferred("disabled", true)

# La hitbox solo detecta cuerpos de la capa "enemigos" (capa 3)
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit(global_position)
