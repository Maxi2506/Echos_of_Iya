extends Node
## Opciones del juego (volumen, dificultad e idioma).
## Es un autoload: se accede desde cualquier escena como `Settings`.
## Las opciones se guardan en user://settings.cfg para que no se pierdan al cerrar el juego.

const SETTINGS_PATH = "user://settings.cfg"

const VOLUME_LEVELS = [100, 75, 50, 25, 0]

const DIFFICULTIES = ["easy", "normal", "hard"]
const DIFFICULTY_NAMES = {"easy": "Easy", "normal": "Normal", "hard": "Hard"}
# Multiplicador de la velocidad de los enemigos según la dificultad
const ENEMY_SPEED = {"easy": 0.7, "normal": 1.0, "hard": 1.4}

const LANGUAGES = ["es", "en"]
# Cada idioma se muestra con su propio nombre, así se reconoce aunque no lo entiendas
const LANGUAGE_NAMES = {"es": "Español", "en": "English"}

# Los textos de las escenas están en inglés y se usan como clave de traducción.
const SPANISH = {
	"Start": "Iniciar",
	"Load": "Cargar",
	"Options": "Opciones",
	"Exit": "Salir",
	"Volume": "Volumen",
	"Difficulty": "Dificultad",
	"Language": "Idioma",
	"Back": "Volver",
	"Easy": "Fácil",
	"Normal": "Normal",
	"Hard": "Difícil",
	"Paused": "Pausa",
	"Resume": "Continuar",
	"Main menu": "Menú principal",
	"Checkpoint": "Punto de control",
	"You have fallen": "Has caído",
	"Retry": "Reintentar",
	"Level": "Nivel",
	"The Valley": "El Valle",
	"The Ruins": "Las Ruinas",
	"Secret found!": "¡Secreto encontrado!",
	"Level complete!": "¡Nivel completado!",
	"The Echo has awakened": "El Eco ha despertado",
	"Continue": "Continuar",
	"Secrets": "Secretos",
	"Enemies defeated": "Enemigos derrotados",
	"Deaths": "Muertes",
	"Time": "Tiempo",
	"Total deaths": "Muertes totales",
	"Total time": "Tiempo total",
	"Crystals": "Cristales",
	"Controls": "Controles",
	"Move": "Moverse",
	"Jump": "Saltar",
	"Attack": "Atacar",
	"Walk (stealth)": "Caminar (sigilo)",
	"Stealth": "Sigilo",
	"Pause": "Pausa",
	"Space": "Espacio",
}

var volume: int = 100
var difficulty: String = "normal"
var language: String = "en"


func _ready() -> void:
	var spanish := Translation.new()
	spanish.locale = "es"
	for key in SPANISH:
		spanish.add_message(key, SPANISH[key])
	TranslationServer.add_translation(spanish)

	# Primera vez: usa el idioma del sistema operativo si es español
	language = "es" if OS.get_locale_language() == "es" else "en"
	_load()
	_apply()


func next_volume() -> void:
	volume = _next(VOLUME_LEVELS, volume)
	_apply_and_save()


func next_difficulty() -> void:
	difficulty = _next(DIFFICULTIES, difficulty)
	_apply_and_save()


func next_language() -> void:
	language = _next(LANGUAGES, language)
	_apply_and_save()


func enemy_speed_multiplier() -> float:
	return ENEMY_SPEED[difficulty]


func difficulty_name() -> String:
	return tr(DIFFICULTY_NAMES[difficulty])


func language_name() -> String:
	return LANGUAGE_NAMES[language]


# Devuelve el elemento siguiente de la lista (vuelve al principio al final)
func _next(list: Array, current):
	var index := list.find(current)
	return list[(index + 1) % list.size()]


func _apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volume == 0)
	if volume > 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(volume / 100.0))
	TranslationServer.set_locale(language)


func _apply_and_save() -> void:
	_apply()
	var config := ConfigFile.new()
	config.set_value("settings", "volume", volume)
	config.set_value("settings", "difficulty", difficulty)
	config.set_value("settings", "language", language)
	config.save(SETTINGS_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var saved_volume = config.get_value("settings", "volume", volume)
	if saved_volume in VOLUME_LEVELS:
		volume = saved_volume
	var saved_difficulty = config.get_value("settings", "difficulty", difficulty)
	if saved_difficulty in DIFFICULTIES:
		difficulty = saved_difficulty
	var saved_language = config.get_value("settings", "language", language)
	if saved_language in LANGUAGES:
		language = saved_language
