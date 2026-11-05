extends Node
## Guardado automático de la partida, en un archivo JSON pequeño (user://save.json, en la carpeta de datos
## del juego). Se guarda al descansar, al subir atributos, al morir y al recoger el morral; se carga al abrir
## el juego (cuando aparece Kael). Qué se guarda: atributos, experiencia, último campamento, el morral
## y la historia (acto y narraciones ya oídas).
## Solo actúa en la partida real (la escena principal); las pruebas usan otro archivo con `force_active`.

const VERSION: int = 1

var path: String = "user://save.json"
## Para las pruebas: guardar/cargar aunque no sea la escena principal.
var force_active: bool = false


## ¿Es la partida real (o una prueba que lo pide)?
func active() -> bool:
	if force_active:
		return true
	var scene: Node = get_tree().current_scene
	return scene != null and scene.scene_file_path == ProjectSettings.get_setting("application/run/main_scene", "")


func exists() -> bool:
	return FileAccess.file_exists(path)


func erase() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Guarda el estado actual del jugador (si es la partida real).
func save(player: Player) -> void:
	if not active() or player == null:
		return
	var data: Dictionary = {
		"version": VERSION,
		"xp": player.xp,
		"attributes": player.attributes.to_dict(),
		"spawn": _vec(player.spawn_position()) + [player.start_facing_degrees],
		"story": Story.to_dict(),
	}
	for node in get_tree().get_nodes_in_group("xp_satchels"):
		var bag := node as XpSatchel
		if bag and not bag.is_queued_for_deletion():
			data["satchel"] = {"at": _vec(bag.global_position), "amount": bag.amount}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la partida en %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Lee el archivo; si no existe o está roto, devuelve un diccionario vacío.
func read() -> Dictionary:
	if not exists():
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		push_warning("Partida guardada ilegible (%s): se empieza de cero." % path)
		return {}
	return json.data


## Al aparecer Kael: si hay partida guardada, la carga.
func on_player_ready(player: Player) -> void:
	Squad.reset()
	Story.reset()
	if not active():
		return
	var data: Dictionary = read()
	if data.is_empty():
		return
	Story.from_dict(data.get("story", {}))
	player.attributes.from_dict(data.get("attributes", {}))
	player.apply_attributes()
	player.xp = int(data.get("xp", 0))
	var spawn: Array = data.get("spawn", [])
	if spawn.size() == 4:
		player.set_spawn(Vector3(spawn[0], spawn[1], spawn[2]), float(spawn[3]))
		player.respawn()
	else:
		player.restore()
	var satchel: Dictionary = data.get("satchel", {})
	if satchel.has("at") and int(satchel.get("amount", 0)) > 0:
		var at: Array = satchel["at"]
		XpSatchel.spawn(player.get_parent(), Vector3(at[0], at[1], at[2]), int(satchel["amount"]))


func _vec(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]
