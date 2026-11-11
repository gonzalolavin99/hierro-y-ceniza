# 16 · Guía de estilo (borrador para el OK del jugador, 2026-11-11)

Es la regla de cómo debe verse **todo** el juego. Hay que decidirla antes de vestir el nivel (paso 7), y no al
final: si no, se acaba juntando un montón de assets que no combinan (revisión del estudio, arte).
Escena de prueba: `game/tests/style_probe.tscn` (capturas en `docs/estilo/`).

## 1. El estilo en una frase

**Low-poly pintado, sin texturas finas.** Low-poly significa pocas caras: formas sencillas y siluetas claras.
Los colores salen de una **paleta cerrada** y casi no hay textura. Es un estilo que una persona con ayuda de la
IA y kits CC0 puede mantener, y que la GTX 1050 mueve sin esfuerzo. Referencias de *tono* (no de copia): la
dureza de los souls-like; el color sobrio de Kingdom Come; la claridad de formas de Death's Door o Tunic.
**No** perseguimos el realismo de Sekiro.

## 2. La paleta (`game/scripts/systems/style_palette.gd`)

| Color | Para qué |
|---|---|
| Pizarra oscura `#2e3236` | Sombras, hierro viejo, rocas lejanas |
| Pizarra `#4a5057` | Rocas y muros de la fortaleza |
| Piedra `#6e6a64` | Casas, empedrado |
| Ceniza `#9a958c` | Polvo, cielo nublado, ceniza |
| Hueso `#bdb7aa` | **Telas grises de la cuarentena**, vendas |
| Tierra `#5a4a3a` | Suelo, barro |
| Madera `#6b4e34` | Casas, cajas, postes |
| Musgo `#4f5a40` | El bosque (verde apagado) |
| Cuero `#3f3328` | Correas, botas, la ropa de Kael |
| **Óxido** `#8e3b2a` | **Acento: peligro** (ataques rojos), la gente de Varga |
| **Brasa** `#d9822b` | **Acento: fuego**, fogatas, farolillos ("por aquí se sigue") |
| **Acero** `#6f8fa6` | **Acento: el metal**, el destello del desvío |

Los tres acentos se usan **poco**, y así significan algo: si algo es rojo óxido, es peligro o es de Varga; si
es naranja, es seguro o marca el camino. El aviso rojo de los ataques peligrosos siempre se tiene que ver
encima de cualquier color de la paleta.

## 3. Formas

- **Siluetas grandes y claras**: hombreras, capas, cascos con forma. Cada tipo de enemigo se tiene que
  reconocer **solo por su silueta a 15 m**: el soldado con yelmo redondo, el lancero con la lanza larga, el
  arquero con capucha y arco, el bandido con pañuelo, Varga con su capa, Bram enorme.
- **Personajes tapados**: yelmos, capuchas y pañuelos. Las caras son lo más difícil de hacer bien, así que se
  ven poco o con rasgos simples.
- **Kael**: cuero y pizarra, sin brillos, y **la cinta de Lira** (siempre visible, el único detalle claro sobre él).
- Nada de calaveras, runas, símbolos raros ni estatuas de culto (`04_GUIA_DE_CONTENIDO.md`).

## 4. Límites (para que vaya bien en la GTX 1050)

| Cosa | Límite |
|---|---|
| Personaje | ≤ 8.000 triángulos (un jefe, ≤ 15.000) |
| Texturas | Una textura-paleta pequeña (256 px) compartida; Poly Haven a 512 px solo para el suelo |
| Llamadas de dibujo por zona | < 1.000 (hoy, la peor zona tiene 640) |
| FPS | ≥ 45 en la peor zona (hoy, 129: ver doc 01) |

## 5. Cómo se ve cada zona (luz y niebla: `StylePalette.ZONES`)

- **Aldea**: gris, con el humo de la ropa ardiendo; niebla gris cálida. Las telas de la cuarentena son lo
  más claro de la escena: tienen que llamar la atención.
- **Bosque**: verde apagado y más cerrado, con la niebla más densa. Luz que entra entre los árboles.
- **Fortaleza**: fría y azulada; el único calor son los braseros, que marcan el camino.
- Luz: un sol bajo y cálido, sombra suave en las esquinas (SSAO, calidad baja) y luces naranjas de guía.

## 6. Cómo se hacen las cosas (cuando llegue el paso 7)

1. **Cuerpo base CC0** (Quaternius Universal/Modular Characters) para sustituir al Y Bot. El esqueleto común
   (`game/scripts/components/bones.gd`) hace que el cambio sea solo la tabla de huesos. **Antes de descargar
   nada se pide permiso al jugador.**
2. **Escenarios con kits CC0** (Quaternius, Kenney) **recoloreados a la paleta**. Cada asset se apunta en
   `CREDITOS.md` y se revisa con la guía de contenido.
3. **Prueba de belleza**: primero se viste una sola esquina (la arena de Varga o un rincón de la aldea), y
   después el resto.

## 7. Lo que muestra la escena de prueba

Es un rincón con cinco objetos (casa con tela gris, rocas de pocas caras, cajas, brasero, valla con estandarte
óxido) y dos personajes: Kael en cuero y un soldado de acero con yelmo. Se ve con la luz de la aldea, la del
bosque y la de la fortaleza. Los cuerpos siguen siendo maniquíes y el arte de verdad llega en el paso 7, pero
los **colores**, la **luz** y las **formas sencillas** ya son los del juego final.
