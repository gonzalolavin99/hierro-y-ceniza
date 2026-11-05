class_name ItemLore
extends RefCounted
## Descripciones de los objetos (inventario del menú de pausa). Cuentan la historia de lado, como en los
## souls: nunca la dicen entera. Guion en docs/11_GUION.md; todo cumple docs/04_GUIA_DE_CONTENIDO.md.
## kind: tipo que se muestra · text: descripción. Los "objetos clave" (documentos, llaves…) solo aparecen
## cuando Kael los tiene (Player.key_items); el resto, según lo que lleve.

const ITEMS: Dictionary[StringName, Dictionary] = {
	# --- Equipo y recuerdos (siempre) ---
	&"sword": {"name": "Espada del Regente", "kind": "Arma",
		"text": "Acero templado en las forjas de la capital, con el sello del Regente grabado en la guarda. Se la entregaron a Kael el día en que juró obedecer. Nunca le explicaron del todo qué estaba jurando."},
	&"lira_ribbon": {"name": "Cinta de Lira", "kind": "Recuerdo",
		"text": "Una cinta azul, descolorida por el sol y el sudor. Kael la lleva atada a la muñeca y nunca se la quita. Era de su hermana. No recuerda bien cuándo se la dio; prefiere no intentarlo."},
	&"bandage": {"name": "Vendaje", "kind": "Consumible",
		"text": "Lino hervido y bien enrollado. En los cordones de la frontera lo hervían dos veces antes de usarlo; en la capital, nadie lo hervía. Uno cura casi la mitad de las heridas. Se reponen al descansar junto al fuego."},
	# --- Armas secundarias ---
	&"crossbow": {"name": "Ballesta de muñeca", "kind": "Arma secundaria",
		"text": "Ballesta pequeña atada al antebrazo, de los talleres del Regente. Sus virotes cortos hacen poco daño, pero uno a tiempo interrumpe al que se prepara para golpear. En los cordones aprendieron a temer su chasquido."},
	&"smoke": {"name": "Bomba de humo", "kind": "Arma secundaria",
		"text": "Ceniza de leña y salitre envueltos en tela encerada. Al romperse, el humo ciega y hace toser: durante unos instantes el enemigo no puede atacar ni defenderse. Fue un recurso de cazadores antes que de soldados."},
	&"powder": {"name": "Bomba de pólvora", "kind": "Arma secundaria",
		"text": "Pólvora negra prensada en barro cocido, con mecha corta. Rompe cualquier guardia, pero no distingue entre amigos: conviene estar lejos cuando estalla. En la capital decían que los rebeldes la usaban para volar puentes."},
	# --- Técnicas ---
	&"art_whirlwind": {"name": "Torbellino", "kind": "Técnica",
		"text": "Giro completo con la espada para quitarse de encima a quien rodea. Se enseña en los cuarteles del Regente a todos los reclutas. Kael lo aprendió antes de saber leer."},
	&"art_hammer": {"name": "Golpe de Martillo", "kind": "Técnica",
		"text": "Salto y tajo descendente con todo el peso del cuerpo. Los soldados de la frontera lo usaban para partir escudos… y puertas atrancadas. Quien se lo enseñó a Kael no quiso decirle su nombre."},
	&"art_flurry": {"name": "Ráfaga", "kind": "Técnica",
		"text": "Serie de tajos rápidos que no dejan respirar. Contra alguien que se cubre, es una invitación a que conteste. Varga la usaba así: para ver quién perdía antes la paciencia."},
	# --- Objetos clave (se consiguen en la historia) ---
	&"grey_cloth": {"name": "Tela gris", "kind": "Objeto clave",
		"text": "Se ataba en las puertas de las casas con enfermos de la Ceniza. Para el soldado del Regente, marcaba un objetivo. Para el vecino, significaba «no entres»."},
	&"bram_key": {"name": "Llave del Carcelero", "kind": "Objeto clave",
		"text": "Una llave de hierro grande, gastada de tanto girar. Abre el portón de la fortaleza del Paso. Bram la llevaba colgada del cuello y dormía con ella en la mano. Quien la tenga decide si esa puerta se abre."},
	&"regent_letter": {"name": "Carta del Regente a Orme", "kind": "Objeto clave",
		"text": "«Maestro Orme: abra la presa y retire a sus hombres antes del invierno. La Corona sabrá agradecerlo en oro y en tierras. Si se niega, la Corona sabrá también qué hacer.» Lleva el sello del Regente. Está arrugada, como si alguien la hubiera querido tirar y no se hubiera atrevido."},
	&"capital_register": {"name": "Registro de la capital", "kind": "Objeto clave",
		"text": "Libro de defunciones del barrio del mercado. Una línea, con letra apretada: «Lira, hija de Doran. Fiebre gris. Dentro de las murallas.» La fecha es de un mes antes de que se cerrara el primer cordón."},
}

## Orden en el inventario.
const ORDER: Array[StringName] = [
	&"sword", &"lira_ribbon", &"bandage",
	&"crossbow", &"smoke", &"powder",
	&"art_whirlwind", &"art_hammer", &"art_flurry",
	&"grey_cloth", &"bram_key", &"regent_letter", &"capital_register",
]
const ALWAYS: Array[StringName] = [&"sword", &"lira_ribbon", &"bandage"]


## Objetos que lleva ahora `player`, en el orden del inventario.
static func owned(player: Player) -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in ORDER:
		if id in ALWAYS or id in PlayerTools.ORDER or id in player.arts.unlocked or id in player.key_items:
			result.append(id)
	return result


## Cuántos lleva (texto corto) o "" si no se cuenta.
static func count_text(player: Player, id: StringName) -> String:
	if id == &"bandage":
		return "%d / %d" % [player.bandages, player.max_bandages]
	if id in PlayerTools.ORDER:
		return "%d / %d" % [player.tools.ammo[id], PlayerTools.DATA[id]["max"]]
	return ""
