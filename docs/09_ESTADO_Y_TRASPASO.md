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
| 4 · Pulido del combate II (opciones) | 🔨 Repertorio de 9 movimientos. Ataques peligrosos (barrido, estocada, agarre) y pisotón hechos (OK del jugador). Faltan más técnicas, armas secundarias, voces |
| 5–9 | Pendientes (IA lista, loop souls, historia, primer jefe, vertical slice) |

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
| LB+RB / K+J | Técnica "Torbellino" (dos tajos) |
| Y / F | Patada: rompe la guardia |
| B mantenido + RB | Ataque a la carrera |
| RB al final del paso | Contraataque tras esquiva |
| A + RB / Espacio + J | Ataque en salto |
| LB / K | Guardia / desvío |
| B / Shift | Paso rápido / correr |
| R3 / Tab | Fijar objetivo |
| A en el aire junto al enemigo | Pisotón (daña su postura; interrumpe el barrido) |
| B hacia el enemigo ante una estocada | Pisar la hoja (mucha postura, queda expuesto) |

- **Ataques peligrosos** (aviso rojo: destello rojo en el filo, "!" rojo sobre la cabeza y sonido grave; no se
  pueden bloquear ni desviar): **barrido** (saltar), **estocada** (pisar la hoja con paso hacia él, o esquivar a un
  lado), **agarre** (esquivar o saltar). Datos en `enemies/states/attack.gd`; tipos en `HitData.Kind`.
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
| Pruebas (ejecutar SIEMPRE tras cambios) | `--headless --path . res://tests/movement_test.tscn` · `combat_test.tscn` · `moveset_test.tscn` · `camera_test.tscn` · `danger_test.tscn` |
| Regenerar biblioteca de animaciones | `--headless --path . --script res://tests/build_anim_library.gd` |
| Medir impactos (mano / pie) | `--script res://tests/measure_swings.gd` · `measure_feet.gd` |
| Verificar el taller de animación | `--script res://tests/polish_check.gd` |
| Capturas (con ventana) | `res://tests/visual_check.tscn -- <carpeta>` · `polish_preview.tscn` · `anim_preview.tscn` · `ramp_shot.tscn` |
| Medir pies | `res://tests/feet_probe.tscn` (con ventana) |
| Regenerar escenario / sonidos | `python tools/gen_test_level.py` · `python tools/gen_sounds.py` (desde `G:\Game`) |

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
