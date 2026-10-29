extends Node2D
## Script de cada nivel: conecta el jugador con el HUD, la pausa y la pantalla de muerte,
## y maneja las fogatas (puntos de control).
##
## Cada fogata guarda una "foto" del nivel: cristales que quedan, enemigos vivos y
## fogatas encendidas. Al morir, el nivel vuelve a esa foto: lo que juntaste o mataste
## antes de la fogata se mantiene, y lo de después vuelve a aparecer.
##
## Los cristales, enemigos y fogatas se buscan por grupo ("crystals", "enemies",
## "checkpoint"), así que pueden estar en cualquier parte del árbol del nivel.

@onready var player: CharacterBody2D = $Player
@onready var puntaje: Node = %Puntaje
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var death_screen: CanvasLayer = $DeathScreen

# Ruta (dentro del nivel) de la fogata donde se reaparece
var current_checkpoint := ""

func _ready() -> void:
	# Por si se salió al menú en medio de un efecto de cámara lenta
	Engine.time_scale = 1.0

	# El total se cuenta antes de cargar la partida, porque al cargar se borran los ya juntados
	hud.set_total_crystals(_in_level("crystals").size())

	if SaveGame.load_pending:
		SaveGame.load_pending = false
		_apply_save(SaveGame.read())

	puntaje.score_changed.connect(hud.update_score)
	hud.update_score(puntaje.score)
	player.health_changed.connect(hud.update_health)
	hud.update_health(player.health, player.MAX_HEALTH)
	player.died.connect(_on_player_died)
	hud.pause_pressed.connect(pause_menu.open)
	for campfire in _in_level("checkpoint"):
		campfire.activated.connect(_on_campfire_activated)


# Nodos del grupo que pertenecen a este nivel (y no fueron borrados al cargar)
func _in_level(group: String) -> Array:
	return get_tree().get_nodes_in_group(group).filter(
		func(node): is_ancestor_of(node) and not node.is_queued_for_deletion())


func _key(node: Node) -> String:
	return String(get_path_to(node))


func _on_campfire_activated(campfire: Area2D) -> void:
	player.heal_full()
	var is_new_checkpoint := _key(campfire) != current_checkpoint
	current_checkpoint = _key(campfire)
	if SaveGame.write(_build_save()):
		SaveGame.checkpoint_active = true
	if is_new_checkpoint:
		hud.show_toast(tr("Checkpoint"))


func _on_player_died() -> void:
	pause_menu.enabled = false
	death_screen.open()


func _build_save() -> Dictionary:
	return {
		"level": scene_file_path,
		"checkpoint": current_checkpoint,
		"lit_campfires": _in_level("checkpoint").filter(func(c): return c.lit).map(_key),
		"score": puntaje.score,
		"crystals": _in_level("crystals").filter(func(c): return not c.collected).map(_key),
		"enemies": _in_level("enemies").filter(func(e): return not e.is_dead).map(_key),
	}


func _apply_save(data: Dictionary) -> void:
	if data.is_empty() or data.get("level", scene_file_path) != scene_file_path:
		return

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

	current_checkpoint = data.get("checkpoint", "")
	var checkpoint := get_node_or_null(current_checkpoint)
	if checkpoint:
		player.global_position = checkpoint.respawn_position()
