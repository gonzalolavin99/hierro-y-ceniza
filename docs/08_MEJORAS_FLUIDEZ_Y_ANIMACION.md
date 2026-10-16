# Mejoras de fluidez y animación

Este documento guía el pulido del movimiento y el combate de *Hierro y Ceniza*. Lo iremos resolviendo por pasos: cada ajuste debe poder probarse en Godot y evaluarse con una sensación concreta. No avanzamos al siguiente paso de pulido hasta recibir el OK del jugador.

## Paso 1 — Cierre estable del paso rápido

**Cambio aplicado:** limitar el avance del paso al intervalo de su duración y calcular cuánto recorre cada fotograma integrando la curva de velocidad. Así no invierte el movimiento en un fotograma tardío y alcanza los 3,6 m configurados. También se protege el cálculo ante una duración casi en cero.

**Qué probar:** hacer pasos rápidos hacia delante, atrás y los lados; mantener una dirección al terminar; probarlo cerca de una rampa o borde. Fijarse si el final se siente continuo y si el personaje conserva el control.

**Prueba automática:** cinco comprobaciones cubren el impulso inicial, la reducción a mitad, la velocidad cero al final, la ausencia de inversión si el fotograma llega tarde y la distancia total de 3,6 m con margen de 0,1 m. La prueba estricta de distancia falló primero con 3,39 m; después del ajuste, recorrió 3,60 m. La prueba de movimiento pasó. La de combate tuvo un fallo intermitente y pasó al repetirla.

**Resultado del jugador:** pendiente.

## Paso 2 — Inclinación visual en rampas

**Cambio aplicado:** el maniquí inclina suavemente su cuerpo visual según la inclinación del suelo. La cápsula de colisión permanece vertical, para no alterar el control ni los golpes.

**Prueba automática:** primero falló con alineación 0,940 en la rampa de 20°. Después del ajuste llega a 1,000 y confirma que el jugador sube la rampa. La prueba de combate también fija el alcance del enemigo antes de medir los golpes, para que los empujones de los desvíos no vuelvan intermitente esa comprobación.

**Qué probar:** sube y cruza la rampa con el personaje; fíjate si la inclinación se ve natural al caminar, girar y atacar. El apoyo individual de los pies se implementa en el paso 4 y queda pendiente de tu revisión visual.

**Resultado del jugador:** pendiente.

## Paso 3 — Guardar la guardia al salir de la esquiva

**Cambio aplicado:** una pulsación breve de guardia durante el final de la esquiva queda guardada hasta 0,15 segundos. El personaje entra en guardia al recuperar el control y la suelta sola si el botón ya no está presionado.

**Prueba automática:** la prueba falló primero porque la guardia se perdía; después del ajuste verifica que entra en `Block` y vuelve a `Ground` al agotarse el margen. El ciclo de trabajo está descrito en `00_LEEME.md` y `06_ARQUITECTURA_TECNICA.md`.

**Qué probar:** al esquivar, pulsa y suelta guardia justo antes de terminar. Comprueba si el personaje protege enseguida y si no queda bloqueando más de lo esperado.

**Resultado del jugador:** pendiente.

## Paso 4 — Apoyo individual de los pies

**Cambio aplicado:** se añadió `FootGroundingModifier` al esqueleto. Después de cada animación, lanza dos consultas cortas al suelo, una por tobillo. Si un pie está cerca del piso, ajusta su altura con IK de dos huesos (cálculo que conserva la flexión natural de la rodilla). Si está levantado o requiere un cambio grande, no lo fuerza. La cápsula y el control no cambian.

**Prueba TDD:** primero se agregó la comprobación a `movement_test.gd`; falló porque el modificador aún no existía. Tras implementarlo, verifica que esté activo y encuentre suelo en la rampa de 20°. Movimiento y combate pasan. La consulta usa la capa física del suelo; son dos rayos por personaje activo.

**Qué probar:** camina despacio y corre por la rampa; fíjate en los tobillos al apoyar, al levantar cada pie, al girar y al atacar. Avísame si se ven flotando, atravesando el suelo o si las rodillas tiemblan.

**Resultado del jugador:** pendiente.

## Paso 5 — El cuerpo caminaba "de espaldas" (corregido)

**Problema reportado:** al avanzar, el personaje se movía de espaldas.
**Causa:** la inclinación en rampas (paso 2) reemplazaba la orientación del modelo y le quitaba el
giro de 180° que necesita el maniquí de Mixamo (que mira hacia +Z).
**Cambio:** la inclinación ahora se combina con ese giro base, guardado al iniciar.
**Prueba automática:** `movement_test` comprueba que el cuerpo mira hacia donde avanza, en plano (1,00)
y sobre la rampa.

## Paso 6 — La patada lanzaba al soldado ~20 m (corregido)

**Causa:** los empujones (patada, choques, golpes) se sumaban a la velocidad en cada fotograma y se
acumulaban.
**Cambio:** el empujón se aplica solo al movimiento de cada fotograma y se desvanece; no se acumula.
**Prueba automática:** `moveset_test` mide el empujón de la patada: 0,93 m (límite 3 m).

## Paso 7 — Pies flotando en la rampa (corregido)

**Medición** (`tests/feet_probe.tscn`, mide la pose final ya ajustada): el tobillo natural del
modelo está a 10,7 cm del suelo, pero el apoyo usaba 14 cm, así que elevaba los pies ~3 cm incluso en
suelo plano. Además bajaba también el pie que la animación levanta al caminar.
**Cambio** (técnica estándar de apoyo de pies):
1. Altura de apoyo = 10,7 cm (medida).
2. Se respeta cuánto levanta la animación cada pie: el pie en el aire sigue en el aire.
3. Si un pie tiene que bajar (pendiente), la cadera baja lo justo, con suavizado, para que llegue.
4. IK de dos huesos para colocar cada tobillo.
**Resultado medido:** plano 10,7 cm (igual que la animación); rampa quieto 10,1 cm (perpendicular a la
pendiente, ≈ 10,7 cm en vertical); caminando, el pie apoyado queda en el suelo y el que avanza conserva
su altura.

## Pruebas que corresponden ahora

Estas comprobaciones manuales son para los pasos ya implementados (1–4). No hace falta probar las mejoras futuras. Hazlas en la escena de prueba con el mando y marca cada resultado; la prueba de pies es la prioridad porque es el cambio más reciente.

| Estado | Paso | Qué hacer | Qué observar |
|---|---|---|---|
| [ ] | 4. Apoyo de pies — prioridad | Entra y sal de la rampa caminando y corriendo. En la pendiente, detente, gira y haz un ataque corto. Repite subiendo y bajando. | Que el pie apoyado no atraviese ni flote sobre el suelo; que el pie levantado conserve su movimiento; que las rodillas no tiemblen ni den saltos visibles. |
| [ ] | 2. Inclinación del cuerpo | Cruza la rampa despacio, corre, gira y ataca sobre ella. | Que el cuerpo acompañe la pendiente sin inclinar la cápsula ni sentirse torcido al salir de la rampa. |
| [ ] | 3. Guardia al terminar una esquiva | Haz una esquiva y pulsa y suelta guardia justo antes de que termine. Prueba hacia delante, atrás y a los lados; con y sin fijar al enemigo. | Que entre en guardia al recuperar el control y que la suelte sola si ya soltaste el botón. |
| [ ] | 1. Final del paso rápido | Haz pasos rápidos en las cuatro direcciones y suelta el movimiento durante el final; repite cerca de la rampa. | Que el personaje frene sin invertir la dirección y puedas volver a moverte enseguida. |

**Resultado para anotar:** paso probado, dirección, con/sin fijación, qué se sintió bien y qué se vio raro. Si algo falla, describe el momento (por ejemplo: «al bajar la rampa, el pie derecho flota cuando giro»). No hace falta usar términos técnicos.

**Pruebas automáticas ya ejecutadas:** `movement_test.tscn` y `combat_test.tscn`; ambas terminaron en `TODO OK`. Para repetirlas, los comandos están en `06_ARQUITECTURA_TECNICA.md`. Estas pruebas verifican reglas y números; no reemplazan las comprobaciones visuales de esta lista.
## Forma de trabajo: TDD

Para cada ajuste medible, primero añadimos una prueba que falla por el comportamiento que queremos corregir; luego cambiamos el juego hasta que pase. Al terminar, ejecutamos las pruebas relacionadas que ya existen. La sensación visual y de control sigue necesitando tu prueba manual en Godot.

## Pasos siguientes

1. **Esquiva y salida:** ajustar el frenado y la recuperación para que el personaje pueda volver a moverse o defenderse con claridad, sin perder la sensación de peso. Revisar cada dirección con y sin objetivo fijado.
2. **Transiciones de locomoción:** afinar la mezcla entre quieto, caminar, correr, movimiento lateral y movimiento hacia atrás, sobre todo con objetivo fijado.
3. **Ataques y recuperación:** revisar preparación, impacto, seguimiento y regreso a guardia. Mantener sincronizados el daño y el contacto visual del arma.
4. **Reacciones y variedad:** valorar variaciones pequeñas en tajos, bloqueos y golpes recibidos, preservando avisos legibles y controles consistentes.

## Criterios para cada paso

- El mando responde de forma inmediata y predecible.
- El personaje mantiene peso sin sentirse pegajoso o rígido.
- La animación comunica el movimiento y el momento del impacto.
- La esquiva no cambia de dirección por un salto de fotograma.
- El rendimiento se mantiene dentro del objetivo del proyecto: 1080p y al menos 45 FPS en el PC previsto.
- Los cambios respetan la guía de contenido y usan las animaciones ya incluidas en el proyecto.

## Registro

| Paso | Estado | Notas |
|---|---|---|
| 1. Cierre estable del paso rápido | Implementado; falta prueba del jugador | Distancia medida: 3,60 m |
| 2. Inclinación visual en rampas | Implementado; falta prueba del jugador | Prueba automatizada: alineación 1,000 |
| 3. Guardar la guardia al salir de la esquiva | Implementado; falta prueba del jugador | Prueba automática: guardia breve entra y se libera sola |
| 4. Apoyo individual de los pies | Implementado; falta prueba del jugador | Prueba automática: modificador activo y contacto en rampa de 20° |
| 5. Cuerpo de espaldas | Corregido | Prueba: cuerpo mira hacia donde avanza (1,00) |
| 6. Patada lanzaba lejos | Corregido | Empujón medido: 0,93 m |
| 7. Pies flotando en rampa | Corregido; falta prueba del jugador | Tobillo a 10,7 cm, pie levantado respetado |
| 8. Transiciones de locomoción | Pendiente | |
| 9. Ataques y reacciones | Pendiente | |
