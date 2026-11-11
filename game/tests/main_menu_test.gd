extends Node
## Prueba automática del menú principal (Hito 9, paso 6a): el juego arranca en el menú; sin partida no sale
## "Continuar"; con partida sí; "Partida nueva" con una partida guardada pide confirmación y, al aceptar, la borra;
## se ve la versión; la partida y el prólogo siguen ligados al Paso de Hierro (no al menú).
## Ejecutar: Godot --headless --path game res://tests/main_menu_test.tscn

const TEST_PATH: String = "user://save_menu_test.json"

var _failures: int = 0


func _ready() -> void:
	SaveGame.path = TEST_PATH
	SaveGame.erase()
	_check("El juego arranca en el menú principal", ProjectSettings.get_setting("application/run/main_scene") == GameInfo.MENU_SCENE)
	_check("La partida es el Paso de Hierro", GameInfo.GAME_SCENE == "res://scenes/levels/iron_pass.tscn" and ResourceLoader.exists(GameInfo.GAME_SCENE))

	# 1. Sin partida guardada.
	var menu := _menu()
	await get_tree().process_frame
	_check("Sin partida, no sale Continuar", not menu._buttons[&"continue"].visible)
	_check("…y el foco está en Partida nueva", menu._buttons[&"new"].has_focus())
	_check("Se ve la versión (%s)" % GameInfo.VERSION, _has_text(menu, GameInfo.VERSION))
	menu.press(&"new")
	_check("Partida nueva sin partida guardada: empieza directamente", menu.chosen == &"new" and not menu._confirm.visible)
	menu.queue_free()

	# 2. Con partida guardada.
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveGame.VERSION, "level": "iron_pass", "xp": 10}))
	file.close()
	menu = _menu()
	await get_tree().process_frame
	_check("Con partida, sale Continuar y tiene el foco", menu._buttons[&"continue"].visible and menu._buttons[&"continue"].has_focus())
	menu.press(&"continue")
	_check("Continuar sigue la partida (sin borrarla)", menu.chosen == &"continue" and SaveGame.exists())
	menu.chosen = &""
	menu.press(&"new")
	_check("Partida nueva con partida guardada: pide confirmación", menu._confirm.visible and menu.chosen == &"")
	menu.press(&"no")
	_check("…«No» vuelve sin borrar nada", not menu._confirm.visible and SaveGame.exists())
	menu.press(&"new")
	menu.press(&"yes")
	_check("…«Sí» borra la partida y empieza una nueva", menu.chosen == &"new" and not SaveGame.exists())
	menu.press(&"quit")
	_check("Salir", menu.chosen == &"quit")
	_check("En el menú no se abre la pausa (no hay partida)", get_tree().get_first_node_in_group("player") == null)
	menu.queue_free()
	SaveGame.erase()
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _menu() -> MainMenu:
	var menu := (load(GameInfo.MENU_SCENE) as PackedScene).instantiate() as MainMenu
	menu.dry_run = true
	add_child(menu)
	return menu


func _has_text(node: Node, text: String) -> bool:
	for child in node.find_children("*", "Label", true, false):
		if text in (child as Label).text:
			return true
	return false


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
