extends Node2D
## Script del nivel: conecta el jugador con el HUD, la pausa y la pantalla de muerte,
## y maneja las fogatas (puntos de control).
##
## Cada fogata guarda una "foto" del nivel: cristales que quedan, enemigos vivos y
## fogatas encendidas. Al morir, el nivel vuelve a esa foto: lo que juntaste o mataste
## antes de la fogata se mantiene, y lo de después vuelve a aparecer.

@onready var player: CharacterBody2D = $Player
@onready var puntaje: Node = %Puntaje
@onready var crystals: Node = $Cristal
@onready var enemies: Node = $Yokai_Knight
@onready var campfires: Node = $Hoguera
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var death_screen: CanvasLayer = $DeathScreen

# Nombre de la fogata donde se reaparece
var current_checkpoint := ""

func _ready() -> void:
	# Por si se salió al menú en medio de un efecto de cámara lenta
	Engine.time_scale = 1.0

	# El total se cuenta antes de cargar la partida, porque al cargar se borran los ya juntados
	hud.set_total_crystals(crystals.get_child_count())

	if SaveGame.load_pending:
		SaveGame.load_pending = false
		_apply_save(SaveGame.read())

	puntaje.score_changed.connect(hud.update_score)
	hud.update_score(puntaje.score)
	player.health_changed.connect(hud.update_health)
	hud.update_health(player.health, player.MAX_HEALTH)
	player.died.connect(_on_player_died)
	hud.pause_pressed.connect(pause_menu.open)
	for campfire in campfires.get_children():
		campfire.activated.connect(_on_campfire_activated)


func _on_campfire_activated(campfire: Area2D) -> void:
	player.heal_full()
	var is_new_checkpoint := String(campfire.name) != current_checkpoint
	current_checkpoint = String(campfire.name)
	if SaveGame.write(_build_save()):
		SaveGame.checkpoint_active = true
	if is_new_checkpoint:
		hud.show_toast(tr("Checkpoint"))


func _on_player_died() -> void:
	pause_menu.enabled = false
	death_screen.open()


func _build_save() -> Dictionary:
	var remaining_crystals := []
	for crystal in crystals.get_children():
		if not crystal.collected:
			remaining_crystals.append(String(crystal.name))

	var alive_enemies := []
	for enemy in enemies.get_children():
		if not enemy.muerto:
			alive_enemies.append(String(enemy.name))

	var lit_campfires := []
	for campfire in campfires.get_children():
		if campfire.lit:
			lit_campfires.append(String(campfire.name))

	return {
		"level": scene_file_path,
		"checkpoint": current_checkpoint,
		"lit_campfires": lit_campfires,
		"score": puntaje.score,
		"crystals": remaining_crystals,
		"enemies": alive_enemies,
	}


func _apply_save(data: Dictionary) -> void:
	if data.is_empty():
		return

	puntaje.score = int(data.get("score", 0))

	var remaining_crystals: Array = data.get("crystals", [])
	for crystal in crystals.get_children():
		if String(crystal.name) not in remaining_crystals:
			crystal.queue_free()

	var alive_enemies = data.get("enemies", [])
	if alive_enemies is Dictionary: # formato de guardado anterior
		alive_enemies = alive_enemies.keys()
	for enemy in enemies.get_children():
		if String(enemy.name) not in alive_enemies:
			enemy.queue_free()

	var lit_campfires: Array = data.get("lit_campfires", [])
	for campfire in campfires.get_children():
		if String(campfire.name) in lit_campfires:
			campfire.set_lit(true)

	current_checkpoint = data.get("checkpoint", "")
	var checkpoint := campfires.get_node_or_null(current_checkpoint)
	if checkpoint:
		player.global_position = checkpoint.respawn_position()
	elif data.has("player"): # formato de guardado anterior
		player.position = Vector2(data.player.x, data.player.y)
