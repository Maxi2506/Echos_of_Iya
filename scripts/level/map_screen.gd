extends CanvasLayer
## Pantalla de mapa (tecla M, botón Select del joystick o desde la pausa).
## Dibuja el terreno del nivel a partir de los tiles con colisión, tapando con "niebla"
## las zonas que el jugador todavía no recorrió. Marca jugador, fogatas, meta y secretos.

const CHUNK := 6 # tamaño (en celdas) de cada zona que se descubre de a una
const COLOR_TERRAIN := Color(0.78, 0.72, 0.66)
const COLOR_BG := Color(0.05, 0.04, 0.09, 0.92)
const COLOR_PLAYER := Color(0.4, 0.95, 1.0)
const COLOR_FIRE := Color(1.0, 0.6, 0.2)
const COLOR_GOAL := Color(1.0, 0.85, 0.3)
const COLOR_SECRET := Color(0.85, 0.45, 1.0)

@onready var canvas: Control = $Canvas
@onready var title_label: Label = $Title
@onready var hint_label: Label = $Hint

var level: Node2D
var _cells: Array[Vector2i] = []
var _bounds := Rect2i()
var _blink := 0.0

func _ready() -> void:
	hide()
	canvas.draw.connect(_draw_map)
	for entry in [[COLOR_PLAYER, "You"], [COLOR_FIRE, "Campfire"], [COLOR_GOAL, "Goal"], [COLOR_SECRET, "Secret"]]:
		var swatch := ColorRect.new()
		swatch.color = entry[0]
		swatch.custom_minimum_size = Vector2(14, 14)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		$Legend.add_child(swatch)
		var label := Label.new()
		label.text = entry[1]
		label.add_theme_font_size_override("font_size", 20)
		$Legend.add_child(label)

func setup(level_node: Node2D) -> void:
	level = level_node
	_cells.clear()
	for layer in level.get_node("TileMap").get_children():
		if layer is TileMapLayer and layer.collision_enabled:
			_cells.append_array(layer.get_used_cells())
	if _cells.is_empty():
		return
	_bounds = Rect2i(_cells[0], Vector2i.ONE)
	for c in _cells:
		_bounds = _bounds.expand(c).expand(c + Vector2i.ONE)

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("map") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()
	elif not visible and event.is_action_pressed("map") and not get_tree().paused:
		open()
		get_viewport().set_input_as_handled()

func open() -> void:
	if level == null or _cells.is_empty():
		return
	title_label.text = "%s — %s %d: %s" % [tr("Map"), tr("Level"), level.level_number, tr(level.level_title)]
	hint_label.text = tr("M or Esc to close")
	show()
	get_tree().paused = true
	canvas.queue_redraw()

func close() -> void:
	hide()
	get_tree().paused = false

func _process(delta: float) -> void:
	if visible:
		_blink += delta
		canvas.queue_redraw()

# --- Dibujo ---

func _draw_map() -> void:
	var area := canvas.get_rect().size
	canvas.draw_rect(Rect2(Vector2.ZERO, area), COLOR_BG)
	var scale := minf(area.x / _bounds.size.x, area.y / _bounds.size.y)
	var offset := (area - Vector2(_bounds.size) * scale) / 2
	var tilemap: Node2D = level.get_node("TileMap")

	var to_map := func(world: Vector2) -> Vector2:
		var cell := (world - tilemap.position) / 16.0
		return offset + (cell - Vector2(_bounds.position)) * scale

	for c in _cells:
		if level.is_explored(c):
			canvas.draw_rect(Rect2(offset + Vector2(c - _bounds.position) * scale, Vector2.ONE * scale), COLOR_TERRAIN)

	for fire in level.get_campfires():
		if fire.lit:
			_draw_marker(to_map.call(fire.global_position), COLOR_FIRE, 4.0)
	for secret in level.get_secrets():
		if secret.is_found:
			_draw_marker(to_map.call(secret.get_node("CollisionShape2D").global_position), COLOR_SECRET, 4.0)
	for goal in level.get_goals():
		if level.is_explored(Vector2i(((goal.global_position - tilemap.position) / 16.0).floor())):
			_draw_marker(to_map.call(goal.global_position), COLOR_GOAL, 6.0)
	var player_pos: Vector2 = to_map.call(level.player.global_position)
	var pulse := 4.0 + sin(_blink * 6.0) * 1.5
	canvas.draw_circle(player_pos, pulse + 2, Color.BLACK)
	canvas.draw_circle(player_pos, pulse, COLOR_PLAYER)

func _draw_marker(pos: Vector2, color: Color, size: float) -> void:
	canvas.draw_rect(Rect2(pos - Vector2.ONE * (size + 1), Vector2.ONE * (size + 1) * 2), Color.BLACK)
	canvas.draw_rect(Rect2(pos - Vector2.ONE * size, Vector2.ONE * size * 2), color)
