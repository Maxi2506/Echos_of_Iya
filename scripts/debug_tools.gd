extends Node
## HERRAMIENTAS DE PRUEBA (temporal). Solo funcionan al probar desde Godot, no en el juego exportado.
## Para quitarlas: borrar este archivo y la línea "DebugTools" de [autoload] en project.godot.
##
##   F1  Modo dios: volar con las flechas (Shift = más rápido), atravesar paredes, invencible.
##   F2  Ir a la siguiente fogata.
##   F3  Alejar / acercar la cámara.

const FLY_SPEED = 260.0
const FAST_MULTIPLIER = 3.0
const FAR_ZOOM = Vector2(1.5, 1.5)

var god_mode := false
var _label: Label
var _saved_zoom := Vector2(4, 4)
var _saved_limit_bottom := 10000000

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_label = Label.new()
	_label.theme = preload("res://themes/menu_theme.tres")
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_label.position = Vector2(180, 18)
	_label.visible = false
	layer.add_child(_label)

func _player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var player := _player()
	if player == null:
		return
	match event.keycode:
		KEY_F1:
			_set_god_mode(player, not god_mode)
		KEY_F2:
			_go_to_next_campfire(player)
		KEY_F3:
			var camera: Camera2D = player.get_node_or_null("Camera2D")
			if camera:
				camera.zoom = _saved_zoom if camera.zoom == FAR_ZOOM else FAR_ZOOM
		_:
			return
	get_viewport().set_input_as_handled()

func _set_god_mode(player: CharacterBody2D, value: bool) -> void:
	god_mode = value
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if god_mode:
		player.set_physics_process(false)
		player.collision_layer = 0
		player.collision_mask = 0
		player.velocity = Vector2.ZERO
		if camera:
			_saved_zoom = camera.zoom if camera.zoom != FAR_ZOOM else _saved_zoom
			_saved_limit_bottom = camera.limit_bottom
			camera.limit_bottom = 10000000 # para poder mirar debajo del mapa
	else:
		player.set_physics_process(true)
		player.collision_layer = 2
		player.collision_mask = 1
		if camera:
			camera.limit_bottom = _saved_limit_bottom
	_label.visible = god_mode
	_label.text = "MODO DIOS (F1)   F2: fogata   F3: zoom"

func _physics_process(delta: float) -> void:
	if not god_mode:
		return
	var player := _player()
	if player == null: # cambió la escena
		god_mode = false
		_label.visible = false
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var speed := FLY_SPEED * (FAST_MULTIPLIER if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	player.global_position += direction * speed * delta
	_label.text = "MODO DIOS (F1)   F2: fogata   F3: zoom   x=%d y=%d" % [player.global_position.x, player.global_position.y]

func _go_to_next_campfire(player: CharacterBody2D) -> void:
	var fires := get_tree().get_nodes_in_group("checkpoint")
	if fires.is_empty():
		return
	fires.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	var target: Node2D = fires[0]
	for fire in fires:
		if fire.global_position.x > player.global_position.x + 30:
			target = fire
			break
	player.global_position = target.global_position + Vector2(20, -10)
	player.velocity = Vector2.ZERO
