extends SceneTree
## Generador de niveles a partir de mapas de texto (tools/levels/*.txt).
##
## Uso (desde la raíz del proyecto):
##   godot --headless --path . --script tools/level_builder.gd
##   python3 tools/fix_uids.py scenes/levels/level_1.tscn scenes/levels/level_2.tscn
##
## Leyenda de los mapas (cada carácter es una celda de 16x16):
##   .  vacío              #  roca del bosque     B  piedra del castillo   =  puente de madera
##   F  pared falsa de castillo (zona secreta)    f  pared falsa de roca (zona secreta)
##   P  inicio del jugador c  cristal             H  fogata (punto de control)
##   G  meta               K  caballero           X  kitsune   s  serpiente   r  rana
##   M  plataforma móvil horizontal               V  plataforma móvil vertical
##   l  velas (en el piso) L  farol colgante (del techo)  h  corazón (recupera 1 de vida)
## Las fichas que se paran en el piso (P, H, G, enemigos, l) van en la celda de arriba del piso.

const TILESET_PATH := "res://tilesets/world.tres"
const LEVEL_1 := "res://scenes/levels/level_1.tscn"
const LEVEL_2 := "res://scenes/levels/level_2.tscn"
const LEVELS_DIR := "tools/levels/"

const SCENES := {
	"c": "res://scenes/cristal.tscn",
	"H": "res://scenes/hoguera.tscn",
	"K": "res://scenes/enemies/knight.tscn",
	"X": "res://scenes/enemies/kitsune.tscn",
	"s": "res://scenes/enemies/snake.tscn",
	"r": "res://scenes/enemies/frog.tscn",
	"M": "res://scenes/level/moving_platform.tscn",
	"V": "res://scenes/level/moving_platform.tscn",
	"l": "res://scenes/velas.tscn",
	"L": "res://scenes/velas_techo.tscn",
	"h": "res://scenes/level/heart_pickup.tscn",
}
const ENEMY_NAMES := {"K": "caballero", "X": "kitsune", "s": "serpiente", "r": "rana"}

# Tiles de cada material: [fuente, coordenadas en el atlas]
const FOREST := 3
const CASTLE := 4
const BRIDGE := 2
const WALLS := 1

var tileset: TileSet
var rng := RandomNumberGenerator.new()
var _counters := {}


func _initialize() -> void:
	rng.seed = 20261029
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tilesets"))
	tileset = _get_tileset()
	build_level_1()
	build_level_2()
	print("Niveles generados.")
	quit()


# El TileSet vivía dentro de la escena del nivel 1; se guarda aparte para compartirlo.
func _get_tileset() -> TileSet:
	if not ResourceLoader.exists(TILESET_PATH):
		var level: Node = load(LEVEL_1).instantiate()
		var ts: TileSet = level.get_node("TileMap/Mid").tile_set
		ResourceSaver.save(ts, TILESET_PATH)
		level.free()
	return load(TILESET_PATH)


# ------------------------------------------------------------------ mapas de texto

func _read_map(file: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://") + LEVELS_DIR + file)
	var origin := Vector2i.ZERO
	var rows: Array[String] = []
	for line in text.split("\n"):
		if line.begins_with(";") or line.strip_edges() == "":
			continue
		if line.begins_with("@origin"):
			var parts := line.split(" ", false)
			origin = Vector2i(int(parts[1]), int(parts[2]))
			continue
		rows.append(line)
	return {"origin": origin, "rows": rows}


static func _char(rows: Array[String], x: int, y: int) -> String:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return "."
	return rows[y][x]


static func _solid(rows: Array[String], x: int, y: int) -> bool:
	return _char(rows, x, y) in ["#", "B", "F", "f"]


func _pick(xs: Array, y: int) -> Vector2i:
	return Vector2i(xs[rng.randi_range(0, xs.size() - 1)], y)


## Elige el tile según el material y qué vecinos son sólidos (un "autotile" simple)
func _tile_for(rows: Array[String], x: int, y: int) -> Array:
	var ch := _char(rows, x, y)
	var n := _solid(rows, x, y - 1)
	var s := _solid(rows, x, y + 1)
	var w := _solid(rows, x - 1, y)
	var e := _solid(rows, x + 1, y)
	if ch in ["#", "f"]:
		if not n:
			if not w: return [FOREST, Vector2i(56, 33)]
			if not e: return [FOREST, Vector2i(71, 33)]
			return [FOREST, _pick(range(58, 70), 33)]
		if not s:
			if not w: return [FOREST, Vector2i(56, 50)]
			if not e: return [FOREST, Vector2i(71, 50)]
			return [FOREST, _pick(range(58, 70), 50)]
		if not w: return [FOREST, Vector2i(52, rng.randi_range(41, 44))]
		if not e: return [FOREST, Vector2i(76, rng.randi_range(41, 44))]
		return [FOREST, _pick(range(58, 69), 34)]
	if ch in ["B", "F"]:
		if not n:
			if not w: return [CASTLE, Vector2i(13, 45)]
			if not e: return [CASTLE, Vector2i(30, 45)]
			return [CASTLE, _pick(range(16, 29), 45)]
		if not w: return [CASTLE, Vector2i(13, 46)]
		if not e: return [CASTLE, Vector2i(30, 46)]
		return [CASTLE, _pick(range(17, 25), 46)]
	if ch == "=":
		return [BRIDGE, _pick(range(4, 9), 15)]
	return []


## Pinta el mapa en las capas. Devuelve las celdas de pared falsa agrupadas por zona.
func _paint(rows: Array[String], origin: Vector2i, terrain: TileMapLayer, decor: TileMapLayer) -> Array:
	var fake_cells := []
	for y in rows.size():
		for x in rows[y].length():
			var ch := rows[y][x]
			var cell := origin + Vector2i(x, y)
			if ch in ["F", "f"]:
				fake_cells.append(Vector2i(x, y))
				continue
			var t := _tile_for(rows, x, y)
			if t.is_empty():
				continue
			terrain.set_cell(cell, t[0], t[1])
			# pasto decorativo sobre la roca del bosque
			if ch == "#" and not _solid(rows, x, y - 1) and _solid(rows, x - 1, y) and _solid(rows, x + 1, y):
				decor.set_cell(cell + Vector2i(0, -1), FOREST, _pick([59, 60, 61, 63, 64, 65, 66, 67, 68], 32))
	return _group_cells(fake_cells)


static func _group_cells(cells: Array) -> Array:
	var left := {}
	for c in cells:
		left[c] = true
	var groups := []
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		var group := []
		var stack := [start]
		left.erase(start)
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			group.append(c)
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if left.has(c + d):
					left.erase(c + d)
					stack.append(c + d)
		groups.append(group)
	return groups


# ------------------------------------------------------------------ fichas (entidades)

## Desplazamiento real de una capa dentro del nivel (la capa puede estar dentro del nodo "TileMap",
## que en el nivel 1 está corrido a (-13, 11))
static func _offset(layer: Node2D) -> Vector2:
	var parent := layer.get_parent()
	return layer.position + (parent.position if parent is Node2D and parent.get_parent() != null else Vector2.ZERO)


func _cell_to_world(layer: Node2D, cell: Vector2i, anchor: Vector2) -> Vector2:
	return _offset(layer) + Vector2(cell * 16) + anchor


# ------------------------------------------------------------------ apoyar las fichas en el piso

var _solid_cells := {}
var _solid_offset := Vector2.ZERO

## Junta las celdas con colisión de todas las capas del nivel
func _collect_solids(tilemap: Node2D) -> void:
	_solid_cells.clear()
	for layer in tilemap.get_children():
		if layer is TileMapLayer and layer.collision_enabled:
			_solid_offset = _offset(layer)
			for c in layer.get_used_cells():
				var data: TileData = layer.get_cell_tile_data(c)
				if data and data.get_collision_polygons_count(0) > 0:
					_solid_cells[c] = true


func _cell_at(world: Vector2) -> Vector2i:
	return Vector2i(((world - _solid_offset) / 16.0).floor())


## Pies sobre el piso: si quedó dentro de una pared sube, si quedó en el aire baja
func _snap_to_floor(feet: Vector2, label: String) -> Vector2:
	var cell := _cell_at(feet - Vector2(0, 1))
	var steps := 0
	while _solid_cells.has(cell) and steps < 12:
		cell.y -= 1
		steps += 1
	while not _solid_cells.has(cell + Vector2i.DOWN) and steps < 40:
		cell.y += 1
		steps += 1
	if steps >= 40:
		push_warning("%s: no encontré piso debajo" % label)
		return feet
	return Vector2(feet.x, _solid_offset.y + (cell.y + 1) * 16)


## Cristales: si quedaron dentro de una pared, suben hasta el primer hueco libre
func _snap_out_of_wall(center: Vector2) -> Vector2:
	var cell := _cell_at(center)
	var moved := false
	while _solid_cells.has(cell):
		cell.y -= 1
		moved = true
	return Vector2(center.x, _solid_offset.y + cell.y * 16 + 10) if moved else center


func _snap_all(root: Node, tilemap: Node2D) -> void:
	_collect_solids(tilemap)
	for node in root.find_children("*", "", true, false):
		var scene: String = node.scene_file_path
		if scene.ends_with("cristal.tscn"):
			node.position = _snap_out_of_wall(node.position)
		elif scene.ends_with("hoguera.tscn"):
			node.position = _snap_to_floor(node.position + Vector2(0, 8), node.name) - Vector2(0, 8)
		elif scene.ends_with("velas.tscn"):
			node.position = _snap_to_floor(node.position + Vector2(0, 8), node.name) - Vector2(0, 8)
		elif scene.contains("/enemies/") or scene.contains("goal_") or scene.ends_with("heart_pickup.tscn"):
			node.position = _snap_to_floor(node.position, node.name)
	_assign_difficulty(root)


## La dificultad es la cantidad de enemigos: recorriendo el nivel de izquierda a derecha,
## de cada 4 enemigos 2 aparecen siempre, 1 desde normal y 1 solo en difícil.
func _assign_difficulty(root: Node) -> void:
	var enemies := root.find_children("*", "", true, false).filter(
		func(n): return n.scene_file_path.contains("/enemies/"))
	enemies.sort_custom(func(a, b): return a.position.x < b.position.x)
	var pattern := [0, 1, 0, 2]
	for i in enemies.size():
		enemies[i].set("min_difficulty", pattern[i % pattern.size()])


func _add(parent: Node, scene_path: String, name_prefix: String, position: Vector2, owner: Node) -> Node:
	var node: Node = load(scene_path).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_counters[name_prefix] = _counters.get(name_prefix, 0) + 1
	node.name = "%s_%02d" % [name_prefix, _counters[name_prefix]]
	node.position = position
	parent.add_child(node)
	node.owner = owner
	return node


## Ubica las fichas del mapa. Devuelve la posición del jugador si hay una "P".
func _place_entities(rows: Array[String], origin: Vector2i, terrain: TileMapLayer, root: Node,
		goal_scene: String) -> Variant:
	var groups := {
		"crystals": _container(root, "Cristales"),
		"enemies": _container(root, "Enemigos"),
		"campfires": _container(root, "Fogatas"),
		"props": _container(root, "Decoracion"),
		"platforms": _container(root, "Plataformas"),
	}
	var player_pos = null
	for y in rows.size():
		for x in rows[y].length():
			var ch := rows[y][x]
			var cell := origin + Vector2i(x, y)
			var feet := _cell_to_world(terrain, cell, Vector2(8, 16))
			match ch:
				"P":
					player_pos = feet
				"c":
					_add(groups.crystals, SCENES.c, "cristal", _cell_to_world(terrain, cell, Vector2(8, 10)), root)
				"h":
					_add(_container(root, "Corazones"), SCENES.h, "corazon", feet, root)
				"H":
					_add(groups.campfires, SCENES.H, "fogata", feet + Vector2(0, -8), root)
				"G":
					_add(root, goal_scene, "meta", feet, root)
				"K", "X", "s", "r":
					_add(groups.enemies, SCENES[ch], ENEMY_NAMES[ch], feet, root)
				"M":
					var p := _add(groups.platforms, SCENES.M, "plataforma", _cell_to_world(terrain, cell, Vector2(32, 8)), root)
					p.set("travel", Vector2(64, 0))
				"V":
					var p := _add(groups.platforms, SCENES.V, "plataforma", _cell_to_world(terrain, cell, Vector2(32, 8)), root)
					p.set("travel", Vector2(0, -96))
					p.set("duration", 2.5)
				"l":
					_add(groups.props, SCENES.l, "velas", _cell_to_world(terrain, cell, Vector2(8, 8)), root)
				"L":
					_add(groups.props, SCENES.L, "farol", _cell_to_world(terrain, cell, Vector2(8, 16)), root)
	return player_pos


func _container(root: Node, container_name: String) -> Node:
	var node := root.get_node_or_null(container_name)
	if node == null:
		node = Node2D.new()
		node.name = container_name
		root.add_child(node)
		node.owner = root
	return node


## Tiles falsos de un grupo del mapa de texto: la pared falsa y la sala que esconde detrás
## (las celdas vacías encerradas a las que solo se llega por la pared falsa).
func _secret_tiles(rows: Array[String], origin: Vector2i, cells: Array) -> Dictionary:
	var tiles := {}
	var fill_forest := false
	for c in cells:
		tiles[origin + c] = _tile_for(rows, c.x, c.y)
		fill_forest = fill_forest or _char(rows, c.x, c.y) == "f"
	for c in cells:
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var room := _flood_room(rows, c + d, 60)
			for r in room:
				if not tiles.has(origin + r):
					tiles[origin + r] = [FOREST, _pick(range(58, 69), 34)] if fill_forest \
						else [CASTLE, _pick(range(17, 25), 46)]
	return tiles


## Celdas no sólidas conectadas a start; vacío si son más de max_size (es el exterior, no una sala)
func _flood_room(rows: Array[String], start: Vector2i, max_size: int) -> Array:
	if _solid(rows, start.x, start.y) or _char(rows, start.x, start.y) == "=":
		return []
	var seen := {start: true}
	var stack := [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if seen.has(n) or _solid(rows, n.x, n.y) or n.y < 0 or n.y >= rows.size() or n.x < 0:
				continue
			seen[n] = true
			stack.append(n)
			if seen.size() > max_size:
				return []
	return seen.keys()


## Crea una zona secreta: los tiles falsos se ven sólidos pero no tienen colisión.
## tiles: celda (del TileMap) -> [fuente, coordenadas en el atlas]
func _add_secret(tiles_by_cell: Dictionary, terrain: TileMapLayer, root: Node) -> void:
	var area := Area2D.new()
	_counters["secreto"] = _counters.get("secreto", 0) + 1
	area.name = "secreto_%02d" % _counters["secreto"]
	area.collision_layer = 0
	area.collision_mask = 2
	area.set_script(load("res://scripts/level/secret_area.gd"))
	_container(root, "Secretos").add_child(area)
	area.owner = root

	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset
	tiles.collision_enabled = false
	tiles.position = _offset(terrain)
	tiles.z_index = 1
	area.add_child(tiles)
	tiles.owner = root

	var cells: Array = tiles_by_cell.keys()
	var min_c: Vector2i = cells[0]
	var max_c: Vector2i = cells[0]
	for c in cells:
		tiles.set_cell(c, tiles_by_cell[c][0], tiles_by_cell[c][1])
		min_c = Vector2i(mini(min_c.x, c.x), mini(min_c.y, c.y))
		max_c = Vector2i(maxi(max_c.x, c.x), maxi(max_c.y, c.y))

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2((max_c - min_c + Vector2i.ONE) * 16) - Vector2(4, 4)
	shape.shape = rect
	shape.position = _offset(terrain) + Vector2(min_c * 16) + rect.size / 2 + Vector2(2, 2)
	area.add_child(shape)
	shape.owner = root

	var sound := AudioStreamPlayer.new()
	sound.name = "FoundSound"
	sound.stream = load("res://assets/sfx/secret_found.wav")
	sound.bus = &"SFX"
	area.add_child(sound)
	sound.owner = root


# ------------------------------------------------------------------ nivel 1

func build_level_1() -> void:
	_counters.clear()
	var root: Node2D = load(LEVEL_1).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	# Si el nivel ya se generó antes, se borra lo agregado para no duplicarlo
	for child in root.get_children():
		if child.name in ["Cristal", "Yokai_Knight", "Cristales", "Enemigos", "Decoracion", "Plataformas", "Corazones",
				"Secretos", "LevelComplete", "MapScreen"] or String(child.name).begins_with("meta_"):
			root.remove_child(child)
			child.free()
	var old_fire_container := root.get_node_or_null("Fogatas")
	if old_fire_container:
		for fire in old_fire_container.get_children():
			if not fire.name in ["fogata_inicio", "fogata_castillo"]:
				old_fire_container.remove_child(fire)
				fire.free()
	var tilemap: Node2D = root.get_node("TileMap")
	var mid: TileMapLayer = tilemap.get_node("Mid")
	var walls: TileMapLayer = tilemap.get_node("elements")
	for layer in tilemap.get_children():
		layer.tile_set = tileset

	var decor: TileMapLayer = tilemap.get_node_or_null("Decor")
	if decor == null:
		decor = TileMapLayer.new()
		decor.name = "Decor"
		decor.tile_set = tileset
		decor.collision_enabled = false
		tilemap.add_child(decor)
		decor.owner = root
	decor.clear()

	# 1) Grieta de 1 celda en medio de la colina (celdas 48-49): se rellena
	for x in range(47, 51):
		for y in range(0, 12):
			if mid.get_cell_source_id(Vector2i(x, y)) == -1 and y >= 5:
				mid.set_cell(Vector2i(x, y), FOREST, Vector2i(rng.randi_range(58, 68), 34) if y > 5 else Vector2i(rng.randi_range(58, 69), 33))

	# 2) Bloques de piedra en el fondo de los pozos, al ras del borde de la cámara: se quitan
	for x in range(64, 83):
		for y in range(7, 12):
			mid.erase_cell(Vector2i(x, y))
	for layer in tilemap.get_children():
		for c in layer.get_used_cells():
			if c.x >= 161 and c.y >= 7 and c.x <= 200:
				layer.erase_cell(c)

	# 3) Sala secreta debajo del piso del castillo (se cae por un piso falso, x 104-107).
	#    Para salir hay un ascensor (plataforma que sube y baja) justo debajo del piso falso.
	for x in range(101, 111):
		for y in range(6, 9):
			mid.erase_cell(Vector2i(x, y))
	for x in range(101, 111):
		mid.set_cell(Vector2i(x, 9), CASTLE, Vector2i(rng.randi_range(16, 28), 45))
	for x in range(100, 112):
		for y in range(5, 10):
			walls.set_cell(Vector2i(x, y), WALLS, Vector2i(2 + posmod(x, 4), 20 + posmod(y, 5)))
	var chamber := {}
	for x in range(104, 108):
		mid.erase_cell(Vector2i(x, 5))
		chamber[Vector2i(x, 5)] = [CASTLE, Vector2i(rng.randi_range(16, 28), 45)]
	for x in range(101, 111):
		for y in range(6, 9):
			if mid.get_cell_source_id(Vector2i(x, y)) == -1:
				chamber[Vector2i(x, y)] = [CASTLE, Vector2i(rng.randi_range(17, 24), 46)]
	_add_secret(chamber, mid, root)

	# 4) Zona final nueva (a partir de la celda 160)
	var ext := _read_map("level1_ext.txt")
	for layer in tilemap.get_children():
		for c in layer.get_used_cells():
			if c.x >= ext.origin.x + 2 and c.x < ext.origin.x + 110:
				layer.erase_cell(c)
	var secrets := _paint(ext.rows, ext.origin, mid, decor)
	for group in secrets:
		_add_secret(_secret_tiles(ext.rows, ext.origin, group), mid, root)

	# 5) Fichas: se reemplazan las viejas por las del diseño nuevo
	var crystals := _container(root, "Cristales")
	var enemies := _container(root, "Enemigos")
	var props := _container(root, "Decoracion")
	# zonas 1 a 4 (mapa original). Posiciones en píxeles; después se apoyan solas en el piso.
	var classic := [
		# cristales que ya tenía el juego (el de (-112,-73) estaba en un hueco donde el
		# personaje no entra: pasa arriba de la cornisa)
		[-100, -165, "c"], [50, -150, "c"], [-134, 60, "c"], [-95, 102, "c"], [501, -19, "c"],
		[682, -26, "c"], [720, 86, "c"], [1097, 22, "c"],
		# cristales nuevos
		[395, -12, "c"], [230, -60, "c"], [895, 0, "c"], [1465, 40, "c"], [1880, 40, "c"], [2330, 20, "c"],
		# sala secreta bajo el castillo
		[1630, 148, "c"], [1683, 118, "c"], [1745, 148, "c"],
		# enemigos
		[320, 110, "s"], [250, -40, "r"], [610, 60, "r"], [868, 43, "K"], [650, -30, "X"],
		[1475, 70, "s"], [1580, 90, "K"], [1770, 90, "K"], [2300, 40, "X"],
		# corazones
		[560, 60, "h"], [1330, 30, "h"], [1855, 80, "h"], [2440, 30, "h"],
	]
	for e in classic:
		var pos := Vector2(e[0], e[1])
		var ch: String = e[2]
		if ch == "c":
			_add(crystals, SCENES.c, "cristal", pos, root)
		elif ch == "h":
			_add(_container(root, "Corazones"), SCENES.h, "corazon", pos, root)
		else:
			_add(enemies, SCENES[ch], ENEMY_NAMES[ch], pos, root)
	_place_entities(ext.rows, ext.origin, mid, root, "res://scenes/level/goal_torii.tscn")
	var elevator := _add(_container(root, "Plataformas"), SCENES.V, "ascensor", _cell_to_world(mid, Vector2i(104, 9), Vector2(32, 5)), root)
	elevator.set("travel", Vector2(0, -80))
	elevator.set("duration", 1.6)
	elevator.set("wait", 1.0)

	# Las fogatas viejas pasan al contenedor "Fogatas"; la del inicio, pegada al jugador
	var old_fires := root.get_node_or_null("Hoguera")
	if old_fires:
		var fires := _container(root, "Fogatas")
		for fire in old_fires.get_children():
			old_fires.remove_child(fire)
			fires.add_child(fire)
			fire.owner = root
			fire.name = "fogata_inicio" if fire.position.x < 500 else "fogata_castillo"
		root.remove_child(old_fires)
		old_fires.free()
	root.get_node("Player").position = Vector2(100, 119)

	# 6) Pantalla de fin de nivel y datos del nivel
	for ui in ["res://scenes/level/level_complete.tscn", "res://scenes/level/map_screen.tscn"]:
		var node: Node = load(ui).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		root.add_child(node)
		node.owner = root
	root.set("level_number", 1)
	root.set("level_title", "The Valley")
	root.set("next_level", LEVEL_2)
	var ext_rows: Array[String] = ext.rows
	var ext_origin: Vector2i = ext.origin
	var right: int = int(_offset(mid).x) + (ext_origin.x + ext_rows[0].length()) * 16
	root.set("camera_limits", Rect2i(-189, -100000, right + 189, 100000 + 161))

	_snap_all(root, tilemap)
	_save(root, LEVEL_1)


# ------------------------------------------------------------------ nivel 2

func build_level_2() -> void:
	_counters.clear()
	var map := _read_map("level2.txt")
	var rows: Array[String] = map.rows
	var size := Vector2i(rows[0].length(), rows.size())

	var root := Node2D.new()
	root.name = "Game"
	root.set_script(load("res://scripts/game.gd"))

	var tilemap := Node2D.new()
	tilemap.name = "TileMap"
	root.add_child(tilemap)
	tilemap.owner = root
	var layers := {}
	for layer_name in ["Fondo", "Terreno", "Decor"]:
		var layer := TileMapLayer.new()
		layer.name = layer_name
		layer.tile_set = tileset
		layer.collision_enabled = layer_name == "Terreno"
		tilemap.add_child(layer)
		layer.owner = root
		layers[layer_name] = layer
	# paredes de fondo en todo el mapa
	for y in size.y:
		for x in size.x:
			layers.Fondo.set_cell(map.origin + Vector2i(x, y), WALLS, Vector2i(2 + posmod(x, 4), 20 + posmod(y, 5)))
	layers.Fondo.modulate = Color(0.55, 0.5, 0.6)

	for group in _paint(rows, map.origin, layers.Terreno, layers.Decor):
		_add_secret(_secret_tiles(rows, map.origin, group), layers.Terreno, root)

	var puntaje := Node.new()
	puntaje.name = "Puntaje"
	puntaje.set_script(load("res://scripts/puntaje.gd"))
	root.add_child(puntaje)
	puntaje.owner = root
	puntaje.unique_name_in_owner = true

	var player: Node2D = load("res://scenes/player.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	player.name = "Player"
	root.add_child(player)
	player.owner = root
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(4, -4)
	camera.zoom = Vector2(4, 4)
	camera.position_smoothing_enabled = true
	camera.limit_smoothed = true
	player.add_child(camera)
	camera.owner = root

	var start = _place_entities(rows, map.origin, layers.Terreno, root, "res://scenes/level/goal_crystal.tscn")
	player.position = start if start != null else Vector2(64, 64)

	for ui in ["res://scenes/hud.tscn", "res://scenes/pause_menu.tscn", "res://scenes/death_screen.tscn",
			"res://scenes/level/level_complete.tscn", "res://scenes/level/map_screen.tscn"]:
		var node: Node = load(ui).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		root.add_child(node)
		node.owner = root

	root.set("level_number", 2)
	root.set("level_title", "The Ruins")
	root.set("next_level", "")
	root.set("dark", true)
	root.set("camera_limits", Rect2i(map.origin * 16, size * 16))
	_snap_all(root, tilemap)
	_save(root, LEVEL_2)


func _save(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print(path, ": ", error_string(err))
	root.free()
