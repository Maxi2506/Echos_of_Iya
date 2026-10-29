extends Node2D
## Script de cada nivel: conecta el jugador con el HUD, la pausa y las pantallas de muerte
## y de fin de nivel, y maneja fogatas, secretos y estadísticas.
##
## Cada fogata guarda una "foto" del nivel: cristales que quedan, enemigos vivos,
## fogatas encendidas y secretos descubiertos. Al morir, el nivel vuelve a esa foto:
## lo que juntaste o mataste antes de la fogata se mantiene, y lo de después vuelve a aparecer.
##
## Cristales, enemigos, fogatas, secretos y la meta se buscan por grupo ("crystals",
## "enemies", "checkpoint", "secrets", "goal"), así que pueden estar en cualquier parte del nivel.

@export var level_number := 1
@export var level_title := "The Valley"
## Escena del nivel siguiente; vacío = es el último nivel
@export_file("*.tscn") var next_level := ""
## Nivel oscuro: se oscurece todo y el jugador lleva una luz
@export var dark := false
@export var dark_color := Color(0.32, 0.3, 0.42)
## Límites de la cámara en píxeles (si el tamaño es 0 no se cambian)
@export var camera_limits := Rect2i()

@onready var player: CharacterBody2D = $Player
@onready var puntaje: Node = %Puntaje
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var level_complete: CanvasLayer = $LevelComplete
@onready var map_screen: CanvasLayer = $MapScreen

# Ruta (dentro del nivel) de la fogata donde se reaparece
var current_checkpoint := ""
var total_crystals := 0
var total_enemies := 0
var total_secrets := 0
var _explored: Dictionary

func _ready() -> void:
	# Por si se salió al menú en medio de un efecto de cámara lenta
	Engine.time_scale = 1.0

	# Los totales se cuentan antes de cargar la partida, porque al cargar se borra lo ya hecho
	total_crystals = _in_level("crystals").size()
	total_enemies = _in_level("enemies").size()
	total_secrets = _in_level("secrets").size()
	hud.set_total_crystals(total_crystals)

	_setup_camera()
	if dark:
		var darkness := CanvasModulate.new()
		darkness.color = dark_color
		add_child(darkness)
		player.get_node("Linterna").enabled = true

	if not SaveGame.explored.has(scene_file_path):
		SaveGame.explored[scene_file_path] = {}
	var fresh_start := not SaveGame.load_pending
	if SaveGame.load_pending:
		SaveGame.load_pending = false
		_apply_save(SaveGame.read())

	if fresh_start or current_checkpoint == "":
		hud.show_toast("%s %d: %s" % [tr("Level"), level_number, tr(level_title)])

	puntaje.score_changed.connect(hud.update_score)
	hud.update_score(puntaje.score)
	player.health_changed.connect(hud.update_health)
	hud.update_health(player.health, player.MAX_HEALTH)
	player.died.connect(_on_player_died)
	hud.pause_pressed.connect(pause_menu.open)
	pause_menu.map_requested.connect(map_screen.open)
	_explored = SaveGame.explored[scene_file_path]
	map_screen.setup(self)
	level_complete.continue_pressed.connect(_go_to_next_level)
	for campfire in _in_level("checkpoint"):
		campfire.activated.connect(_on_campfire_activated)
	for secret in _in_level("secrets"):
		secret.found.connect(_on_secret_found)
	for goal in _in_level("goal"):
		goal.reached.connect(_on_goal_reached)

func _process(delta: float) -> void:
	SaveGame.run.time += delta
	_mark_explored()


# --- Mapa: zonas recorridas ---

const MAP_CHUNK := 6

func _chunk_key(cell: Vector2i) -> String:
	return "%d,%d" % [floori(cell.x / float(MAP_CHUNK)), floori(cell.y / float(MAP_CHUNK))]

# Marca como recorridas las zonas que entran en la pantalla alrededor del jugador
func _mark_explored() -> void:
	var cell := Vector2i(((player.global_position - $TileMap.position) / 16.0).floor())
	for dx in range(-2, 3):
		for dy in range(-1, 2):
			_explored[_chunk_key(cell + Vector2i(dx, dy) * MAP_CHUNK)] = true

func is_explored(cell: Vector2i) -> bool:
	return _explored.has(_chunk_key(cell))

func get_campfires() -> Array:
	return _in_level("checkpoint")

func get_secrets() -> Array:
	return _in_level("secrets")

func get_goals() -> Array:
	return _in_level("goal")


# Nodos del grupo que pertenecen a este nivel (y no fueron borrados al cargar)
func _in_level(group: String) -> Array:
	return get_tree().get_nodes_in_group(group).filter(
		func(node): return is_ancestor_of(node) and not node.is_queued_for_deletion())


func _key(node: Node) -> String:
	return String(get_path_to(node))


func _setup_camera() -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null or camera_limits.size == Vector2i.ZERO:
		return
	camera.limit_left = camera_limits.position.x
	camera.limit_top = camera_limits.position.y
	camera.limit_right = camera_limits.end.x
	camera.limit_bottom = camera_limits.end.y


# --- Eventos del nivel ---

func _on_campfire_activated(campfire: Area2D) -> void:
	player.heal_full()
	var is_new_checkpoint := _key(campfire) != current_checkpoint
	current_checkpoint = _key(campfire)
	if SaveGame.write(_build_save()):
		SaveGame.checkpoint_active = true
	if is_new_checkpoint:
		hud.show_toast(tr("Checkpoint"))


func _on_secret_found(_secret: Area2D) -> void:
	hud.show_toast(tr("Secret found!"))


func _on_player_died() -> void:
	SaveGame.run.deaths += 1
	pause_menu.enabled = false
	death_screen.open()


func _on_goal_reached() -> void:
	pause_menu.enabled = false
	player.set_physics_process(false)
	var alive := _in_level("enemies").filter(func(e): return not e.is_dead).size()
	var found := _in_level("secrets").filter(func(s): return s.is_found).size()
	var stats := [
		[tr("Crystals"), "%d/%d" % [puntaje.score, total_crystals]],
		[tr("Secrets"), "%d/%d" % [found, total_secrets]],
		[tr("Enemies defeated"), "%d/%d" % [total_enemies - alive, total_enemies]],
		[tr("Deaths"), str(SaveGame.run.deaths)],
		[tr("Time"), SaveGame.format_time(SaveGame.run.time)],
	]
	var is_final := next_level == ""
	SaveGame.finish_level()
	if is_final:
		stats.append([tr("Total deaths"), str(SaveGame.run.total_deaths)])
		stats.append([tr("Total time"), SaveGame.format_time(SaveGame.run.total_time)])
	var title := tr("The Echo has awakened") if is_final else tr("Level complete!")
	level_complete.open(title, stats, is_final)


func _go_to_next_level() -> void:
	# Se guarda el comienzo del nivel siguiente, así "Cargar" retoma desde ahí
	SaveGame.write({"level": next_level})
	SaveGame.checkpoint_active = true
	SaveGame.load_pending = false
	get_tree().change_scene_to_file(next_level)


# --- Guardar y cargar la "foto" del nivel ---

func _build_save() -> Dictionary:
	return {
		"level": scene_file_path,
		"checkpoint": current_checkpoint,
		"lit_campfires": _in_level("checkpoint").filter(func(c): return c.lit).map(_key),
		"score": puntaje.score,
		"crystals": _in_level("crystals").filter(func(c): return not c.collected).map(_key),
		"enemies": _in_level("enemies").filter(func(e): return not e.is_dead).map(_key),
		"secrets": _in_level("secrets").filter(func(s): return s.is_found).map(_key),
		"explored": SaveGame.explored.get(scene_file_path, {}).keys(),
	}


func _apply_save(data: Dictionary) -> void:
	if data.is_empty() or data.get("level", scene_file_path) != scene_file_path:
		return
	if SaveGame.restore_run and data.has("run"):
		SaveGame.run.merge(data.run, true)
		var explored := {}
		for key in data.get("explored", []):
			explored[key] = true
		SaveGame.explored[scene_file_path] = explored
	SaveGame.restore_run = false
	if not data.has("crystals"):
		return # comienzo de nivel: no hay foto todavía

	puntaje.score = int(data.get("score", 0))

	var remaining_crystals: Array = data.get("crystals", [])
	for crystal in _in_level("crystals"):
		if _key(crystal) not in remaining_crystals:
			crystal.queue_free()

	var alive_enemies: Array = data.get("enemies", [])
	for enemy in _in_level("enemies"):
		if _key(enemy) not in alive_enemies:
			enemy.queue_free()

	var lit_campfires: Array = data.get("lit_campfires", [])
	for campfire in _in_level("checkpoint"):
		if _key(campfire) in lit_campfires:
			campfire.set_lit(true)

	var found_secrets: Array = data.get("secrets", [])
	for secret in _in_level("secrets"):
		if _key(secret) in found_secrets:
			secret.set_found(true, false)

	current_checkpoint = data.get("checkpoint", "")
	var checkpoint := get_node_or_null(current_checkpoint)
	if checkpoint:
		player.global_position = checkpoint.respawn_position()
