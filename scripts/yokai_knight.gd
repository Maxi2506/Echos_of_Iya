extends CharacterBody2D

const SPEED = 70.0
var direction = 1

# Traemos la gravedad para que caiga de verdad
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	# 1. Gravedad (Si está en el aire, cae)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# 2. Lógica de patrulla (Solo si está en el suelo)
	if is_on_floor():
		if ray_cast_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = true
		elif ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false

	# 3. Aplicar movimiento físico real
	velocity.x = direction * SPEED
	move_and_slide()
	
	# 4. Animaciones optimizadas (Solo se ejecuta .play() si cambia de estado)
	if velocity.x == 0:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
