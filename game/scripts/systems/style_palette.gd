class_name StylePalette
extends RefCounted
## La paleta cerrada del juego (docs/16_GUIA_DE_ESTILO.md). Todo lo que se pinte sale de aquí: así el juego se
## ve coherente aunque los modelos vengan de sitios distintos (kits CC0 recoloreados).
## Grises de pizarra y ocres de ceniza como base; solo 3 acentos con significado:
## rojo óxido = peligro (ataques rojos, Varga) · naranja = fuego y lugar seguro · azul acero = el metal, el desvío.

const SLATE_DARK := Color("2e3236")   ## Sombras, rocas lejanas, hierro viejo.
const SLATE := Color("4a5057")        ## Muros de la fortaleza, rocas.
const STONE := Color("6e6a64")        ## Piedra de las casas, caminos empedrados.
const ASH := Color("9a958c")          ## Ceniza, polvo, cielo nublado.
const BONE := Color("bdb7aa")         ## Telas grises de la cuarentena, vendas.
const EARTH := Color("5a4a3a")        ## Tierra, barro.
const WOOD := Color("6b4e34")         ## Madera de las casas, cajas, postes.
const MOSS := Color("4f5a40")         ## Verde apagado: el bosque.
const LEATHER := Color("3f3328")      ## Cuero, correas, botas.
const RUST := Color("8e3b2a")         ## ACENTO: peligro, la capitana Varga, sangre seca.
const EMBER := Color("d9822b")        ## ACENTO: fuego, fogatas, farolillos (por aquí se sigue).
const STEEL := Color("6f8fa6")        ## ACENTO: metal de las armas, el destello del desvío.

const ALL: Dictionary = {
	"pizarra oscura": SLATE_DARK, "pizarra": SLATE, "piedra": STONE, "ceniza": ASH, "hueso": BONE,
	"tierra": EARTH, "madera": WOOD, "musgo": MOSS, "cuero": LEATHER,
	"óxido": RUST, "brasa": EMBER, "acero": STEEL,
}
## Los acentos: se usan poco, para que signifiquen algo.
const ACCENTS: Array[Color] = [RUST, EMBER, STEEL]

## Niebla y luz de cada zona del Paso de Hierro: [color de la niebla, densidad, color del sol].
const ZONES: Dictionary = {
	&"aldea": [Color("8f8a82"), 0.012, Color("e8dcc8")],      # Gris, humo de la ropa ardiendo.
	&"bosque": [Color("6f7766"), 0.016, Color("d8dcc4")],     # Verde apagado, más cerrado.
	&"fortaleza": [Color("7d8590"), 0.010, Color("cfd8e2")],  # Fría, azulada; los braseros dan el calor.
}


## Un material mate de la paleta.
static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m


## ¿Es este color de la paleta? (para las pruebas de los assets que entren).
static func has(color: Color, tolerance: float = 0.02) -> bool:
	for key in ALL:
		var c: Color = ALL[key]
		if absf(c.r - color.r) <= tolerance and absf(c.g - color.g) <= tolerance and absf(c.b - color.b) <= tolerance:
			return true
	return false
