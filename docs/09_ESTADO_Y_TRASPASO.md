# 09 · Estado del proyecto y traspaso

Resumen para retomar el trabajo en una sesión nueva. **Leer primero esto**, después
[00_LEEME](00_LEEME.md), [05_ROADMAP](05_ROADMAP.md) y [08_MEJORAS](08_MEJORAS_FLUIDEZ_Y_ANIMACION.md).

Última actualización: 2026-11-08 · Último commit: `d9767af` (los commits `01277a8`, `f6c4768` y `d9767af` aún
no están subidos a GitHub; subir solo cuando el jugador lo diga) · Repositorio público:
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
| 5 · IA inteligente y enemigos | ✅ **OK del jugador: Hito 5 cerrado.** IA que lee al jugador, pelea en grupo con turnos, patrulla y sigilo, bandido, lancero y arquero, grupo mixto. Caminar agachado fabricado a partir de caminar (sin descargas) |
| 6 · El loop souls | ✅ **OK del jugador: Hito 6 cerrado.** Paso 1 (vendajes) hecho y probado (OK). Paso 2 (campamento) hecho y probado (OK). Paso 3 (experiencia y morral) hecho y probado (OK). Paso 4 (atributos) hecho y probado (OK). Paso 5 (guardado) hecho y probado (OK). Paso 6 (menú de pausa) hecho y probado (OK) |
| 7 · Historia | ✅ **OK del jugador: Hito 7 cerrado.** Paso 1 (guion, `docs/11_GUION.md`) escrito y aprobado (OK); decisiones D18–D21 tomadas. Paso 2 (textos del narrador) hecho y probado (OK). Paso 3 (descripciones de objetos e inventario) hecho y probado (OK). Paso 4 (escena del prólogo) hecho y probado (OK) |
| 8 · Primer jefe | ✅ **OK del jugador: Hito 8 cerrado.** Paso 1 (arena, rastrillo, barra de jefa y 2 golpes mortales) hecho y probado (OK). Pasos 2–3 (repertorio acrobático, cuchillos, fase 2 y voz propia) hechos y probados (OK). Paso 4 (reacciones a los golpes, escena previa, música, estandarte) hecho y probado (OK) |
| 9 · Vertical slice | Paso 1 (plan, `docs/12_PLAN_PASO_DE_HIERRO.md`) aprobado (OK). Paso 2 (prólogo nuevo) hecho (el jugador siguió adelante). Paso 3 (nivel en bloques, `scenes/levels/iron_pass.tscn`, escena principal) hecho y corregido tras la primera prueba, **pendiente de la segunda prueba y OK del jugador**. Faltan pasos 4 (aldeanos), 5 (Bram), 6 (menú y `.exe`) y 7 (arte) |
| Extra · Frank | Paso 1 (Frank, la red y su escena) hecho y probado (OK). Paso 2 (consejos y bromas) hecho y probado (OK). Paso 3 (avisos, escondites y la despensa) hecho y probado (OK). Paso 4 (fruta para distraer) hecho y probado (OK). **Frank completo** para el juego actual |

**Prioridad del jugador (D14):** combate y movimiento pulidos y variados → historia → diseño de personajes.
El mundo: **El Paso de Hierro en bloques** (`scenes/levels/iron_pass.tscn`, escena principal; todo se construye
en `iron_pass_layout.gd`, el primer nodo, antes que Kael). El patio de pruebas (`test_level.tscn`) sigue para las
pruebas automáticas. El guardado anota el nivel: una partida de otro nivel no se carga.

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
| Cruceta ↓ / G | Frank lanza una fruta (distrae; recarga 40 s) |
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
| X / R | Vendarse (cura 45 %; quieto y sin guardia 1,4 s; 3 vendajes) |
| Y / E junto a la fogata | Descansar (sin enemigos que te vean cerca) |
| Start / Esc | Pausa: continuar, controles, empezar de nuevo, salir |
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
- **Tipos de enemigo** (grupo "Tipo" en Enemy): `moveset`, `danger_moveset`, `danger_ratio`, `idle_wait`,
  `evade_chance`, `damage_scale`; la mente usa ese repertorio (`EnemyMind.configure`). Cada tipo es una escena que
  hereda de `training_soldier.tscn` y cambia esos valores, la vida, la postura y el color. **Bandido**
  (`bandit.tscn`): ataques `quick`, `flurry` (3 tajos), `lunge` (embestida: avanza hasta 1,4 m durante la
  preparación), `double`; peligrosos barrido y agarre. Esquiva (`states/evade.gd`): ve empezar tu ataque a ≤3,2 m,
  reacciona en 0,1 s, salta 2,4 m atrás o en diagonal sin que le alcancen los golpes los primeros 0,22 s, y la
  mitad de las veces embiste después. Círculo del bandido en el escenario (x=12, z=34). Se prueba en `enemy_types_test`.
  **Lancero** (`spearman.tscn`): `Mannequin.weapon = SPEAR` (lanza montada en código sobre la espada), golpe que
  llega más lejos (Hitbox más larga, `strike_distance` 2,5, `attack_range` 3,3), `spear_thrust`, `spear_swing`,
  `thrust_combo`; peligrosos estocada y barrido; `keep_away_range` 1,9: si te pegas, `Evade` hacia atrás y
  estocada (cada 2,5 s como mucho). Círculo en x=-12, z=34.
  **Arquero** (`archer.tscn`): `weapon = BOW` (arco en la mano izquierda, orientado con `BOW_GRIP` medido con
  `tests/bow_probe.gd`), pose de guardia `bow_aim`, `ranged`, `can_block = false`. Estado `Shoot`: tensa 0,95 s,
  apunta 0,6 s con destello, suelta una `Arrow` (`weapons/arrow.gd`, 26 m/s, se bloquea/desvía como un tajo; si
  estás invulnerable pasa de largo). No usa los turnos de Squad para disparar. Retrocede caminando si estás a
  <5 m; a <2,2 m, patada (`kick_push`). Campo con muro en z=50. Animaciones Longbow renombradas:
  `bow_draw`, `bow_aim`, `bow_shoot`, `bow_walk_back` (esta aún sin usar).
  En grupo, el arquero pide turno a Squad como los demás (lo tiene mientras tensa y apunta; lo suelta al
  disparar), así nunca coinciden su flecha y un tajo. Zona "GRUPO MIXTO" (x=34, z=46). `group_test` sección 4.
  Rendimiento con 9 enemigos en el escenario: 60 FPS con vsync, 223 sin él (`tests/perf_probe.tscn`).
- **Vendajes** (Player `max_bandages` 3, `bandage_heal_ratio` 0,45, señal `bandages_changed`; estado
  `player/states/heal.gd`): 1,4 s quieto y sin guardia, cura a los 0,9 s; golpe antes = no cura ni gasta;
  paso rápido para cancelar desde 1,05 s. Se reponen en `respawn()`. HUD "X Vendajes ×N" encima de la técnica.
  Sonido `bandage` (gen_sounds.py). Castigo de la IA: `Enemy._watch_player_heal()` (≤7 m, alerta, no
  predecible, nadie más atacando): toma el turno y lanza `lunge`/`quick`, o `Shoot` si es arquero.
  Animación provisional `heal` = `idle_4` (0,9→2,3 s). Se prueba en `heal_test`.
- **Campamento** (`scenes/props/campfire.gd`, `class_name Campfire`, grupo `campfires`; piezas en código:
  piedras, leños, conos de llama, luz que titila, tienda, petate, sonido `fire` en bucle). Autoload `Camps`
  (`scripts/systems/camps.gd`): `fade_to(alpha, s, texto)` y `reset_world()` (borra flechas, `Enemy.reset_to_post()`
  en todos, `Squad.reset()`). Estado `player/states/rest.gd` (3,6 s: oscurece 0,5→1,3; repone a 1,4 con
  `Campfire.rest()` = `Player.restore()` + `set_spawn()` + `reset_world()`; aclara 2,6→3,5). `Player.wants_rest()`
  va antes de la patada en `ground.gd` (ambas en Y). Muerte (`player/states/dead.gd`): fundido 2,6→3,4,
  `respawn()` + `reset_world()`. `Enemy.respawn_delay` ahora vale 0 por defecto (no reaparecen solos).
  Se prueba en `campfire_test`; capturas con `campfire_shot`.
- **Experiencia** (Player `xp` con señal `xp_changed(total, delta)`, `gain_xp`, `drop_xp`, `recover_xp`;
  `Enemy.xp_reward`, se da en `enemies/states/dead.gd`). Al morir (`player/states/dead.gd` → `drop_xp()`) se
  borra el morral anterior y, si lleva algo, aparece un `XpSatchel` (`scenes/props/xp_satchel.gd`, grupo
  `xp_satchels`) en el suelo donde cayó (`_last_floor_position` si murió en el aire). Se recoge al pasar a
  ≤1,3 m (sonido `pickup`). HUD: `xp_text()`, "+N" que se desvanece. Se prueba en `xp_test`; capturas `xp_shot`.
- **Atributos** (`scripts/components/attributes.gd`, `class_name Attributes`, hijo del Player creado en código;
  `to_dict`/`from_dict` listos para el guardado). `Player.raise_attribute()` cobra y llama a `apply_attributes()`
  (vida/postura máximas); `Player.make_hit()` aplica Fuerza y Destreza (lo usa `player/states/attack.gd`).
  Menú `scenes/ui/level_menu.gd` (`LevelMenu`, grupo `level_menu`, lo crea `Camps` y vive en `Camps.level_menu`):
  botones con foco (ui_up/ui_down/ui_accept), `ui_cancel` cierra. `rest.gd` lo abre al aclararse la pantalla y
  no termina hasta que se cierra; la cámara no gira con el menú abierto. Las pruebas que descansan cierran el
  menú con `Camps.level_menu.close()`. Se prueba en `attributes_test`; captura `level_menu_shot`.
- **Guardado** (autoload `SaveGame`, `scripts/systems/save_game.gd`; JSON en `user://save.json`): guarda xp,
  atributos, `spawn` [x, y, z, grados] y el morral. Llamadas a `SaveGame.save(player)` en `Campfire.rest()`,
  `Player.raise_attribute()`, `Player.drop_xp()` (al morir) y `Player.recover_xp()`. Carga en
  `SaveGame.on_player_ready()` (diferido desde `Player._ready`). Solo actúa si la escena actual es la
  principal (`active()`), así las pruebas que cargan el nivel no tocan la partida; `save_test` usa
  `path = "user://save_test.json"` y `force_active = true`. Para empezar de cero: borrar ese archivo.
- **Historia** (`scripts/systems/story.gd`, autoload `Story`): `act` (1–4) y narraciones ya oídas.
  `Story.narrate(&"story_x")` hace hablar al anciano una sola vez por partida; `Story.death_event()` da las
  frases de muerte del acto. Se guarda en `save.json` ("story") y se reinicia en `on_player_ready`. Zonas
  `NarrationZone` (`scenes/props/narration_zone.gd`, Area3D con `event`, `size` y `act` opcional) en el
  nivel bajo el nodo `Narration`. Frases en `VoiceLines` (narrador, eventos `story_*` y `player_death_N`);
  tras cambiarlas: exportar el guion y `gen_voices.py`. Prueba `story_test`.
- **Jefes** (`Enemy.boss`, `Enemy.deathblows`): `deathblows_left`; un golpe mortal que no es el último pasa
  al estado `Rally` (de rodillas, invulnerable 2,4 s, se rehace con vida y postura llenas) y emite
  `phase_changed`; `phase()` da la fase. Un jefe vencido no vuelve con `reset_to_post`. Barra `BossBar`
  (`scenes/ui/boss_bar.gd`); el HUD no pone panel flotante a los jefes.
- **Arena de Varga** (`scenes/levels/varga_arena.gd`, `VargaArena`, grupo "arenas", en el nivel en x = 84):
  todo en código (suelo, muros, torre del rastrillo, niebla en capas, braseros, campamento a la entrada).
  `DuelTrigger` → `start_fight()` (baja el rastrillo `AnimatableBody3D`, `aggro_range` 60, barra, narración
  `story_varga_before`). `Camps.reset_world()` llama a `reset_arena()`. Al caer: `Story` "boss_varga" (se
  guarda), rastrillo arriba, narración `story_varga_after`. Varga: `scenes/enemies/varga.tscn` (hereda del
  soldado). Prueba `varga_test`; capturas `tests/arena_shot` y `tests/varga_shot`.
- **Varga, repertorio y fases**: patrones `varga_*` en `EnemyAttackState.PATTERNS` con claves nuevas:
  `leap` (salta hacia ti y cae en el impacto), `hop` (salto atrás), `throw: N` (lanza N cuchillos en abanico
  en vez de tajar; `ThrowingKnife`, `scenes/weapons/knife.gd`, hereda de `Arrow`), `no_hit`. En `Enemy`:
  `voice` (personaje de voz), `evade_counters`, `counter_pattern`, `ranged_patterns` + `ranged_cooldown`
  (los usa `Chase` a 4,5–14 m). La fase 2 la aplica la arena (`VargaArena.PHASE_2`) al recibir
  `phase_changed`, y vuelve a la fase 1 en `reset_arena()`.
- **Reacciones a los golpes**: `PlayerHitstun.strength_of(daño, peligroso o hit.heavy)` → LIGHT/MEDIUM/HEAVY
  (umbrales 18 y 34 de daño); cada fuerza con su empujón, frenado (`BRAKE`), duración y animación; por la
  espalda no se gira. `HitData.heavy` lo ponen los ataques `leap`. Enemigos: fuera de `Attack`/`Broken`/`Rally`
  reciben `push` y `play_reaction` (hit/hit_light). Prueba `hit_react_test`.
- **Invulnerable ≠ sin cuerpo**: `Enemy.set_vulnerable(false)` quita la zona de golpes y pone `collision_layer`
  a 0 (Kael lo atraviesa), pero mantiene la colisión con el suelo. Si un enemigo cae 20 m bajo su puesto,
  vuelve a él (`FALL_LIMIT`).
- **Pausa y escenas**: el menú de pausa quita su pausa 0,08 s después de cerrarse; no lo hace si hay una
  escena en el grupo "cutscene" (si no, tras "Empezar de nuevo" el prólogo corría con el juego en marcha).
  El soldado de práctica junto al inicio tiene `aggro_range` 6 (no ataca nada más aparecer).
- **Escenas en el nivel**: base común `LevelCutscene` (`scenes/cutscenes/level_cutscene.gd`): bandas negras,
  cámara propia, HUD oculto, subtítulos propios, mantener A la salta, Kael en `Scripted`. Cada escena escribe
  `_begin()`, `_run()` (guion con `await _line(...)` / `_wait(...)`, que devuelven false si se saltó) y `_end()`
  (también al saltarla: dejarlo todo como al terminar). `VargaIntro` (`varga_intro.gd`): Varga también en
  `Scripted` (el del enemigo acepta `walk_velocity`); la lanza la arena la primera vez (`Story` "scene_varga").
  `FrankMeet` (`frank_meet.gd`): la escena de la red. Capturas `tests/varga_intro_shot`, `tests/frank_shot`.
- **Frank, el tití** (`scenes/companions/frank.gd`, `Frank`): lo crea `Player._ready` (`player.frank`), oculto.
  Modos HIDDEN / TRAPPED (sigue a la red) / GROUND / RUNNING / HOPPING / PERCHED (en el hombro: sigue al hueso
  `mixamorig_LeftArm` vía `Mannequin.bone_attachment()`, un poco hacia el cuello). Poses IDLE, CLING,
  COVER_EYES, POINT, SAD, TOUCH_CURLS. `say(evento)` = `Voice.say(&"frank", …)`. Se recoloca con
  `Story.changed` (partida nueva o cargada): `Story` "frank_met" (va con Kael) y "frank_freed" (Kael lo soltó).
  **La red** (`scenes/props/frank_snare.gd`, `FrankSnare`, en test_level junto al inicio): pide ayuda a menos de
  11 m; "Y  Soltar al tití" a menos de 2,3 m lanza `FrankMeet`; si Kael lo vio y se aleja 26 m, Frank se
  suelta solo y lo alcanza corriendo (ofendido). Chillidos: `tools/gen_frank.py` (lee `tools/voice_lines.json`;
  líneas `{id, chirp, es}` o `{id, chirp, effort}`); `gen_voices.py` salta a Frank. Prueba `frank_test`.
- **Consejos y bromas de Frank** (`scenes/companions/frank_advisor.gd`, `FrankAdvisor`, hijo de Frank:
  `frank.advisor`): escucha `state_machine.state_changed` (Heal, Rest, Dead → Ground), `bandages_changed`,
  `posture.broken` y `Voice.spoken` (kael/deathblow, narrator/story_pass_*, varga/death). Solo habla si
  Frank está PERCHED y no hay escena. `is_quiet()` (duelo con jefe activo o 25 s tras la muerte de Varga)
  calla bromas y parloteo, no pistas. Pistas por `Enemy.display_name` (`HINTS`); `respawn_event(killer,
  muertes)`. Al reaparecer espera a que calle el anciano. `frank.gesture(pose, segundos)`. Prueba
  `frank_tips_test`.
- **Avisos y hallazgos de Frank** (paso 3): `FrankAdvisor` escucha el `state_changed` de cada enemigo
  (Shoot contra Kael → warn_archer; Chase con el enemigo a la espalda de la cámara, `is_behind()` → warn_behind;
  Suspicious → warn_suspicious) y busca escondites a `HiddenCache.FIND_RANGE`. `frank.point_at(punto, s)`:
  pose POINT, se gira en el hombro hacia el objetivo. **Escondites** (`scenes/props/hidden_cache.gd`,
  `HiddenCache`: `cache_id`, `reward_xp`, `reward_item`; Story "cache_<id>"). **Puerta con pestillo**
  (`scenes/props/latched_gate.gd`, `LatchedGate`: `gate_id`, Story "gate_<id>"; puerta en el lado -Z local, que
  en el escenario mira hacia el inicio; la puerta es un `AnimatableBody3D` con `sync_to_physics = false`
  para que su colisión siga a la bisagra). Objeto clave nuevo `poacher_note`. Prueba `frank_finds_test`;
  capturas `tests/frank_finds_shot`.
- **Fruta de Frank** (paso 4; `scenes/companions/frank_throw.gd`, `FrankThrow`, `frank.thrower`; acción
  `frank_throw` = cruz abajo / G): `pick_target()` (fijado, o el más centrado delante de la cámara a 16 m o
  menos), `throw_at()` lanza `FrankFruit` (`scenes/weapons/fruit.gd`, arco sin colisiones) y al llegar:
  desprevenido → `Suspicious` hacia donde cayó (3 m detrás, al otro lado de Kael); alerta → `Dazed`
  {"seconds": 1.4} (el estado Dazed acepta ahora la duración); jefe → solo `flinch`. `cooldown_left` (40 s);
  el HUD lo muestra (`frank_text()`). `thrower.distracted` evita que Frank además avise «ha oído algo».
  En plena pelea la fruta sigue el hueso de la cabeza (`bone_attachment("mixamorig_Head")`) en el vuelo.
- **Que Frank no agobie**: `Frank.CHATTY` (comentarios de charla) + `chat_gap` (30 s mínimo entre dos; las
  pruebas lo ponen a 0). Avisos, pistas y escenas no esperan. `VoiceLines.VOLUME_DB` (Frank −7 dB).
  Chillidos: `tools/gen_frank.py` con `PITCH` 0,62 y `SOFT_CUTOFF` 3,8 kHz (`--all` para rehacerlos).
  Prueba `frank_throw_test`.
- **Enemigos intocables** (`Enemy.set_vulnerable(false)`, al rehacerse o al morir): capa de cuerpo 0 y máscara
  solo `WORLD_LAYER` (1): ni Kael choca con ellos ni ellos con Kael (antes un jefe podía quedarse de pie sobre
  él).
- **Música** (`tools/gen_music.py` → `assets/audio/music/varga_duel_1/2.wav`, bucles de 40 s a 96 ppm): la
  arena la pone en bucle (`AudioStreamWAV.LOOP_FORWARD`), cambia de pista en la fase 2 en el mismo punto
  del compás y la apaga al reiniciar o al vencer.
- **Escena del prólogo** (`scenes/cutscenes/prologue_scene.gd`, `PrologueScene`, CanvasLayer capa 70, grupo
  "cutscene"): mundo 3D propio (SubViewport `own_world_3d`) con dos decorados hechos en código (fogata en el
  origen, sala del Regente en x = 200), maniquíes quietos (`Mannequin.Weapon.NONE`, `ribbon`), cámara con
  acercamientos lentos, subtítulos propios y fundidos. Espera cada frase con `Voice.last_seconds`. La lanza
  `Story.start_if_new()` (diferido desde `Player._ready`) solo si es la escena principal y no se vio
  (`scene_prologue` en `Story`); pausa el árbol; al terminar quita la pausa y guarda. Mantener A / Start 1 s
  la salta; el menú de pausa no se abre durante una escena. El Regente es un "narrador" (voz no posicional)
  en `VoiceLines.NARRATORS`. Prueba `prologue_test`; capturas `tests/prologue_shot`.
  **Versión 2** (Hito 9, paso 2; guion "Un buen hombre"): salón con luz dorada y música cálida
  (`assets/audio/music/prologue_hall.wav` en bucle; `prologue_sting.wav`, la nota que no cuadra, en el título;
  ambas de `tools/gen_music.py`). Planos: fire, hall, regent (baja del estrado: "Levántate"), memory (decorados
  en x = 400: mercado con Lira de niña y Kael chico; habitación con la cama vacía y una tela gris en la puerta;
  tinte cálido con viñeta `_tint`, sol `_memory_sun`), kael, map (mesa con cinco fichas que se encienden al
  nombrarlas, `TOKENS`), choice, ribbon, title. **Elección** (`_choose()`, cruz/stick para cambiar, A para
  elegir; `choose(i)` para pruebas): `vow` = &"stop" / &"end", guardado en `Story` como "vow_stop" / "vow_end".
  Voz nueva **Lira** (`bf_emma`, aguda; narradora). El Regente, con menos eco y tono normal.
- **Descripciones de objetos** (`scripts/systems/item_lore.gd`, `ItemLore`): `ITEMS` (nombre, tipo, texto) y
  `ORDER`; `owned(player)` = siempre espada/cinta/vendaje + armas secundarias + técnicas desbloqueadas +
  `Player.key_items` (objetos clave, guardados en `save.json`). Se ven en Pausa → Inventario. Al añadir un arma,
  técnica u objeto: escribir su descripción (la prueba `lore_test` lo exige y revisa la guía de contenido).
- **Menú de pausa** (`scenes/ui/pause_menu.gd`, `PauseMenu`, lo crea `Camps` en `Camps.pause_menu`, capa 58,
  `PROCESS_MODE_ALWAYS`): `get_tree().paused`; páginas main/controls/confirm con botones con foco. Esc es
  "pause" y "ui_cancel" a la vez: primero vuelve atrás, en la principal cierra. Al cerrar, la pausa se quita
  0,08 s después (para que la A de "Continuar" no haga saltar). "Empezar de nuevo" = `SaveGame.erase()` +
  `reload_current_scene()` (en pruebas `reload_on_restart = false` y se mira `restart_count`). La lista de
  controles está en `PauseMenu.CONTROLS`: **actualizarla al añadir controles**. Prueba `pause_test`;
  capturas `pause_shot`.
- **Caminar agachado**: la mezcla `crouch_loco` del maniquí usa `crouch_idle` (crouching_3) y `crouch_fwd/back/left/right`.
  No hay FBX de caminar agachado: `build_anim_library.gd` los fabrica a partir de los de caminar de pie
  (`FALLBACK`) con el taller `AnimPolish` (`hips_drop` 0,36 m + `spine_pitch` 20°: rodillas dobladas con los
  pies en su sitio y tronco inclinado). Capturas: `tests/crouch_shot`. Si algún día se descargan los de Mixamo,
  quitar esos retoques de `POLISH` y medir `CROUCH_SPEEDS`.
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
├── scripts/systems/     input_setup (controles por código), combat_fx, sfx, squad, camps
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
| Pruebas (ejecutar SIEMPRE tras cambios) | `--headless --path . res://tests/movement_test.tscn` · `combat_test.tscn` · `moveset_test.tscn` · `camera_test.tscn` · `danger_test.tscn` · `tools_test.tscn` · `arts_test.tscn` · `voice_test.tscn` · `ai_test.tscn` · `group_test.tscn` · `stealth_test.tscn` · `enemy_types_test.tscn` · `heal_test.tscn` · `campfire_test.tscn` · `xp_test.tscn` · `attributes_test.tscn` · `save_test.tscn` · `pause_test.tscn` · `story_test.tscn` · `lore_test.tscn` · `prologue_test.tscn` · `varga_test.tscn` · `hit_react_test.tscn` · `frank_test.tscn` · `frank_tips_test.tscn` · `frank_finds_test.tscn` · `frank_throw_test.tscn` · `iron_pass_test.tscn` (el nivel: piezas, enemigos sobre suelo firme, se llega a pie a cada zona, farolillos, atajo y su puerta) · `combo_settle_test.tscn` (el soldado baja el arma tras su último golpe; la guardia corta el ataque de Kael y desvía) · `anim_audit.tscn` (con `--fixed-fps 60`) |
| Regenerar biblioteca de animaciones | `--headless --path . --script res://tests/build_anim_library.gd` |
| Medir impactos (mano / pie) | `--script res://tests/measure_swings.gd` · `measure_feet.gd` |
| Verificar el taller de animación | `--script res://tests/polish_check.gd` |
| Capturas (con ventana) | `res://tests/visual_check.tscn -- <carpeta>` · `polish_preview.tscn` · `anim_preview.tscn` · `ramp_shot.tscn` · `iron_pass_shot.tscn` (el Paso de Hierro desde 8 sitios y el mapa desde arriba) |
| Medir pies | `res://tests/feet_probe.tscn` (con ventana) |
| Regenerar escenario / sonidos | `python tools/gen_test_level.py` · `python tools/gen_sounds.py` (desde `G:\Game`) |
| Voces (tras cambiar `voice_lines.gd`) | `--headless --path . --script res://tests/export_voice_script.gd` y luego, desde `G:\Game`: `G:\Herramientas	tsenv\Scripts\python tools/gen_voices.py` (`--all` rehace todas) |

Mixamo en un PC nuevo: ver [06_ARQUITECTURA_TECNICA](06_ARQUITECTURA_TECNICA.md) § Animaciones.
Archivos usados: Great Sword Pack + One/Two Hand Sword Combo + Sword Fight One + 4 Standing Dodge
(Y Bot, FBX Binary, With Skin, 30 fps), renombrados en minúsculas en `assets/animations/mixamo/`.

## 5. Lecciones aprendidas (evitan horas de depuración)

- **Enemigos colocados girados en el nivel**: el modelo gira *dentro* del cuerpo, así que `Enemy.face_direction`
  pasa la dirección del mundo a la del cuerpo. Sin eso, un enemigo puesto con 180° te da la espalda al pelear
  (pasó con lancero, arquero, bandido y guardias). Lo comprueba `enemy_types_test` (sección 9).
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

- **Nivel construido en código**: los bordes de cajas que se tocan deben solaparse un poco; si una caja acaba
  justo donde empieza otra (la meseta y la rampa, el patio de Varga), un rayo hacia abajo en ese borde no toca
  nada y queda una "grieta". `iron_pass_test` lo detecta (búsqueda a pie por una rejilla de 1 m, con la rampa y el
  suelo de debajo como sitios distintos).

- **Clips de Mixamo con varios tajos** (`combo_one_hand`, `combo_two_hand`): si un patrón acaba a mitad del
  clip, el clip sigue hacia el tajo siguiente y parece un golpe más que nunca llega. Anotar dónde empieza cada
  tajo en `EnemyAttackState.CLIP_STRIKES`.
- **Mando o teclado**: `InputSetup.using_pad` cambia con lo último que se tocó (señal `device_changed`); los textos
  con botones usan `InputSetup.label(acción)`. Las pruebas usan InputEventAction, que no cambia el aparato.

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

### Para retomar en una conversación nueva (2026-11-08)

**Actualización 2026-11-09 (cierre del paso 3, plan del estudio):**
- **Tutorial nuevo**: soldado de práctica a ritmo fijo, solo con golpes normales; luego el soldado del barrido,
  que solo hace barridos rojos; el bandido pasa al escondite del bosque. Carteles nuevos: patada y agacharse.
- **Avisos de las primeras veces** (`TutorialHints`, lo crea el HUD: `hud.hints`).
- **Fogatas**: la 2.ª está en el campamento de los cazadores; `VargaArena.with_campfire = false` en el Paso.
- **Pose de aguantar la espada** en lo alto (`EnemyAttackState`: `HOLD_RISE`, `HOLD_EARLIEST`, `HOLD_CREEP`
  0,005; prueba `hold_pose_test`).
- `Camps.reset_world()` también borra los proyectiles de Kael y la fruta de Frank.
- Pruebas nuevas: `tutorial_hints`, `hold_pose`, `save_iron_pass` y `respawn_clean`.
- **Ejecutor nuevo**: `bash game/tests/run_all.sh` (todas, 4 a la vez, ≈ 4,5 min, termina con "N/N OK";
  encuentra solas las pruebas `*_test.tscn`). `run_all.sh rapido` lanza 6 pruebas en unos 30 s, y
  `run_all.sh ai save` solo esas dos.
- **FPS del Paso** medidos con `perf_probe.tscn -- iron_pass`: la peor zona, la aldea, da 82 FPS (ver doc 01).
- Alcance congelado de la slice y lista de cambios: doc 12, §7–8. Lista de comprobación del paso 3 para
  probar con F5: doc 15, sección A.
- **Falta**: la prueba del jugador con F5 y su OK → commit. Después, los Cimientos (doc 15, B).

**Paso 6a, `.exe` de prueba (2026-11-11, en curso):**
- **Música de fondo** en el Paso (`Ambience`): `pass_explore.wav`, muy suave, y la capa `pass_tension.wav`, que
  entra cuando un enemigo cercano te descubre (`in_danger()`) y siempre en el mismo punto del compás. Calla en el
  duelo con un jefe. Las dos salen de `tools/gen_music.py`.
- **Menú principal** (`scenes/ui/main_menu.tscn`, `MainMenu`): ahora es la escena con la que arranca el juego
  (F5). Tiene Continuar (si hay partida), Partida nueva (si ya hay una, pide confirmar y la borra) y Salir, y
  muestra la versión. La pausa no se abre en el menú. **`GameInfo`** guarda `VERSION` (subirla en cada `.exe`),
  `GAME_SCENE` y `MENU_SCENE`. `SaveGame.active()` y `Story.should_play_prologue()` comparan con
  `GAME_SCENE`, no con la escena principal. Prueba `main_menu_test`.
- **Registro de errores** en el `.exe` (`debug/file_logging`): se guarda en `user://logs` (en Windows,
  `%APPDATA%\Godotpp_userdata\Hierro y Ceniza\logs`).
- **Exportación**: `game/export_presets.cfg` (Windows, todo en un `.exe`, sin las pruebas) → `build/HierroYCeniza.exe`
  (fuera de Git). **El `.exe` ya se exporta** (2026-11-11). Las plantillas oficiales de 4.7.2 (solo las de Windows) están en
  `G:\Herramientas\Godot\templates` (no en C:) y el preset las usa como `custom_template`. Para exportar, desde
  `G:\Game\game`: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows"
  ../build/HierroYCeniza.exe` (unos 143 MB). `build/LEEME.txt` es la hoja para los probadores y
  `docs/17_FALLOS.md`, el registro de fallos. El `.exe` no acepta una escena por la línea de órdenes: siempre
  empieza en el menú.
- **Releases de GitHub** (con el OK del jugador, 2026-11-11): la v0.9.4 está publicada como versión de prueba
  (pre-release) con el `.exe` y `LEEME_como_jugar.txt`:
  https://github.com/gonzalolavin99/hierro-y-ceniza/releases/tag/v0.9.4. Por cada `.exe` nuevo: subir
  `GameInfo.VERSION` y `application/*_version` del preset, exportar y `gh release create vX.Y.Z --prerelease`.
  descargarlas de godotengine.org, así que antes hace falta el permiso del jugador.

**Cimientos (2026-11-11, doc 15 B):**
- **Canales de sonido** (`game/default_bus_layout.tres`, `AudioMix`): Musica, Voz, Efectos y Ambiente. `Voice`
  baja la música y el ambiente 6 dB mientras alguien habla (`_update_duck`). `Sfx` usa un reproductor libre y
  nunca repite la misma variante dos veces seguidas.
- **Ambiente del Paso** (`scenes/levels/ambience.gd`, `Ambience`; sonidos de `tools/gen_ambient.py`): viento en
  bucle, que sopla más arriba; el arroyo junto al sendero del atajo (con una franja de agua de vista); pájaros
  lejanos cada 5–13 s, que callan en la fortaleza y en el duelo con un jefe. Prueba `audio_mix_test`.
- **Enemigos que duermen** (`Squad.update_sleep`, `Enemy.set_asleep/can_sleep`): en el Paso de Hierro
  (`Squad.sleep_distance` = 40 m), los enemigos tranquilos y lejanos se quedan con `PROCESS_MODE_DISABLED`.
  F3 muestra "Enemigos activos". La peor zona pasa de 82 a 129 FPS. Prueba `enemy_sleep_test`.
- **Esqueleto común** (`scripts/components/bones.gd`, clase `Bones`; "BoneMap" ya lo usa Godot): el código pide
  `Bones.name(&"Hips")` o `Bones.path(&"Hips")`. "mixamorig" solo aparece en esa tabla.
- **Guía de estilo** (`docs/16_GUIA_DE_ESTILO.md`) y su paleta (`StylePalette`); escena de prueba
  `tests/style_probe.tscn -- <carpeta>` (capturas en `docs/estilo/`). **Falta el OK del jugador.**
- **Pendiente de los Cimientos**: el cuerpo base CC0 (Quaternius) para sustituir al Y Bot. Hay que descargarlo,
  así que antes hace falta el permiso del jugador.
- Lección: `--headless --editor --quit` (para importar archivos nuevos) a veces se queda colgado; usar
  siempre `timeout 120` delante.

**Arreglos tras la 2.ª prueba del jugador (2026-11-11):**
- **La cámara ya no se mete en los muros**: el SpringArm tiene una esfera de 0,3 m (`camera_probe`). Kael no
  atravesaba la roca: `walls_test` lo empuja contra las paredes del camino de 50 maneras.
- **Escenas en el nivel**: `LevelCutscene.clear_view()` adelanta la cámara si hay un muro entre ella y lo que se
  mira. El rincón de la red de Frank es más grande (x 5,5–14, z 94–104) y la red cuelga en (10, 0, 99).
- **Soltar a Frank**: Y / E ya no da una patada junto a algo con lo que se puede interactuar
  (`Player.interaction_nearby()`, grupo "interactables", `offers_interaction()` en la red, las puertas y los
  escondites). En la escena, Kael levanta la espada y corta la cuerda (`slash_a` con `play_shaped`).
- **Golpe por la espalda**: si un enemigo desprevenido tiene a Kael a su espalda a distancia de remate, sale la
  marca roja ◆ sobre él (`hud._find_exposed_enemy`), y las 3 primeras ocasiones un aviso (`TutorialHints`
  "stealth").
- **Bram**: el cartel del lazareto dice claro que aún no está hecho (paso 5) y que se sigue hacia Varga.
- **Varga, conversación ampliada** (doc 11): 4 frases nuevas (`intro_1b`, `intro_2b`, `kael_scene varga_1b`,
  `varga_1c`), con la voz de Kokoro. Kael cree que ella deja morir a la gente, y su hermana murió de la fiebre.
- **Nadie se queda encima de otro**: `Enemy._slide_off_player()` y `Player._slide_off_enemy()`. Si uno queda
  apoyado en el otro, deja de chocar con él 0,35 s y resbala hacia fuera (`stack_test`).
- Las rampas de las torres entran 0,4 m en la torre (había una "grieta" en el borde).
- 36/36 pruebas OK (nuevas: `walls`, `stack`).

**Dónde quedamos (antes):** Hito 9, **paso 3** (nivel en bloques del Paso de Hierro) hecho, con los arreglos de la
primera prueba del jugador: la guardia corta cualquier ataque de Kael (no las técnicas), los soldados ya no
amagan un tercer golpe, los carteles muestran solo los botones del aparato en uso, farolillos y sendero que
guían, y la puerta atrancada del atajo en la aldea. Las 30 pruebas pasan (`bash game/tests/run_all.sh`, ≈ 12 min; al añadir una prueba nueva, sumarla a su lista).
**Falta:** que el jugador lo pruebe con F5 y dé el OK → entonces **commit** (nada de esto está en Git aún:
nivel nuevo, `combo_settle_test`, cambios en `attack.gd`, `input_setup.gd`, `latched_gate.gd`,
`save_game.gd`, etc.). El paso 2 (prólogo nuevo) ya está en `d9767af`; el jugador siguió adelante sin
objeciones.

**Pasos que faltan del Hito 9** (detalle en `05_ROADMAP.md` y `12_PLAN_PASO_DE_HIERRO.md`):
1. **Paso 4 — la gente de la aldea** (el siguiente): aldeanos con frases sutiles que hagan sospechar lo que
   pasa de verdad; los soldados de la aldea son **de Varga y guardan la cuarentena** (Kael cree que son
   rebeldes): primero avisan ("¡Atrás! No te acerques a las casas") y solo luego atacan; el desertor. Quitar
   el cartel provisional "(Aldeanos: paso 4)".
2. **Paso 5 — Bram**, gigante de unos 3 m (hueco ya preparado en el lazareto de la fortaleza).
3. **Paso 6 — menú principal, opciones** (gráficos, sangre, subtítulos) **y exportar el `.exe`**.
4. **Paso 7 — arte**: estilo, Kael, enemigos, jefes, Frank (mejorar su modelo), iluminación; vestir el nivel.

**Pendiente de decidir por el jugador:** ¿se mantiene la revelación final "Yo fui ese guerrero"? (ver
memoria del narrador: siempre en tercera persona hasta entonces). Pulido fino de audio y diálogo, más
adelante.

**Referencia:** los puestos de un estudio de videojuegos y quién cubre cada uno aquí están en
[13_EQUIPO_DE_UN_ESTUDIO](13_EQUIPO_DE_UN_ESTUDIO.md). La revisión de un experto por departamento
(2026-11-09: notas, problemas y recomendaciones) está en [14_REVISION_DEL_ESTUDIO](14_REVISION_DEL_ESTUDIO.md), y el plan por hito que propusieron
(**aprobado por el jugador el 2026-11-09**; el orden ya está en el roadmap) en [15_PLAN_DEL_ESTUDIO](15_PLAN_DEL_ESTUDIO.md).
Orden: cierre del paso 3 → Cimientos → `.exe` de prueba (6a) → aldeanos (4) → Bram (5) → menú completo (6b) →
arte en partes (7) → prueba final → Hitos 10–13. **El juego no se va a
vender** (proyecto personal): no se planifica marketing ni localización.
Arreglos de 2026-11-09: guardado v2 seguro (`.tmp` + `.bak`, migración, validación), técnicas bloqueadas en el
nivel real (`start_with_all_arts = false`; las técnicas se guardan) y retrasos de la IA fijos por ataque
(`EnemyAttackState.HOLDS`; la racha cuenta ataques, `EnemyMind.begin_attack`).

### Historial

1. **Hito 7 — historia**: borrador del guion en `docs/11_GUION.md` (OK del jugador; decisiones D18–D21 tomadas). Textos del narrador hechos (OK). Descripciones de objetos hechas (OK). Escena del prólogo hecha (OK). **Hito 7 cerrado.**
   **Hito 8** (Capitana Varga) empezado: ver `05_ROADMAP.md`. Hechos repertorio, fase 2 y voz (OK). Pulido de Varga hecho (OK). **Hito 8 cerrado.** Frank, paso 1 (crearlo, la red y su escena) hecho y probado (OK); paso 2 (consejos y bromas) hecho y probado (OK); paso 3 (avisos y hallazgos) hecho y probado (OK); paso 4 (fruta para distraer) hecho y probado (OK). Con él, Frank queda completo para el juego actual (guion §12; la carta y el registro llegarán con sus zonas).
2. **Ajustes tras la prueba del jugador (2026-11-05)**, con su OK: A / B del mando en los menús
   (`InputSetup._pad`: Godot no los trae en `ui_accept` / `ui_cancel`), pisotón más exigente (1,6 m, de cara
   al enemigo), la guardia corta los tajos ligeros en cualquier momento salvo en el impacto
   (`Attack.FREE_GUARD`), estocada del lancero apuntada y estirada a mano (`Mannequin.set_spear_thrust`,
   alcance 2,8 m = su zona de daño; captura `tests/spear_shot`), recuperación de 0,36 s tras el paso rápido
   (encadenar pasos ya no supera el trote; correr = mantener B sin soltar) y caminar agachado de verdad.
   Esquiva = **voltereta** (pedido del jugador): con dirección rueda hacia allí (se gira, también fijado),
   3,6 m en 0,68 s, invulnerable 0,36 s, recuperación 0,12 s; si venía corriendo usa la de carrera. Sin
   dirección, paso atrás. FBX descargados por el jugador: `roll_stand.fbx` ("Stand To Roll", tramo 0,85–2,0 s)
   y `roll_sprint.fbx` ("Sprinting Forward Roll", 0,45–1,17 s). Capturas: `tests/roll_shot`.
3. Pulido fino de audio y diálogo (volúmenes, mezcla, variedad), pedido por el jugador para más adelante.
