extends Node
## Guarda y lee la partida en user://savegame.json.
## Es un autoload: se accede desde cualquier escena como `SaveGame`.
## Qué se guarda lo decide el nivel (scripts/game.gd); acá solo se escribe y se lee el archivo.

const SAVE_PATH = "user://savegame.json"

# El menú lo pone en true al tocar "Load"; el nivel lo lee al arrancar
var load_pending := false

# true si en esta partida se cargó o se guardó: al morir se vuelve a ese punto.
# En una partida nueva ("Start") arranca en false, para no volver a un guardado viejo.
var checkpoint_active := false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func write(data: Dictionary) -> bool:
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
