class_name Enemy
extends CharacterBody2D
## Comportamiento común de todos los enemigos:
## patrullar sin caerse por los bordes, ver al jugador (el sigilo lo hace más difícil),
## perseguirlo, atacar, recibir golpes y morir.
##
## Cada enemigo es una escena con estos nodos:
##   AnimatedSprite2D  animaciones "idle", "run" y opcionales "attack", "hit", "death"
##   CollisionShape2D  cuerpo (choca con el mundo)
##   killzone          daño por contacto
##   AttackArea        (opcional) killzone que solo se activa en los cuadros del ataque
##   HitSound, DeathSound, AttackSound (opcionales)

signal died(enemy: Enemy)

enum State { PATROL, CHASE, ATTACK, HURT, DEAD }

@export var max_health := 1
@export var patrol_speed := 40.0
@export var chase_speed := 70.0
@export var can_chase := true
## Distancia a la que ve al jugador si corre (de frente)
@export var detect_range := 120.0
## Distancia a la que ve al jugador si camina en sigilo (Shift)
@export var sneak_detect_range := 34.0
## 0 = no ataca, solo hace daño por contacto
@export var attack_range := 0.0
## Cuadros de la animación "attack" en los que el golpe hace daño
@export var attack_active_frames: PackedInt32Array = PackedInt32Array()
@export var attack_cooldown := 1.0
## Hacia dónde mira el dibujo original
@export var faces_right := true
## Corrección horizontal para que el cuerpo del dibujo quede centrado en el nodo
@export var sprite_offset_x := 0.0
## Ancho del cuerpo, para revisar el borde del piso un poco por delante
@export var body_half_width := 9.0
## Color de las partículas al morir (si no tiene animación "death")
@export var death_color := Color(0.6, 0.9, 1.0)
## Dificultad mínima en la que aparece: 0 = siempre, 1 = normal y difícil, 2 = solo difícil
@export_range(0, 2) var min_difficulty := 0
## Probabilidad de soltar un corazón al morir
@export_range(0.0, 1.0) var heart_drop_chance := 0.3

const HEART_SCENE := preload("res://scenes/level/heart_pickup.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var contact: Area2D = $killzone
@onready var attack_area: Area2D = get_node_or_null("AttackArea")
@onready var hit_sound: AudioStreamPlayer2D = get_node_or_null("HitSound")
@onready var death_sound: AudioStreamPlayer2D = get_node_or_null("DeathSound")
@onready var attack_sound: AudioStreamPlayer2D = get_node_or_null("AttackSound")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := 1
var direction := 1
var state := State.PATROL
var is_dead := false
var _cooldown := 0.0
var _lost_time := 0.0
var _hurt_time := 0.0
var _floor_ray: RayCast2D
var _alert: Label
var _attack_shape_x := 0.0


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	collision_layer = 4 # capa "enemigos": la espada del jugador la detecta
	collision_mask = 1
	floor_max_angle = deg_to_rad(15) # las pendientes empinadas cuentan como pared

	_floor_ray = RayCast2D.new()
	_floor_ray.target_position = Vector2(0, 20)
	_floor_ray.position.y = -4
	add_child(_floor_ray)

	_alert = Label.new()
	_alert.text = "!"
	_alert.add_theme_font_override("font", preload("res://assets/fonts/VCR_OSD_MONO_1.001.ttf"))
	_alert.add_theme_font_size_override("font_size", 16)
	_alert.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_alert.add_theme_color_override("font_outline_color", Color.BLACK)
	_alert.add_theme_constant_override("outline_size", 4)
	_alert.position = Vector2(-4, -60)
	_alert.visible = false
	add_child(_alert)

	if attack_area:
		attack_area.monitoring = false
		var shape := attack_area.get_node("CollisionShape2D")
		_attack_shape_x = absf(shape.position.x)

	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	_set_facing(direction)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	_cooldown -= delta

	match state:
		State.DEAD:
			velocity.x = 0
		State.HURT:
			velocity.x = move_toward(velocity.x, 0, 500 * delta)
			_hurt_time -= delta
			if _hurt_time <= 0:
				_change_state(State.CHASE if can_chase else State.PATROL)
		State.ATTACK:
			velocity.x = 0
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase(delta)

	move_and_slide()
	_update_animation()


# --- Comportamiento (los enemigos especiales pueden reemplazar estas funciones) ---

func _patrol(_delta: float) -> void:
	velocity.x = direction * patrol_speed * _speed_multiplier()
	if is_on_floor() and (_hits_wall() or _at_edge()):
		_set_facing(-direction)
		velocity.x = 0
	if can_chase and _can_see_player():
		_alert_player()


func _chase(delta: float) -> void:
	var player := _player()
	if player == null or player.is_dead:
		_change_state(State.PATROL)
		return
	var to_player := player.global_position - global_position
	if absf(to_player.x) > 4:
		_set_facing(1 if to_player.x > 0 else -1)

	if _can_see_player():
		_lost_time = 0.0
	else:
		_lost_time += delta
		if _lost_time > 2.0:
			_alert.visible = false
			_change_state(State.PATROL)
			return

	if attack_range > 0 and absf(to_player.x) < attack_range and absf(to_player.y) < 30 and _cooldown <= 0:
		_start_attack()
		return

	# Se acerca, pero no se tira por un borde ni se pega al jugador
	if _at_edge() or absf(to_player.x) < 10:
		velocity.x = 0
	else:
		velocity.x = direction * chase_speed * _speed_multiplier()


func _start_attack() -> void:
	_change_state(State.ATTACK)
	sprite.play("attack")
	if attack_sound:
		attack_sound.play()


func _update_animation() -> void:
	if state in [State.DEAD, State.ATTACK]:
		return
	if state == State.HURT:
		if sprite.sprite_frames.has_animation("hit"):
			sprite.play("hit")
		elif sprite.animation != "idle":
			sprite.play("idle")
		return
	var anim := "run" if absf(velocity.x) > 1 else "idle"
	if sprite.animation != anim:
		sprite.play(anim)


# --- Ver al jugador ---

func _player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player")


func _can_see_player() -> bool:
	var player := _player()
	if player == null or player.is_dead:
		return false
	var to_player := player.global_position - global_position
	if absf(to_player.y) > 40:
		return false
	var in_front := signf(to_player.x) == direction
	var reach := sneak_detect_range if player.is_sneaking else detect_range
	if not in_front:
		reach = minf(reach, 24.0) # de espaldas solo lo nota si lo tiene encima
	if absf(to_player.x) > reach:
		return false
	# Las paredes tapan la vista
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -16), player.global_position + Vector2(0, -16), 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _alert_player() -> void:
	_change_state(State.CHASE)
	_lost_time = 0.0
	_alert.visible = true
	var tween := create_tween()
	_alert.position.y = -56
	tween.tween_property(_alert, "position:y", -64.0, 0.15)
	tween.tween_property(_alert, "position:y", -60.0, 0.1)


# --- Recibir daño y morir ---

## Lo llama la espada del jugador
func take_hit(from_position: Vector2) -> void:
	if is_dead:
		return
	health -= 1
	if hit_sound:
		hit_sound.play()
	_flash()
	if health <= 0:
		die()
		return
	var push := signf(global_position.x - from_position.x)
	velocity = Vector2(push * 140, -80)
	_hurt_time = 0.3
	_alert.visible = can_chase
	_set_facing(-int(push) if push != 0 else direction)
	_disable_attack()
	_change_state(State.HURT)


## Lo llama el jugador cuando bloquea un golpe de este enemigo: retrocede sin recibir daño
func blocked(from_position: Vector2) -> void:
	if is_dead:
		return
	velocity = Vector2(signf(global_position.x - from_position.x) * 170, -60)
	_hurt_time = 0.35
	_disable_attack()
	_change_state(State.HURT)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	if randf() < heart_drop_chance:
		_drop_heart.call_deferred()
	_change_state(State.DEAD)
	_alert.visible = false
	_disable_attack()
	contact.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	if death_sound:
		death_sound.play()
	died.emit(self)
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	else:
		await _dissolve()
	if death_sound and death_sound.playing:
		visible = false
		await death_sound.finished
	queue_free()


func _drop_heart() -> void:
	var heart := HEART_SCENE.instantiate()
	heart.position = position + Vector2(0, -12)
	get_parent().add_child(heart)


func _flash() -> void:
	var tween := create_tween()
	sprite.modulate = Color(1, 0.35, 0.35)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


# Se deshace en partículas (para los enemigos que no tienen animación de muerte)
func _dissolve() -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 24
	particles.lifetime = 0.7
	particles.position = Vector2(0, -8)
	particles.direction = Vector2(0, -1)
	particles.spread = 70.0
	particles.gravity = Vector2(0, -20)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, death_color)
	ramp.set_color(1, Color(death_color, 0.0))
	particles.color_ramp = ramp
	add_child(particles)
	particles.emitting = true
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.75).timeout


# --- Ataque ---

func _on_frame_changed() -> void:
	if state != State.ATTACK or attack_area == null:
		return
	attack_area.monitoring = sprite.frame in attack_active_frames


func _on_animation_finished() -> void:
	if state == State.ATTACK:
		_disable_attack()
		_cooldown = attack_cooldown
		_change_state(State.CHASE)


func _disable_attack() -> void:
	if attack_area:
		attack_area.set_deferred("monitoring", false)


# --- Utilidades ---

func _change_state(new_state: State) -> void:
	state = new_state


func _set_facing(new_direction: int) -> void:
	direction = new_direction
	var looking_right := direction > 0
	sprite.flip_h = looking_right != faces_right
	sprite.position.x = sprite_offset_x * direction
	_floor_ray.position.x = (body_half_width + 3) * direction
	if attack_area:
		attack_area.get_node("CollisionShape2D").position.x = _attack_shape_x * direction


func _hits_wall() -> bool:
	return is_on_wall() and signf(get_wall_normal().x) == -direction


func _at_edge() -> bool:
	return is_on_floor() and not _floor_ray.is_colliding()


# ¿Hay piso a esta distancia por delante? (para no saltar a un pozo)
func _floor_ahead(distance: float) -> bool:
	var from := global_position + Vector2(direction * distance, -8)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 48), 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _speed_multiplier() -> float:
	return Settings.enemy_speed_multiplier()
