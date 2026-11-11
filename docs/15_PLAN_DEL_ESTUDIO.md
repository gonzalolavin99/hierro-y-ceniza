# 15 · Plan del estudio por hito (propuesta, 2026-11-09)

Después de la revisión ([14_REVISION_DEL_ESTUDIO](14_REVISION_DEL_ESTUDIO.md)), cada experto (dirección,
diseño, programación, arte, animación, audio y QA) dijo qué hay que hacer en cada hito desde su área, en qué
orden y cuándo se considera **hecho**. Este documento junta sus siete planes en uno solo. No hay plan de
marketing ni de localización porque el juego no se va a vender.

**Estado: aprobado por el jugador (2026-11-09)**. El orden ya está en el [05_ROADMAP](05_ROADMAP.md).

---

## El orden en una línea

**Cerrar el paso 3 → Cimientos → `.exe` de prueba → Aldeanos (4) → Bram (5) → Menú completo (6) → Arte en
partes (7) → Prueba final → Hitos 10–13.**

¿Por qué este orden? Hay tres ideas en las que coinciden casi todos:
1. **Que alguien de fuera lo juegue pronto** (dirección, diseño, QA y programación). El `.exe` se adelanta: no
   tiene que esperar al final.
2. **Primero los "cimientos" y luego el contenido** (animación, audio, arte y programación). Si los aldeanos y
   Bram se hacen con el esqueleto de Mixamo y sin canales de sonido, habrá que rehacerlos.
3. **El arte deja de ser un único paso gigante al final.** El estilo se decide ya y el resto se divide en 7 partes.

---

## A · Cerrar el paso 3 (nivel en bloques)

| Área | Tareas |
|---|---|
| Dirección | Guardar en Git todo lo pendiente cuando el jugador dé el OK. Dejar por escrito la lista de lo que **entra / no entra** en la vertical slice; cualquier idea nueva va a "después" |
| Diseño | **Tutorial nuevo**: una idea por tramo y un enemigo por idea. Un 2.º soldado que solo hace el barrido rojo ("¡ROJO! No se para → SALTA"). El aviso "◆ GOLPE MORTAL" aparece al romper la postura. El cartel de curarse sale la primera vez que Kael está herido. El bandido pasa al bosque. **Avisos la primera vez** que se ve cada ataque rojo |
| Diseño | **Ritmo**: la fogata 2 pasa al campamento de los cazadores (bosque) y se **quita la de la entrada de Varga**. Así el atajo es la vuelta rápida a Varga |
| Animación | La pose de "aguantar la espada" de los retrasos fijos (`HOLDS`) se hace en el punto más alto de la preparación, con la espada quieta |
| Programación | Medir los FPS **en el Paso de Hierro** (hoy solo se mide en el patio de pruebas) y anotarlos como cifras de partida. Nuevo ejecutor de pruebas: las encuentra solo, ejecuta 4 a la vez, termina con "N/N OK" y tiene modo rápido y completo |
| QA | Pruebas nuevas: `save_iron_pass_test` (atajo, escondite, Varga y elección → guardar, cargar y que siga igual) y `respawn_clean_test` (morir agachado, en el aire, con una bomba en vuelo o en pleno duelo, sin que quede nada colgado). Además, una lista de comprobación a mano para F5 (abajo) |

**Hecho cuando:**
- ningún tramo entre fogatas tiene más de 8 enemigos obligatorios;
- con el atajo abierto se vuelve de la fogata 1 a Varga en ≤ 45 s;
- cada movimiento tiene su cartel o aviso antes de necesitarlo;
- las pruebas dicen "N/N OK" en ≤ 5 min;
- los FPS del nivel están anotados en `01_EVALUACION_PC.md`;
- el jugador da el OK → commit.

**Lista a mano (F5) del paso 3:**
- [ ] Del inicio a Varga sin atascarse.
- [ ] Saltar contra muros y esquinas.
- [ ] Morir en la aldea, en el bosque y en la fortaleza.
- [ ] Abrir el atajo, cerrar el juego y comprobar que sigue abierto.
- [ ] Alt+F4 justo al descansar: la partida sigue ahí.
- [ ] 10 min con mando y 10 con teclado.
- [ ] F3: mínimo 45 FPS en la aldea.

## B · Cimientos (no se ven, pero evitan rehacer cosas)

| Área | Tareas | Hecho cuando |
|---|---|---|
| Animación + programación | **Esqueleto común**: una sola tabla de nombres de huesos (`BoneMap`) en lugar de `mixamorig_` escrito a mano en 16 archivos. La cadera fija solo en los clips de "paso real" | `mixamorig` solo aparece en el archivo de importación; todas las pruebas y `anim_audit` igual que antes |
| Audio | **Canales de mezcla**: Música, Voz, Efectos y Ambiente. La música baja cuando alguien habla. Los reproductores ya no cortan sonidos que siguen sonando. Nunca se repite la misma variante dos veces seguidas | Una prueba comprueba los canales y que la música baja con la voz |
| Programación | **Dormir enemigos**: los que están a más de ~40 m dejan de pensar y de animarse | En F3 solo trabajan los cercanos; 60 FPS en la aldea |
| Arte | **Guía de estilo** (`docs/16_GUIA_DE_ESTILO.md`): paleta de unos 12 colores (pizarra y ceniza, más rojo óxido, naranja y azul acero), personajes tapados (yelmos, capuchas), límites de polígonos y aspecto de cada zona. Una **escena de prueba** con 5 objetos y un personaje | El jugador ve 3 capturas y da el OK al estilo |
| Arte + animación | Elegir un **cuerpo base CC0** (Quaternius) para sustituir al Y Bot y decidir las siluetas de Kael y Bram | Kael con el cuerpo nuevo pasa todas las pruebas sin deformarse |

## C · `.exe` de prueba (paso 6a, adelantado)

- **Programación:** un menú mínimo (Jugar / Continuar / Salir), exportación a Windows, un registro de errores
  en un archivo y el número de versión visible. Comprobar que el `.exe` incluye las animaciones.
- **Dirección y QA:** 3–5 amigos o familiares lo juegan mientras se hace el paso 4. Se les mira jugar **sin
  ayudar**, con una hoja de 5 preguntas: ¿dónde te perdiste?, ¿qué no entendiste?, ¿dónde moriste?, ¿qué te
  gustó?, ¿se rompió algo? Los fallos se apuntan en un registro (`docs/17_FALLOS.md`).
- Si alguien juega con teclado, antes hay que añadir el **ratón para la cámara**.
- **Hecho cuando:** 3 personas lo han jugado y los 3 problemas más repetidos están arreglados.

## D · Paso 4: la gente de la aldea (lo que más cuenta la historia)

| Área | Tareas |
|---|---|
| Diseño / guion | 5–8 aldeanos con **dos versiones** de sus frases (antes y después de Varga). Soldados que avisan: "¡Atrás! No te acerques a las casas", 3 s en guardia, y solo atacan si Kael se acerca o golpea. **Desertor**: suelta la espada y se arrodilla; si Kael se va, más tarde se le ve llevando agua. La carta de raciones. La elección del prólogo cambia cómo reaccionan |
| Programación | Un bus de eventos (`Events`) para que la historia, Frank y los escondites no dependan unos de otros. Una lista de todas las marcas de la historia, con una prueba. El estado "avisar" y un aldeano sencillo |
| Animación | Gestos cotidianos: barrer, sentarse, mirar a lo lejos, tapar los ojos a una niña, el "¡atrás!" del soldado, el desertor arrodillado. La cabeza mira a Kael (como mucho 60°) |
| Audio | 6–10 voces de aldeanos (Kokoro, bajas y cansadas), murmullo de aldea y el grito de alerta. Si Kael perdona al desertor, **silencio** |
| QA | El aviso del soldado vuelve a empezar al morir o descansar; nadie bloquea el camino; las frases se dicen una sola vez y pasan la guía de contenido |

**Hecho cuando:**
- se puede cruzar la aldea sin matar a nadie;
- el desertor aparece con el agua;
- desaparece el cartel provisional;
- un amigo, cuando se le pregunta "¿quién es el malo?", duda.

## E · Paso 5: Bram (gigante de 3 m)

| Área | Tareas |
|---|---|
| Programación | **Antes de Bram**, los ataques pasan a archivos de datos (`AttackPattern.tres`, `EnemyProfile.tres`), primero los del soldado y los de Varga. Una base común `BossArena` para los jefes (rastrillo, música, fases). Ajustes de tamaño: zona de golpes, colisión y cámara que se aleja al fijarlo |
| Diseño | Golpes amplios y lentos que **se esquivan mejor que se paran** (bloquearlos castiga mucho la postura; desviarlos sí funciona). La cadena barre en círculo (rojo: salta). El grillete le sirve para agarrar. Queda expuesto cuando falla un golpe contra el suelo. Un solo golpe mortal. **Da el Golpe de Martillo** (dirección y diseño coinciden) y la llave |
| Animación | El mismo esqueleto, escalado. Se reproduce a ~0,7 de velocidad y con preparaciones 1,5–2 veces más largas. 6–8 animaciones propias (pisotón, barrido con la cadena, agarre, golpe vertical, giro, tambaleo, caída y golpe mortal). Polvo y temblor al pisar |
| Audio | Pasos graves que se oyen antes de verlo, la cadena (tintineo, arrastre, latigazo), voz grave y música de 2 fases |
| QA | No atraviesa muros; la cámara no se mete en su cuerpo ni en la pared; vencido, no vuelve |

**Hecho cuando:**
- `attack.gd` ya no contiene datos de jefes;
- Bram se vence en **2–6 intentos** aprendiendo (es un mini-jefe);
- el jugador lo describe como "lento y pesado", no como "un humano grande";
- da el Martillo.

## F · Paso 6b: menú y opciones completos

Gráficos (sombras, SSAO, escala de resolución), sangre, subtítulos con tamaño y **volumen por canal**,
guardados en `user://settings.cfg` (también con copia de seguridad). La pausa se abre sola si se desconecta el
mando. Una prueba de que el `.exe` arranca bien.

**Hecho cuando:**
- cambiar una opción y reiniciar conserva el cambio;
- con la música a 0 no suena música;
- con calidad baja hay ≥ 45 FPS en la peor zona.

## G · Paso 7: arte, en partes (7a ya va en los Cimientos)

1. **7b Prueba de belleza**: vestir solo una esquina (la arena de Varga o un rincón de la aldea) para comprobar el estilo y los FPS.
2. **7c Kael**: el cambio es solo de malla, gracias al esqueleto común. La cinta de Lira se ve y se mueve con física sencilla. Reacciones nuevas: golpe recibido por dirección, caída y levantada, tambaleo, y giros de 0,1 s en vez de instantáneos.
3. **7d Enemigos, Varga y Bram**: cada tipo se reconoce **por su silueta a 15 m**.
4. **7e Frank**: un esqueleto de tití propio y unas 10 poses.
5. **7f Vestir el nivel por zonas** (aldea → bosque → fortaleza → patio) con kits CC0 recoloreados. Cada zona pasa a ser una escena aparte. Versiones simplificadas de lejos y ocultación tras muros. Menos de 1.000 llamadas de dibujo por zona.
6. **7g Iluminación y efectos**: sombras precalculadas, niebla de color distinto por zona y estela gris acero.
7. **Audio del 7**: cambiar los gritos hechos con voz sintética por sonidos CC0, acero CC0 mezclado con la síntesis, 4–5 variantes de cada choque y roce de la ropa.

**Hecho cuando:**
- ≥ 45 FPS en la peor zona;
- el aviso rojo se lee con cualquier luz;
- nadie confunde un enemigo con el escenario ni un efecto con magia.

## H · Prueba final del Hito 9

2 personas nuevas lo juegan de principio a fin **sin ayuda**, en 25–40 minutos.

## Hitos siguientes (propuestos para el roadmap)

| Hito | Contenido | Regla |
|---|---|---|
| **10 · Pulido de la slice** | Segunda ronda con gente de fuera, arreglos, documentos al día. Una versión "1.0 de la slice" marcada en Git | Sin fallos graves en el registro |
| **11 · Acto II: la Montaña Alta** | Ilse, Dov, el primer enemigo que se rinde, como mucho 2 tipos de enemigo nuevos (trampero, soldado con escudo) | Cada acto se hace como una slice propia: plan → bloques → prueba con amigos → gente → jefe → arte. **1 zona, 1 jefe y como mucho 1 mecánica nueva** |
| **12 · Acto III: la Ciudad del Río** | Orme, la carta del Regente, los pozos tapiados | Igual |
| **13 · Acto IV y los finales** | Aren, el registro, los dos finales y el epílogo | Antes, decidir "Yo fui ese guerrero" |

Cada región trae su paleta de colores y su "paleta sonora", y además su prueba de "se llega a pie", su prueba
de guardado y la prueba de su jefe. Dirección calcula unos 2–3 meses por acto. Si falta tiempo, se recorta a
3 actos antes que bajar la calidad.

---

## Lo que hay que decidir (el jugador)

1. ~~Aprobar este orden~~ (aprobado el 2026-11-09).
2. ~~Grabaciones caseras~~: **no se graba nada con el móvil** (decisión del jugador, 2026-11-09). Los gritos, el
   acero, la cadena y los pasos serán sintetizados o CC0 (Kenney, Freesound con filtro CC0, OpenGameArt CC0).
3. **Probadores**: ¿qué 3–5 amigos o familiares pueden jugarlo?
4. ~~Pájaros lejanos~~: **aprobado** (2026-11-09). Sonidos de fondo lejanos (pájaros, viento, río) en el
   ambiente; nunca como enemigos ni a la vista.
5. **La revelación final** "Yo fui ese guerrero" (pendiente desde antes; hace falta antes del Hito 13).

## Las tres primeras cosas (si se aprueba)

1. Tu segunda prueba del paso 3 con la lista F5 y, con tu OK, guardar todo en Git.
2. El tutorial y el ritmo nuevos (fogatas, atajo) y el ejecutor de pruebas rápido.
3. Escribir las frases de los aldeanos y del desertor para que las apruebes, y empezar la guía de estilo.
