extends Node
## Prueba automática de las descripciones de objetos (ItemLore): todas completas, en orden, sin palabras
## prohibidas por la guía de contenido, y los objetos clave se guardan con la partida.
## Ejecutar: Godot --headless --path game res://tests/lore_test.tscn

const BANNED: Array[String] = ["alma", "espíritu", "demonio", "diablo", "magia", "mágic", "hechiz", "bruj",
	"maldi", "dios", "fantasma", "infierno", "cielo", "reza", "rezo", "bendi", "milagro", "sagrad", "destino"]
const TEST_PATH: String = "user://save_lore_test.json"

var _failures: int = 0


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.force_active = true
	SaveGame.erase()
	add_child(load("res://scenes/levels/test_level.tscn").instantiate())
	var player := get_tree().get_first_node_in_group("player") as Player
	await get_tree().create_timer(0.3).timeout

	var incomplete: Array[String] = []
	for id: StringName in ItemLore.ORDER:
		var item: Dictionary = ItemLore.ITEMS.get(id, {})
		if String(item.get("name", "")) == "" or String(item.get("kind", "")) == "" or String(item.get("text", "")).length() < 60:
			incomplete.append(String(id))
	_check("Cada objeto tiene nombre, tipo y una descripción de verdad %s" % str(incomplete), incomplete.is_empty())
	_check("Todos los objetos están en el orden del inventario", ItemLore.ITEMS.size() == ItemLore.ORDER.size())
	var missing: Array[String] = []
	for id: StringName in PlayerTools.ORDER + PlayerArts.ORDER:
		if not ItemLore.ITEMS.has(id):
			missing.append(String(id))
	_check("Hay descripción para cada arma secundaria y técnica %s" % str(missing), missing.is_empty())

	var found: Array[String] = []
	for id: StringName in ItemLore.ITEMS:
		var text: String = (" " + ItemLore.ITEMS[id]["name"] + " " + ItemLore.ITEMS[id]["text"]).to_lower()
		for word in BANNED:
			if text.contains(" " + word) or text.contains("«" + word):
				found.append("%s: %s" % [id, word])
	_check("Sin palabras prohibidas por la guía %s" % str(found), found.is_empty())

	var owned: Array[StringName] = ItemLore.owned(player)
	_check("Sin objetos clave al empezar", not owned.any(func(id: StringName) -> bool: return ItemLore.ITEMS[id]["kind"] == "Objeto clave"))
	_check("Cuenta los vendajes (%s)" % ItemLore.count_text(player, &"bandage"), ItemLore.count_text(player, &"bandage") == "%d / %d" % [player.bandages, player.max_bandages])

	player.key_items.append(&"bram_key")
	SaveGame.save(player)
	player.key_items.clear()
	SaveGame.on_player_ready(player)
	_check("La partida guarda los objetos clave (%s)" % str(player.key_items), player.key_items == [&"bram_key"])
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
