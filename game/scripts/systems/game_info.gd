class_name GameInfo
extends RefCounted
## Datos del juego que no cambian durante la partida: versión (se ve en el menú principal; los probadores la
## apuntan al avisar de un fallo) y escenas principales.

## Versión: 0.<hito>.<entrega dentro del hito>. Subirla en cada `.exe` que se dé a probar.
const VERSION: String = "0.9.4"
const TITLE: String = "Hierro y Ceniza"
## La partida (el Paso de Hierro). La escena que arranca el juego es el menú principal (project.godot).
const GAME_SCENE: String = "res://scenes/levels/iron_pass.tscn"
const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
