# 17 · Registro de fallos y opiniones de los probadores

Aquí se apunta todo lo que encuentren el jugador y las personas que prueban el `.exe` (Hito 9, paso 6a). Cada
fallo, cuando se arregla, se marca con la prueba automática que lo vigila desde entonces.

## Cómo apuntar un fallo

| Campo | Ejemplo |
|---|---|
| Versión | 0.9.4 (abajo a la derecha en el menú) |
| Qué hice | Rodé contra la pared del camino del inicio |
| Qué esperaba | Que Kael se parara |
| Qué pasó | La cámara se metió en la roca |
| Dónde | Camino del Paso, junto al tronco |
| Mando o teclado | Mando |
| Registro / captura | `godot.log` (ver `build/LEEME.txt`) o una captura |

## Hoja para los probadores (las 5 preguntas)

1. ¿Dónde te perdiste o no supiste a dónde ir?
2. ¿Qué no entendiste?
3. ¿Cuántas veces moriste, y dónde?
4. ¿Qué es lo que más te gustó?
5. ¿Se rompió algo? ¿Dónde?

Mientras juegan: **mirar sin ayudar**. Apuntar dónde dudan, dónde mueren y si encuentran el atajo.

## Fallos abiertos

| # | Versión | Quién | Dónde | Qué pasa | Estado |
|---|---|---|---|---|---|
| — | | | | (ninguno por ahora) | |

## Fallos arreglados

| # | Qué pasaba | Arreglo | Prueba que lo vigila |
|---|---|---|---|
| 1 | La cámara se metía en las paredes de roca | Esfera en el SpringArm | `walls_test`, `camera_test` |
| 2 | En la escena de Frank la roca tapaba la cámara | `LevelCutscene.clear_view` y rincón más grande | capturas `frank_shot` |
| 3 | Y daba una patada al intentar soltar a Frank | `Player.interaction_nearby()` | `frank_test` |
| 4 | No se sabía desde dónde se mata por la espalda | Marca roja ◆ y aviso | `tutorial_hints_test` |
| 5 | Varga se quedaba encima de Kael | Resbalar al suelo | `stack_test` |
| 6 | Morir con un virote o la fruta en el aire: seguían volando | `Camps.reset_world` | `respawn_clean_test` |

## Opiniones de los probadores

(Se apuntan aquí, con la fecha y el nombre o inicial de quien probó.)
