extends Node
## Guardado automático de la partida, en un archivo JSON pequeño (user://save.json, en la carpeta de datos
## del juego). Se guarda al descansar, al subir atributos, al morir y al recoger el morral; se carga al abrir
## el juego (cuando aparece Kael). Qué se guarda: atributos, experiencia, último campamento, el morral,
## las técnicas aprendidas y la historia (acto y narraciones ya oídas).
## Solo actúa en la partida real (la escena principal); las pruebas usan otro archivo con `force_active`.
##
## Guardado seguro (revisión del estudio, 2026-11-09):
## - Se escribe primero en "save.json.tmp" y solo al terminar sustituye al bueno: si el juego se cierra a
##   mitad, el archivo anterior sigue intacto.
## - La partida anterior queda como copia ("save.json.bak"); si la buena está rota, se carga la copia.
## - Cada archivo lleva su versión: los de versiones antiguas se adaptan (`_migrate`) y los de una versión
##   más nueva que el juego no se tocan.
## - Cada dato se comprueba antes de usarlo: un dato raro se ignora en vez de romper la carga.

const VERSION: int = 2

var path: String = "user://save.json"
## Para las pruebas: guardar/cargar aunque no sea la escena principal.
var force_active: bool = false
## Qué pasó en la última lectura: "", "backup" (se usó la copia) o "newer" (archivo de una versión futura).
var last_read_note: String = ""


## ¿Es la partida real (o una prueba que lo pide)?
func active() -> bool:
	if force_active:
		return true
	var scene: Node = get_tree().current_scene
	return scene != null and scene.scene_file_path == ProjectSettings.get_setting("application/run/main_scene", "")


func exists() -> bool:
	return FileAccess.file_exists(path)


func backup_path() -> String:
	return path + ".bak"


func _temp_path() -> String:
	return path + ".tmp"


## Borra la partida, su copia y cualquier resto a medio escribir ("Empezar de nuevo").
func erase() -> void:
	for p: String in [path, backup_path(), _temp_path()]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


## Guarda el estado actual del jugador (si es la partida real).
func save(player: Player) -> void:
	if not active() or player == null:
		return
	var data: Dictionary = {
		"version": VERSION,
		"level": level_id(),
		"xp": player.xp,
		"attributes": player.attributes.to_dict(),
		"spawn": _vec(player.spawn_position()) + [player.start_facing_degrees],
		"story": Story.to_dict(),
		"key_items": player.key_items.map(func(id: StringName) -> String: return String(id)),
		"arts": player.arts.unlocked.map(func(id: StringName) -> String: return String(id)),
		"art_equipped": String(player.arts.equipped),
	}
	for node in get_tree().get_nodes_in_group("xp_satchels"):
		var bag := node as XpSatchel
		if bag and not bag.is_queued_for_deletion():
			data["satchel"] = {"at": _vec(bag.global_position), "amount": bag.amount}
	write_safely(JSON.stringify(data, "\t"))


## Escribe el texto en el archivo temporal y, si todo fue bien, lo pone en lugar del bueno
## (el bueno anterior pasa a ser la copia).
func write_safely(text: String) -> bool:
	var tmp: String = _temp_path()
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la partida en %s" % tmp)
		return false
	file.store_string(text)
	file.close()
	# Comprobar que lo escrito se puede leer antes de sustituir nada.
	if _parse(FileAccess.get_file_as_string(tmp)).is_empty():
		push_warning("La partida recién escrita no se puede leer: se conserva la anterior.")
		return false
	var dir_path: String = ProjectSettings.globalize_path(path)
	var bak: String = ProjectSettings.globalize_path(backup_path())
	if FileAccess.file_exists(path):
		# La partida actual solo pasa a ser la copia si se puede leer (no se pisa una copia buena con una rota).
		if not _parse(FileAccess.get_file_as_string(path)).is_empty():
			if FileAccess.file_exists(backup_path()):
				DirAccess.remove_absolute(bak)
			DirAccess.rename_absolute(dir_path, bak)
		else:
			DirAccess.remove_absolute(dir_path)
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), dir_path) != OK:
		push_warning("No se pudo sustituir la partida por la nueva (%s)" % path)
		return false
	return true


## Lee la partida; si está rota, la copia; si las dos faltan o están rotas, un diccionario vacío.
## Devuelve los datos ya adaptados a la versión actual.
func read() -> Dictionary:
	last_read_note = ""
	var data: Dictionary = {}
	if exists():
		data = _parse(FileAccess.get_file_as_string(path))
		if data.is_empty():
			push_warning("Partida guardada ilegible (%s): se prueba con la copia." % path)
	if data.is_empty() and FileAccess.file_exists(backup_path()):
		data = _parse(FileAccess.get_file_as_string(backup_path()))
		if not data.is_empty():
			last_read_note = "backup"
	if data.is_empty():
		return {}
	var version: int = int(data.get("version", 1)) if _is_number(data.get("version", 1)) else 1
	if version > VERSION:
		push_warning("La partida es de una versión más nueva del juego (%d > %d): no se carga." % [version, VERSION])
		last_read_note = "newer"
		return {}
	return _migrate(data, version)


## Adapta una partida de una versión antigua a la actual, paso a paso.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 2:
		# v1 guardaba la ruta completa del nivel ("res://scenes/levels/iron_pass.tscn"); v2, solo su nombre.
		data["level"] = _id_from(str(data.get("level", "")))
		# v1 no guardaba las técnicas: se queda con la inicial.
		if not data.has("arts"):
			data["arts"] = [String(PlayerArts.STARTING)]
	data["version"] = VERSION
	return data


## Al aparecer Kael: si hay partida guardada, la carga.
func on_player_ready(player: Player) -> void:
	Squad.reset()
	Story.reset()
	if not active():
		return
	var data: Dictionary = read()
	if data.is_empty():
		return
	# Una partida de otro nivel (por ejemplo, del patio de pruebas de antes): se empieza de cero.
	if str(data.get("level", "")) != level_id():
		return
	Story.from_dict(_dict(data.get("story")))
	player.key_items.clear()
	for id in _array(data.get("key_items")):
		if id is String:
			player.key_items.append(StringName(id))
	for id in _array(data.get("arts")):
		if id is String:
			player.arts.unlock(StringName(id))
	if data.get("art_equipped") is String:
		player.arts.equip(StringName(data["art_equipped"]))
	player.attributes.from_dict(_dict(data.get("attributes")))
	player.apply_attributes()
	player.xp = int(data["xp"]) if _is_number(data.get("xp")) else 0
	var spawn: Array = _array(data.get("spawn"))
	if spawn.size() == 4 and spawn.all(_is_number):
		player.set_spawn(Vector3(spawn[0], spawn[1], spawn[2]), float(spawn[3]))
		player.respawn()
	else:
		player.restore()
	var satchel: Dictionary = _dict(data.get("satchel"))
	var at: Array = _array(satchel.get("at"))
	if at.size() == 3 and at.all(_is_number) and _is_number(satchel.get("amount")) and int(satchel["amount"]) > 0:
		XpSatchel.spawn(player.get_parent(), Vector3(at[0], at[1], at[2]), int(satchel["amount"]))


## El nivel de esta partida: el nombre de la escena actual sin carpeta ni extensión ("iron_pass").
## Así mover la escena de carpeta no borra las partidas.
func level_id() -> String:
	var scene: Node = get_tree().current_scene
	return _id_from(scene.scene_file_path) if scene else ""


func _id_from(scene_path: String) -> String:
	return scene_path.get_file().get_basename()


func _parse(text: String) -> Dictionary:
	var json := JSON.new()
	if text.is_empty() or json.parse(text) != OK or not (json.data is Dictionary):
		return {}
	return json.data


func _dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _array(value: Variant) -> Array:
	return value if value is Array else []


func _is_number(value: Variant) -> bool:
	return value is float or value is int


func _vec(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]
