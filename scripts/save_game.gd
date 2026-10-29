extends Node
## Guarda y lee la partida en user://savegame.json, y lleva las estadísticas de la partida.
## Es un autoload: se accede desde cualquier escena como `SaveGame`.
## Qué se guarda de cada nivel lo decide el nivel (scripts/game.gd).

const SAVE_PATH = "user://savegame.json"

# El menú lo pone en true al tocar "Load"; el nivel lo lee al arrancar
var load_pending := false

# true si en esta partida se cargó o se guardó: al morir se vuelve a ese punto.
# En una partida nueva ("Start") arranca en false, para no volver a un guardado viejo.
var checkpoint_active := false

# true solo al cargar desde el menú: el nivel recupera las estadísticas guardadas.
# Al reintentar después de morir se conservan las de memoria (para no perder las muertes).
var restore_run := false

# Estadísticas de la partida: muertes y tiempo del nivel actual, y totales de los anteriores
var run := {}

# Zonas del mapa ya recorridas: ruta del nivel -> {"x,y": true}
var explored := {}

func _ready() -> void:
	new_run()

func new_run() -> void:
	run = {"deaths": 0, "time": 0.0, "total_deaths": 0, "total_time": 0.0}
	explored = {}

## Al terminar un nivel, suma sus muertes y tiempo a los totales y reinicia los del nivel
func finish_level() -> void:
	run.total_deaths += run.deaths
	run.total_time += run.time
	run.deaths = 0
	run.time = 0.0

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func write(data: Dictionary) -> bool:
	data["run"] = run.duplicate()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

func read() -> Dictionary:
	if not has_save():
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return data if data is Dictionary else {}

static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
