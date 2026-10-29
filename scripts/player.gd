extends CharacterBody2D
## Jugador: movimiento, ataque, vida (corazones), daño y muerte.

signal health_changed(health: int, max_health: int)
signal died

const SPEED = 150.0
const WALK_SPEED = 65.0 # Velocidad reducida para el sigilo
const JUMP_VELOCITY = -320.0

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

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound
@onready var camera: Camera2D = get_node_or_null("Camera2D")

var is_attacking := false
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

	# ATAQUE: tecla X (acción "attack")
	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_attacking:
		is_attacking = true
		velocity.x = 0
		attack_shape.set_deferred("disabled", false)
		attack_sound.play()

	# SALTO: acción nativa "ui_accept" (barra espaciadora)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	# Caminar en sigilo con Shift, solo tocando el suelo
	var is_walking: bool = Input.is_action_pressed("walk") and is_on_floor()

	if not is_attacking:
		if direction > 0:
			animated_sprite.flip_h = false
			attack_shape.position.x = ATTACK_REACH
		elif direction < 0:
			animated_sprite.flip_h = true
			attack_shape.position.x = -ATTACK_REACH

		if direction:
			var current_speed = WALK_SPEED if is_walking else SPEED
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	elif is_on_floor():
		velocity.x = 0

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


# --- Vida y daño ---

func heal_full() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)

# Lo llaman las zonas de daño (enemigos). from_position sirve para empujar hacia el lado contrario.
func hurt(from_position: Vector2) -> void:
	if is_dead or invulnerable:
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
	if body.has_method("morir"):
		body.morir()
