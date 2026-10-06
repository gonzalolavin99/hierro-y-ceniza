# 06 · Arquitectura técnica

Referencia para mantener el código ordenado a medida que crece.

## Estructura de carpetas (proyecto Godot)

```
G:\Game\
├── CLAUDE.md                 ← contexto para Claude
├── CREDITOS.md               ← origen y licencia de cada asset
├── docs\                     ← estos documentos
└── game\                     ← proyecto Godot (project.godot aquí)
    ├── assets\
    │   ├── models\  animations\  textures\  audio\  fonts\
    ├── scenes\
    │   ├── player\  enemies\  bosses\  levels\  ui\  props\
    ├── scripts\
    │   ├── components\       ← piezas reutilizables (Health, Stamina, Posture, Hitbox, Hurtbox)
    │   ├── states\           ← máquinas de estados (jugador / IA)
    │   └── systems\          ← guardado, campamentos, progresión
    ├── data\                 ← armas, enemigos, objetos como .tres (Resources)
    └── tests\                ← escenas de prueba aisladas
```

## Principios

1. **Componentes** — vida, postura, hitbox/hurtbox son nodos reutilizables. El jugador y
   los enemigos usan los mismos.
2. **Máquinas de estados** — cada personaje es una FSM (Idle, Move, Attack, Dodge, Block, Stagger,
   Dead…). Las transiciones se deciden por estado, nunca con un `if` gigante.
3. **Datos separados del código** — el daño de una espada o la vida de un bandido viven en Resources
   (`.tres`), para poder ajustar balance sin tocar scripts.
4. **Señales (signals)** para comunicar sistemas (ej. `health.died` → HUD, sonido, experiencia).
5. **Autoloads** mínimos: `GameState` (progreso), `SaveSystem`, `Events` (bus de eventos), `Settings`.
6. **Escenas de prueba** por sistema (`tests/`) para probar una cosa aislada.

## Convenciones de código (GDScript)

- Tipado estático siempre (`var speed: float = 5.0`).
- `snake_case` variables/funciones, `PascalCase` clases/nodos, archivos en `snake_case`.
- Comentarios en español, breves.
- Valores ajustables con `@export` para tunearlos desde el editor.

## Rendimiento

- Contador de FPS/draw calls en modo debug desde el hito 0.
- LOD automático de Godot activado; occlusion culling en niveles grandes.
- Renderer: **Forward+**; si los FPS no llegan, probamos **Mobile** renderer.
- Revisar presupuesto de [01_EVALUACION_PC](01_EVALUACION_PC.md) en cada hito.

## Control de versiones

- Git en `G:\Game`. Un commit por cada cambio que apruebes (tu OK = commit).
- `.gitignore` de Godot (excluir `.godot/`). Assets binarios grandes → Git LFS si hace falta.

## Animaciones (Mixamo)

La licencia de Mixamo no permite publicar los archivos, así que **no están en el repositorio**.
Para regenerarlas en un equipo nuevo:

1. En mixamo.com: personaje **Y Bot** → pack **Great Sword Pack** → FBX Binary, With Skin, 30 fps.
2. Descomprimir en `game/assets/animations/mixamo/` con nombres en minúsculas y `_` (ver
   `tests/build_anim_library.gd`). Se descartan *casting*, *spell cast* y *power up* (guía de contenido).
3. `Godot --headless --path game --script res://tests/build_anim_library.gd` → crea `mixamo_library.res`.

El cuerpo animado es `scenes/characters/mannequin.tscn` (árbol de animación armado en código).

## Pruebas automáticas

Simulan el mando y comprueban que todo funciona. Se ejecutan tras cada cambio:

```
G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path game res://tests/movement_test.tscn
G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path game res://tests/combat_test.tscn
```

El escenario de pruebas se genera con `python tools/gen_test_level.py` (no editarlo a mano).
