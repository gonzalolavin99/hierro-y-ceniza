# 12 · Plan del Paso de Hierro (Hito 9: la "vertical slice")

**Estado:** propuesta 🔶, versión 2 con los cambios del jugador (bosque obligatorio, Bram gigante de 3 m,
aldeanos que cuentan lo que pasa sin decirlo, y un prólogo nuevo donde el Regente parece bueno).

Una **vertical slice** es un trozo pequeño del juego hecho como si fuera el juego final: de principio a
fin, jugable, para que otra persona lo pruebe y diga si engancha. Para nosotros es **el Prólogo y el Acto I**
(guion §5 y §10): de la orden del Regente hasta vencer a Varga, en 15–25 minutos.

Hasta ahora todo vive en el **escenario de pruebas** (un patio con piezas sueltas). Este plan lo convierte en
un **nivel de verdad**, con un camino que se recorre en orden y que se va abriendo.

## 1. Cómo lo haremos (orden de los pasos)

1. **Este plan** (mapa, zonas, qué pasa en cada una). Lo apruebas o lo cambias.
2. **El prólogo nuevo** (guion §5, "Prólogo, versión 2"): el Regente parece bueno (música cálida, baja del
   trono, habla de Lira antes que de nada), **recuerdo de Kael con su hermana**, los cinco nombres uno a uno
   con pena, y **la primera elección** ("Los detendré" / "Acabaré con ellos"; el Regente está de acuerdo con
   las dos). Va primero porque es con lo que empieza el juego y está fresco.
3. **El nivel "en bloques" (greybox)**: el mapa entero con cajas, rampas y muros sencillos, sin arte. Sirve para
   probar que el camino, las distancias y los combates funcionan antes de gastar tiempo en dibujar. El patio
   de pruebas se queda para las pruebas automáticas.
4. **La gente de la aldea**: **aldeanos** (ver §3B) que, sin que te des cuenta, cuentan lo que pasa de verdad;
   los soldados de Varga que avisan ("¡Atrás! No te acerques a las casas"), las telas grises, la carta de
   raciones, y **el desertor que se rinde** (la primera de las 6 cosas del final bueno).
5. **Bram, el Carcelero** (mini-jefe): **un gigante de unos 3 m** (casi el doble que Kael), lento, con cadena y
   grillete, junto al lazareto. Golpes amplios que se esquivan mejor que se paran.
6. **Menú principal y opciones** (gráficos, subtítulos, sangre) y **exportar el `.exe`** para que lo pruebe otra
   persona.
7. **Arte**: guía de estilo visual, diseño final de Kael, enemigos, Varga, Bram y Frank (mejorar su modelo) y la
   iluminación del nivel.

El arte va al final a propósito (D14: primero que se juegue bien). Si algo del mapa no funciona en bloques,
cambiarlo cuesta minutos; con arte, días.

## 2. El mapa (vista desde arriba, aproximada)

```
                                N (montaña)
                 ┌────────────────────────────────────┐
                 │   PATIO DE VARGA  (jefa)            │
                 │        ▲ rastrillo                  │
                 │  ┌─────┴──────────┐                 │
                 │  │  FORTALEZA      │   LAZARETO      │
                 │  │  (exterior)     │── Bram (mini)   │
                 │  │  🔥 Campamento 2 │                 │
                 │  └──┬──────────────┘                 │
                 │     │  ← ATAJO: portón lateral        │
                 │     │    (Frank lo abre desde dentro) │
                 │     │                                 │
                 │  ┌──┴──────────────────────┐          │
                 │  │ BOSQUE (obligatorio)     │          │
                 │  │ sigilo, arqueros,        │          │
                 │  │ campamento de cazadores  │          │
                 │  └──┬──────────────────────┘          │
                 │  ┌──┴────────────┐                    │
                 │  │ ALDEA EN      │  casa del pozo     │
                 │  │ CUARENTENA    │  (telas grises)    │
                 │  │ 🔥 Campamento 1│  aldeanos          │
                 │  └──┬────────────┘                    │
                 │     │                                 │
                 │  CAMINO DEL PASO                      │
                 │  (tutorial · red de Frank)            │
                 └─────┴───────────────────────────────┘
                       S  ← empieza aquí (tras la escena del prólogo)
```

Unos **250 × 300 m** en total. El camino sube de sur a norte: camino → aldea → **bosque** → fortaleza → patio
de Varga. El bosque es **paso obligatorio** (decisión del jugador): es la única forma de llegar a la fortaleza
la primera vez. El atajo une la fortaleza con la aldea: al abrirlo, el campamento 1 queda a un paso del
jefe sin volver a cruzar el bosque.

## 3. Las zonas, una a una

### A. Camino del Paso (2–4 min) · tutorial
- Empieza tras la escena del prólogo. El anciano: "Esta es la historia de un guerrero…".
- Carteles cortos de controles, uno por tramo: moverse, saltar, rodar, atacar, cubrirse y desviar.
- **Un soldado de práctica** que se cubre (aprender a desviar) y **un bandido** suelto.
- **La red de Frank** a mitad del camino: se le suelta o se pasa de largo (ya hecho).
- Termina en un arco de piedra con la primera vista de la aldea y **el humo** de las hogueras de ropa.

### B. Aldea en cuarentena (5–7 min)
- **Campamento 1** a la entrada.
- Casas en ruinas; algunas puertas con **tela gris**. Soldados de Varga que no atacan enseguida: avisan
  primero ("¡Atrás! No te acerques a las casas"). Kael lo lee como una amenaza (y el jugador también, la
  primera vez).
- **Aldeanos** (no pelean; pasear entre ellos es seguro). Cada uno dice una frase corta al pasar o con Y, y
  ninguno explica nada: el jugador lo va juntando solo. Ejemplos:
  - Una mujer barre delante de una casa con tela gris: "No se entra. La capitana lo dijo. Ni por pan."
  - Un viejo junto a la hoguera de ropa: "Las mantas de mi hijo… las quemaron ayer. Mejor eso que lo otro."
  - Un niño con un dibujo de una mujer con espada: "Es la capitana. Nos trae el agua cuando no hay."
  - Un hombre que mira el camino de la capital: "Mandaron soldados, no médicos. Otra vez."
  - Una madre a su hija, al ver la espada de Kael: "No mires. Es de los del Regente."
  La primera vez, Kael (y el jugador) lo leen como gente asustada de unos rebeldes. Al volver tras Varga,
  las mismas frases suenan distintas.
- **El desertor**: un soldado de Varga que suelta la espada y se arrodilla. Si Kael se va sin rematarlo, más
  tarde lleva agua a la casa del pozo. No hay aviso ni barra: solo cambia el mundo.
- **La casa del pozo**: la **carta de raciones** en un cadáver ("para los de la casa del pozo").
- Enemigos: 2 grupos de 2–3 soldados, 1 lancero y 1 arquero en un tejado.

### C. Bosque (4–6 min) · sigilo (obligatorio)
- Hierba alta, árboles, rocas para esconderse. **Centinelas desprevenidos** (golpe por la espalda) y la
  **fruta de Frank** tiene aquí su sitio natural.
- **Escondite**: el campamento de los cazadores (la despensa de la nota; ya hecho) y una cosa útil al fondo.
- Al fondo sale a la rampa de la fortaleza. Un sendero escondido vuelve a la aldea (se abre con el atajo).

### D. Fortaleza, exterior (4–6 min)
- Rampa hacia el portón, con arqueros en lo alto y un grupo mixto abajo.
- **Campamento 2** antes del lazareto.
- **El atajo**: un portón lateral cerrado por dentro. Frank salta el muro y lo abre: une la fortaleza con la
  aldea.
- **El lazareto** y **Bram** (mini-jefe), **un gigante de unos 3 m**. Tras vencerlo, su llave (guion: llevarla al lazareto o abrir el
  portón; lo segundo aquí, lo primero en el futuro).

### E. Patio de Varga (jefa)
- El que ya existe (rastrillo, niebla, pira de ropa, escena previa, música, dos golpes mortales).
- Al vencerla: el estandarte, la Ráfaga, y el anciano cierra el Acto I.

## 4. Qué reutilizamos (ya hecho) y qué falta

| Ya existe | Falta |
|---|---|
| Combate, enemigos (soldado, bandido, lancero, arquero), IA y sigilo | El mapa en bloques |
| Campamentos, experiencia, guardado, pausa e inventario | Carteles del tutorial |
| Prólogo, narrador y escena de Varga | Soldados que avisan antes de atacar |
| Varga y su patio | El desertor (y la variable del final bueno) |
| Frank completo (red, consejos, avisos, escondites, despensa, fruta) | Aldeanos con sus frases; casa del pozo, telas grises, carta de raciones |
| Escena del prólogo (versión 1) | Prólogo nuevo: música cálida, recuerdo de Lira, los cinco nombres y la elección |
| | El portón lateral (atajo) y el lazareto |
| | Bram, gigante de 3 m |
| | Menú principal, opciones y `.exe` |

## 5. Rendimiento (docs/01)

Cada zona es una parte separada del nivel. Solo hay enemigos despiertos cerca de Kael. Se aplican las mismas
cifras que en el patio de pruebas: 60 FPS en la laptop, sin sombras caras ni demasiados enemigos a la vez.
Si una zona pasa del presupuesto, se separa en dos.

## 6. Decisiones del jugador (2026-11-06)

- El bosque es **obligatorio** (no un desvío).
- **Bram es un gigante de unos 3 m.**
- En la aldea hay **aldeanos** que cuentan lo que pasa sin decirlo.
- **Prólogo nuevo**: el Regente tiene que parecer bueno; recuerdo de Kael con su hermana; los nombres uno a
  uno y una elección que el Regente acepta siempre.
