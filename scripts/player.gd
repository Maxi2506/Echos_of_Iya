extends CharacterBody2D

const SPEED = 150.0
const WALK_SPEED = 65.0 # 🥷 Nueva velocidad reducida para el sigilo
const JUMP_VELOCITY = -320.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound

# Distancia horizontal de la hitbox del ataque respecto al centro del jugador
const ATTACK_REACH = 26.0
# Cuadros de la animación "attack" en los que se ve el corte de la espada (0, 1 y 2)
const ATTACK_ACTIVE_FRAMES = 3

# Variable para controlar si el personaje está ejecutar un ataque
var is_attacking: bool = false

func _ready() -> void:
	# Conectamos de forma segura la señal de fin de animación
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	# Aplicar gravedad nativa de Godot 4
	if not is_on_floor():
		velocity += get_gravity() * delta

	# ATAQUE: Detecta la tecla X (acción "attack")
	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_attacking:
		is_attacking = true
		velocity.x = 0
		attack_shape.set_deferred("disabled", false)
		attack_sound.play()

	# SALTO: Acción nativa "ui_accept" (Barra Espaciadora)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Obtener la dirección de movimiento usando las flechas del teclado
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# DETECTAR SI ESTÁ CAMINANDO: Verifica si mantiene presionado Shift
	# Solo permitimos caminar sigilosamente si está tocando el suelo
	var is_walking: bool = Input.is_action_pressed("walk") and is_on_floor()
	
	# Si NO está atacando, permitimos que se mueva y gire libremente
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
	else:
		if is_on_floor():
			velocity.x = 0
	
	# Animación
	if is_attacking:
		animated_sprite.play("attack")
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		elif is_walking:
			animated_sprite.play("walk") 
		else:
			animated_sprite.play("run") 
	else:
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")

	move_and_slide()

# Esta función se activa sola cuando termina cualquier animación
func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		attack_shape.set_deferred("disabled", true)

# Apaga la hitbox cuando termina el corte de la espada
func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack" and animated_sprite.frame >= ATTACK_ACTIVE_FRAMES:
		attack_shape.set_deferred("disabled", true)

# La hitbox solo detecta cuerpos de la capa "enemigos" (capa 3)
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("morir"):
		body.morir()
