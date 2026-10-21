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

### Taller de animación (`tests/anim_polish.gd`)
Retoca las animaciones de Mixamo sobre sus datos, al construir la biblioteca
(`tests/build_anim_library.gd`, tabla `POLISH`):
- **hips_drop**: baja la cadera (postura más firme, estilo kenjutsu/Sekiro).
- **cut_emphasis**: en cada impacto la cadera y el pecho giran más hacia el tajo, con un contragiro
  previo (anticipación). El tajo "nace de la cadera".
- Las piernas se recalculan con **IK de dos huesos**: los pies quedan exactamente donde estaban.
- Verificación: `tests/polish_check.gd` (números) y `tests/polish_preview.tscn` (capturas antes/después).


### Apoyo de pies en rampas
`scenes/characters/foot_grounding.gd` implementa `FootGroundingModifier`, un `SkeletonModifier3D` que se procesa después de la mezcla de animación. Consulta el piso bajo cada tobillo y corrige solo los que están cerca; el cálculo IK de dos huesos conserva la flexión de la rodilla. No cambia la cápsula física. Hace dos rayos al suelo por personaje activo.

Prueba automatizada en `tests/movement_test.gd`: confirma que el modificador está activo y detecta la rampa de 20°. Ejecutar también `movement_test.tscn` y `combat_test.tscn` después de cambios del maniquí.
Además, en el juego: **paso real** (root motion) en ataques, **ritmo de esgrima** en cada tajo
(`Mannequin.play_shaped`: preparación lenta → impacto seco → peso) y **estela del filo**.

Nota: Blender (`G:\Herramientas\Blender`) cambia la orientación interna de los huesos al exportar FBX,
por eso los retoques se hacen dentro de Godot. Blender queda para modelado.

## Pruebas automáticas

Simulan el mando y comprueban que todo funciona. En los ajustes nuevos, primero se escribe una prueba que detecta el fallo o fija el comportamiento esperado; luego se implementa el cambio y se vuelven a ejecutar las pruebas relacionadas. La prueba automática mide reglas y números; la sensación de control y la lectura visual también requieren la prueba manual del jugador.


```
G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path game res://tests/movement_test.tscn
G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path game res://tests/combat_test.tscn
G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path game res://tests/moveset_test.tscn
G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path game res://tests/camera_test.tscn
G:\Herramientas\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path game res://tests/danger_test.tscn
```

`camera_test` y `danger_test` aceptan una carpeta (con ventana, sin `--headless`) para guardar capturas del encuadre:
`... --path game res://tests/camera_test.tscn -- <carpeta>`.

El escenario de pruebas se genera con `python tools/gen_test_level.py` (no editarlo a mano).
