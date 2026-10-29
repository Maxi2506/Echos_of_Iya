extends Node2D
## Script del nivel: conecta el puntaje con el HUD, abre la pausa
## y arma o aplica la partida guardada.

@onready var player: CharacterBody2D = $Player
@onready var puntaje: Node = %Puntaje
@onready var crystals: Node = $Cristal
@onready var enemies: Node = $Yokai_Knight
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu

func _ready() -> void:
	# Por si se salió al menú en medio de la cámara lenta de la muerte
	Engine.time_scale = 1.0

	# El total se cuenta antes de cargar la partida, porque al cargar se borran los ya juntados
	hud.set_total_crystals(crystals.get_child_count())

	if SaveGame.load_pending:
		SaveGame.load_pending = false
		_apply_save(SaveGame.read())

	puntaje.score_changed.connect(hud.update_score)
	hud.update_score(puntaje.score)
	hud.pause_pressed.connect(pause_menu.open)
	pause_menu.save_requested.connect(_on_save_requested)


func _on_save_requested() -> void:
	if SaveGame.write(_build_save()):
		SaveGame.checkpoint_active = true
		pause_menu.show_message(tr("Game saved"))
	else:
		pause_menu.show_message(tr("Could not save"))


# Guarda la posición del jugador, el puntaje, los cristales que faltan juntar
# y los enemigos que siguen vivos (con su posición y dirección).
func _build_save() -> Dictionary:
	var remaining_crystals := []
	for crystal in crystals.get_children():
		if not crystal.collected:
			remaining_crystals.append(String(crystal.name))

	var alive_enemies := {}
	for enemy in enemies.get_children():
		if not enemy.muerto:
			alive_enemies[String(enemy.name)] = {
				"x": enemy.position.x,
				"y": enemy.position.y,
				"direction": enemy.direction,
			}

	return {
		"player": {"x": player.position.x, "y": player.position.y},
		"score": puntaje.score,
		"crystals": remaining_crystals,
		"enemies": alive_enemies,
	}


func _apply_save(data: Dictionary) -> void:
	if data.is_empty():
		return

	var player_data: Dictionary = data.get("player", {})
	player.position = Vector2(player_data.get("x", player.position.x), player_data.get("y", player.position.y))
	puntaje.score = int(data.get("score", 0))

	var remaining_crystals: Array = data.get("crystals", [])
	for crystal in crystals.get_children():
		if String(crystal.name) not in remaining_crystals:
			crystal.queue_free()

	var alive_enemies: Dictionary = data.get("enemies", {})
	for enemy in enemies.get_children():
		var enemy_data = alive_enemies.get(String(enemy.name))
		if enemy_data == null:
			enemy.queue_free()
		else:
			enemy.position = Vector2(enemy_data.x, enemy_data.y)
			enemy.direction = int(enemy_data.direction)
