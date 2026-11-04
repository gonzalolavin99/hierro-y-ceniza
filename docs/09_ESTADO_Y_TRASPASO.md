# 09 · Estado del proyecto y traspaso

Resumen para retomar el trabajo en una sesión nueva. **Leer primero esto**, después
[00_LEEME](00_LEEME.md), [05_ROADMAP](05_ROADMAP.md) y [08_MEJORAS](08_MEJORAS_FLUIDEZ_Y_ANIMACION.md).

Última actualización: 2026-10-20 · Último commit: `8636b93` · Repositorio público:
https://github.com/gonzalolavin99/hierro-y-ceniza

---

## 1. Dónde estamos

| Hito | Estado |
|---|---|
| 0 · Preparación | ✅ OK del jugador |
| 1 · Movimiento | ✅ OK del jugador |
| 2 · Combate básico | ✅ OK del jugador |
| 3 · Pulido del combate I (sensación) | ✅ OK del jugador (incluye cámara al fijar con vista por encima del hombro) |
| 4 · Pulido del combate II (opciones) | ✅ Repertorio de 9 movimientos. Ataques peligrosos (barrido, estocada, agarre) y pisotón hechos (OK del jugador). Armas secundarias hechas (OK del jugador). Técnicas Martillo y Ráfaga + desbloqueo y sistema de voces con subtítulos hechos (OK del jugador). Voces generadas en local con Kokoro. ✅ **OK del jugador: Hito 4 cerrado** (pulido fino de audio/diálogo, más adelante) |
| 5 · IA inteligente y enemigos | 🔨 Paso 1 (IA que lee al jugador) ✅ OK del jugador. Paso 2 (pelea en grupo) ✅ OK del jugador. Paso 3 (patrulla y sigilo) ✅ OK del jugador (faltan las animaciones de caminar agachado). Siguen: patrulla/sigilo, 3 tipos de enemigo |
| 6–9 | Pendientes (loop souls, historia, primer jefe, vertical slice) |

**Prioridad del jugador (D14):** combate y movimiento pulidos y variados → historia → diseño de personajes.
El mundo, por ahora, solo es el escenario de pruebas.

## 2. Lo que funciona hoy (F5 en Godot)

**Movimiento:** correr, paso rápido con invulnerabilidad (esquiva animada según la dirección), mantener B
para esprintar, salto con margen tras la cornisa ("coyote"), cámara con SpringArm, fijar objetivo (R3) y
cambiar de objetivo con el stick derecho.

**Combate estilo Sekiro:**
- Postura (sin aguante). Guardia y **desvío** con ventana de 0,2 s que se achica si se pulsa seguido
  (castigo acumulativo, se borra a los 0,5 s o al desviar). Golpe mortal al romper la postura.
- Repertorio (datos en `game/scenes/player/moves.gd`):

| Botón (mando / teclado) | Movimiento |
|---|---|
| RB ×3 / J | Combo ligero (tres tramos del combo a una mano) |
| RT / L | Golpe pesado |
| LB+RB / K+J | Técnica equipada: Torbellino, Golpe de Martillo o Ráfaga |
| Cruceta ↑ / 3 | Cambiar de técnica (solo las desbloqueadas) |
| Y / F | Patada: rompe la guardia |
| B mantenido + RB | Ataque a la carrera |
| RB al final del paso | Contraataque tras esquiva |
| A + RB / Espacio + J | Ataque en salto |
| LB / K | Guardia / desvío |
| B / Shift | Paso rápido / correr |
| R3 / Tab | Fijar objetivo |
| A en el aire junto al enemigo | Pisotón (daña su postura; interrumpe el barrido) |
| B hacia el enemigo ante una estocada | Pisar la hoja (mucha postura, queda expuesto) |
| LT / Q | Arma secundaria equipada |
| L3 / C | Agacharse (alterna): sigilo; por la espalda sin que te vean, ataque = golpe mortal |
| Cruceta ← → / 1, 2 | Cambiar de arma secundaria |

- **Ataques peligrosos** (aviso rojo: destello rojo en el filo, "!" rojo sobre la cabeza y sonido grave; no se
  pueden bloquear ni desviar): **barrido** (saltar), **estocada** (pisar la hoja con paso hacia él, o esquivar a un
  lado), **agarre** (esquivar o saltar). Datos en `enemies/states/attack.gd`; tipos en `HitData.Kind`.
- **Armas secundarias** (`player/tools.gd`, `weapons/`): ballesta de muñeca (10 virotes; un virote durante la
  preparación de un ataque lo interrumpe; en guardia lo bloquea), bomba de humo (3; aturde 2,6 s: ni ataca ni
  bloquea, estado `Dazed`), bomba de pólvora (3; 25 de daño y 35 de postura aunque esté en guardia, interrumpe;
  radio 2,8 m, también te daña si estás cerca). Se rellenan al reaparecer. HUD: arma y usos sobre la vida.
- **Técnicas** (`player/arts.gd`, datos en `moves.gd`): una equipada (LB+RB), cruceta ↑ cambia entre las
  desbloqueadas. Torbellino de serie; Golpe de Martillo y Ráfaga se desbloquean (en el escenario de pruebas,
  todas desde el inicio: `Player.start_with_all_arts`). La Ráfaga contra alguien en guardia provoca su contraataque.
- **Voces** (autoload `Voice`, líneas en `systems/voice_lines.gd`): esfuerzos de Kael y del soldado, frases del
  soldado (al verte, al ganarte) y del narrador al morir ("No… no fue así."), con subtítulos en español abajo al
  centro. Probabilidad y pausa por evento para no saturar; turnos para que no se pisen: cada personaje dice una
  cosa a la vez, como mucho 2 voces a la vez (gana la más importante, `EVENT_PRIORITY`) y el narrador calla al resto. Audios generados en local y gratis con **Kokoro**
  (licencia Apache 2.0) por `tools/gen_voices.py`: Kael `bm_daniel`, soldado `am_onyx`, anciano `bm_lewis`. Guion: docs/10.
- **IA que lee al jugador** (`enemies/enemy_mind.gd`): observa solo lo visible (desvíos, esquivas, guardia,
  ataques) y decide al empezar cada ataque. Desvías 3+ seguidos → retrasa golpes (espada arriba 0,25–0,5 s); 5+ →
  a veces amaga. Abusas del paso rápido → estocadas. Guardia 2 s+ → barridos y agarres. Atacas sin pausa →
  contraataca tras 2 bloqueos. Un golpe que te acierta borra la racha. F3 muestra "IA lee". Las pruebas que no
  tratan de la IA usan `mind.predictable = true` (ritmo fijo); la IA se prueba en `ai_test`.
- **Pelea en grupo** (autoload `Squad`, estado `enemies/states/circle.gd`): como en Sekiro ataca uno cada vez
  (el turno lo recibe quien más rato lleva esperando; 0,6 s de respiro entre enemigos distintos). Los demás
  esperan a 3,6 m con la guardia alta, se separan ≥75° entre ellos y rodean hacia tu espalda. Los tajos no
  hieren a compañeros. Si muere el fijado, se fija el siguiente. Arena de grupo en el escenario (x=32, 3 soldados).
  Con un solo enemigo nada cambia. Se prueba en `group_test`.
- **Sigilo** (Enemy `starts_unaware`, `patrol_points`; estados `patrol.gd` y `suspicious.gd`): sospecha 0→1 por
  vista (cono 120°, 15 m, rayo de ojos a pecho: agachado se esconde tras muros bajos; agachado cuesta más verte)
  y oído (`Player.noise_radius()`: quieto 0, agachado 1 m, andar 3, correr 6, esprintar 10, atacar 6). Solo el
  oído no pasa de 0,8 (hace falta verte, salvo a <2 m). 0,35 = "?" y va a mirar; 1 = "!" y alerta a los que
  estén a 12 m. Si te pierde 4 s, busca y vuelve a la ronda. Desprevenido no se cubre. Golpe mortal por sorpresa
  con el jugador a su espalda o costado (≤2,4 m). Agacharse: C / L3 (alterna). El soldado de práctica y los del
  grupo siguen empezando alerta. Patio de sigilo en x=-34 con 2 guardias. Se prueba en `stealth_test`;
  capturas con `tests/stealth_shot.tscn`.
- **Caminar agachado**: la mezcla `crouch_loco` del maniquí usa `crouch_idle` (crouching_3) y `crouch_fwd/back/left/right`.
  Faltan los FBX `crouch_walk_fwd/back/left/right` de Mixamo: hasta tenerlos, `build_anim_library.gd` usa los de
  caminar de pie (`FALLBACK`). Al añadirlos: reconstruir la biblioteca y medir `CROUCH_SPEEDS`.
- **Soldado de práctica:** se acerca en guardia, avisa con un destello en el filo y un "ting", 4 patrones
  normales y ~1 de cada 3 ataques peligroso,
  bloquea fuera de sus ataques, contraataca tras 3 bloqueos, retrocede si le desvían el último tajo, se
  arrodilla al romperse la postura, muere y reaparece (solo en pruebas).
- **Sensación:** hitstop, chispas, sangre mínima (configurable), temblor de cámara, estela del filo,
  reacciones según la dirección del golpe, choque de espadas que empuja a ambos.
- **Sonido:** 18 efectos sintetizados propios (desvío metálico con chirrido, bloqueo, impacto, tajos,
  postura rota, golpe mortal, destello). `tools/gen_sounds.py`.

**Animación:** maniquí Y Bot de Mixamo (cuerpo provisional, no es el diseño final de Kael) con 40
animaciones; mezcla de locomoción, guardia solo en el torso, acciones cruzadas, **paso real** (root motion)
con magnetismo de ataque, **ritmo de esgrima** (preparación lenta → impacto seco → peso), postura baja y
tajos que nacen de la cadera (taller `AnimPolish`), **apoyo de pies** con IK e inclinación en rampas.

**Rendimiento:** ~140–165 FPS en la GTX 1050 en el escenario de pruebas (objetivo mínimo: 45).

## 3. Cómo está construido (mapa rápido)

```
game/
├── scenes/characters/   mannequin.gd/.tscn (cuerpo animado, árbol de animación por código),
│                        foot_grounding.gd (apoyo de pies), sword_trail.gd (estela)
├── scenes/player/       player.gd, camera_rig.gd, moves.gd (repertorio), states/ (Ground, Sprint,
│                        Dash, Air, Attack, Block, Hitstun, Stagger, Deathblow, Dead)
├── scenes/enemies/      enemy.gd, training_soldier.tscn, states/ (Idle, Chase, Attack, Recoil, Broken, Dead)
├── scenes/ui/           hud (vida, postura, barras del enemigo, ◆ golpe mortal), debug_overlay (F3)
├── scripts/components/  health, posture, hitbox, hurtbox, hit_data
├── scripts/systems/     input_setup (controles por código), combat_fx, sfx
├── assets/audio/sfx/    sonidos generados
├── assets/animations/   mixamo/ (NO está en Git: licencia) + mixamo_library.res (generada)
└── tests/               pruebas automáticas y herramientas (ver §4)
tools/                   gen_test_level.py (escenario), gen_sounds.py, blender/ (experimental)
```

Autoloads: `InputSetup`, `DebugOverlay`, `CombatFX`, `Sfx`. Capas físicas: 1 mundo, 2 jugador,
3 enemigos, 4 hurtbox jugador, 5 hurtbox enemigos.

## 4. Herramientas y comandos

Godot: `G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe` (abrir el editor: `Abrir Godot.bat`).

| Para qué | Comando (desde `G:\Game\game`) |
|---|---|
| Pruebas (ejecutar SIEMPRE tras cambios) | `--headless --path . res://tests/movement_test.tscn` · `combat_test.tscn` · `moveset_test.tscn` · `camera_test.tscn` · `danger_test.tscn` · `tools_test.tscn` · `arts_test.tscn` · `voice_test.tscn` · `ai_test.tscn` · `group_test.tscn` · `stealth_test.tscn` · `anim_audit.tscn` (con `--fixed-fps 60`) |
| Regenerar biblioteca de animaciones | `--headless --path . --script res://tests/build_anim_library.gd` |
| Medir impactos (mano / pie) | `--script res://tests/measure_swings.gd` · `measure_feet.gd` |
| Verificar el taller de animación | `--script res://tests/polish_check.gd` |
| Capturas (con ventana) | `res://tests/visual_check.tscn -- <carpeta>` · `polish_preview.tscn` · `anim_preview.tscn` · `ramp_shot.tscn` |
| Medir pies | `res://tests/feet_probe.tscn` (con ventana) |
| Regenerar escenario / sonidos | `python tools/gen_test_level.py` · `python tools/gen_sounds.py` (desde `G:\Game`) |
| Voces (tras cambiar `voice_lines.gd`) | `--headless --path . --script res://tests/export_voice_script.gd` y luego, desde `G:\Game`: `G:\Herramientas	tsenv\Scripts\python tools/gen_voices.py` (`--all` rehace todas) |

Mixamo en un PC nuevo: ver [06_ARQUITECTURA_TECNICA](06_ARQUITECTURA_TECNICA.md) § Animaciones.
Archivos usados: Great Sword Pack + One/Two Hand Sword Combo + Sword Fight One + 4 Standing Dodge
(Y Bot, FBX Binary, With Skin, 30 fps), renombrados en minúsculas en `assets/animations/mixamo/`.

## 5. Lecciones aprendidas (evitan horas de depuración)

- **El modelo de Mixamo mira hacia +Z**; el nodo `YBot` está girado 180°. Cualquier código que cambie
  `_bot.basis` debe conservar ese giro (`_bot_facing`). Hay prueba automática.
- **Empujones (`push`)**: se suman solo al movimiento de cada fotograma y se restan después; si se
  acumulan en `velocity`, la patada lanza al rival 20 m. Hay prueba.
- **Pose de huesos con modificadores**: la pose ajustada (pies, IK) solo existe justo tras la señal
  `skeleton_updated`; leerla en otro momento da la pose sin ajustar.
- **Tobillo natural del Y Bot: 10,7 cm** sobre el suelo (`foot_grounding.gd`).
- **Blender cambia la orientación de los huesos al exportar FBX**: los retoques se hacen en Godot
  (`tests/anim_polish.gd`). Blender (`G:\Herramientas\Blender`) queda para modelado.
- **Hitstop**: se restaura midiendo tiempo real en `_process` (con temporizadores se quedaba en cámara lenta).
- Al editar archivos con scripts, **no abrir en modo escritura antes de leer** (se vaciaron archivos así).
- `class_name` nuevos: ejecutar una vez `--headless --editor --quit` para refrescar la caché de clases.
- Animaciones descartadas por la guía de contenido: *casting*, *spell cast*, *power up*.
- **Tiempo de juego ≠ tiempo real** en las pruebas sin ventana (0,7 s de juego ≈ 0,57 s reales). Las esperas y
  pausas del juego deben medirse en tiempo de juego (`delta`), nunca con `Time.get_ticks_msec()`.
- **Funciones anónimas de GDScript copian las variables locales**: `var n = 0; var f = func(): n += 1` nunca
  cambia `n` fuera. En pruebas, contar con variables de la clase.
- **Voz Kokoro**: las interjecciones con consonantes sueltas ("Hh!", "Nngh", "Hmph") se leen **deletreadas**
  ("eich-eich"). `gen_voices.py` lo detecta por los fonemas y se detiene. Usar "Hut!", "Huff!", "Ungh...", "Rah!".
- Entorno de voz: `G:\Herramientas	ts` (venv con `kokoro-onnx` + modelos `kokoro-v1.0.onnx` y `voices-v1.0.bin`,
  de github.com/thewh1teagle/kokoro-onnx, release model-files-v1.0). En un PC nuevo: crear el venv e instalar
  `kokoro-onnx soundfile`, y descargar esos dos archivos en `models/`.

## 6. Reglas del proyecto (resumen)

- El jugador no tiene experiencia: explicar en español simple. Él prueba y da OK; no se avanza de hito sin OK.
- **Contenido:** nada de magia, demonios, espíritus, no-muertos, brujería, ocultismo, "almas" ni deidades.
  **Solo enemigos humanos.** Sin mundo abierto (zonas conectadas que se desbloquean).
- Una sola dificultad: la IA debe ser lista, no tramposa. Jefes muy completos y distintos entre sí.
- Sonido: nunca audio extraído de otros juegos. Voces futuras: ElevenLabs (inglés + subtítulos ES).
- Git: commit tras cada OK, mensajes en español, **sin ninguna mención a asistentes de IA**, correo noreply
  de GitHub. Los archivos de instrucciones de los asistentes (`CLAUDE.md`, `AGENTS.md`) están excluidos del
  repositorio (`.git/info/exclude`). Mixamo nunca se sube (licencia).
- TDD: para cada ajuste medible, primero una prueba que falla; documentar en `08_MEJORAS`.

## 7. Siguiente paso recomendado

1. **Cerrar el Hito 3:** cámara al fijar objetivo (transición suave al fijar/soltar, encuadre que
   mantenga a ambos personajes en pantalla en peleas cercanas, que no atraviese al enemigo). Pedir OK.
2. **Hito 4 — ataques peligrosos (lo más "Sekiro" que falta):**
   - Aviso rojo: destello rojo sobre el enemigo + sonido grave (distinto del destello blanco normal).
   - **Barrido** → se esquiva saltando; saltar sobre el enemigo permite **pisotón** (daño de postura).
   - **Estocada** → contraataque especial (pisar la hoja con paso hacia delante en el momento justo).
   - **Agarre** → no se puede bloquear: alejarse o esquivar a un lado.
   - Con animaciones existentes (sweep_low, slash_b para estocada, shove para agarre) o nuevas de Mixamo.
3. Después: 1–2 técnicas más, armas secundarias (LT), voces con ElevenLabs, y el Hito 5 (IA lista).
