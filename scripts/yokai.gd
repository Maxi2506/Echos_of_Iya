extends Node2D

const speed = 60
var direction = 1

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@onready var rey_cast_right = $RayCastRight
@onready var rey_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta):
	if rey_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if rey_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	position.x += direction * speed * delta
	
	# 3. Animaciones
	if direction == 0:
		animated_sprite_2d.play("idle")
	else:
		animated_sprite_2d.play("run")
