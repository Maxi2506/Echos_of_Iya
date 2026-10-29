extends CharacterBody2D

const SPEED = 70.0
var direction = 1
var muerto := false

# Traemos la gravedad para que caiga de verdad
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var killzone: Area2D = $killzone
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

func _physics_process(delta):
	# 1. Gravedad (Si está en el aire, cae)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if muerto:
		velocity.x = 0
		move_and_slide()
		return

	# 2. Lógica de patrulla (Solo si está en el suelo)
	if is_on_floor():
		if ray_cast_right.is_colliding():
			direction = -1
		elif ray_cast_left.is_colliding():
			direction = 1

	# 3. Aplicar movimiento físico real
	velocity.x = direction * SPEED * Settings.enemy_speed_multiplier()
	move_and_slide()

	# Si choca contra una pared o una pendiente empinada, da la vuelta
	if is_on_wall():
		direction = 1 if get_wall_normal().x > 0 else -1
	animated_sprite.flip_h = direction < 0

	# 4. Animaciones optimizadas (Solo se ejecuta .play() si cambia de estado)
	if velocity.x == 0:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")

# Lo llama el ataque del jugador
func morir() -> void:
	if muerto:
		return
	muerto = true
	# Deja de matar al jugador y de recibir golpes
	killzone.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	animated_sprite.play("death")
	death_sound.play()
	await animated_sprite.animation_finished
	queue_free()
