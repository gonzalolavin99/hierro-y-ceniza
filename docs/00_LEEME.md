# 00 · Léeme — Índice y forma de trabajo

## Documentos

| Archivo | Contenido |
|---|---|
| [01_EVALUACION_PC](01_EVALUACION_PC.md) | ¿Puede tu PC? Presupuesto de rendimiento |
| [02_MOTOR_Y_HERRAMIENTAS](02_MOTOR_Y_HERRAMIENTAS.md) | Godot, Git, Blender, fuentes de assets |
| [03_GDD](03_GDD.md) | Diseño del juego: combate, progresión, enemigos, mundo |
| [04_GUIA_DE_CONTENIDO](04_GUIA_DE_CONTENIDO.md) | Qué evitamos (magia, demonios…) y con qué lo sustituimos |
| [05_ROADMAP](05_ROADMAP.md) | Hitos con pruebas y OKs |
| [06_ARQUITECTURA_TECNICA](06_ARQUITECTURA_TECNICA.md) | Estructura del código y convenciones |
| [07_DECISIONES_PENDIENTES](07_DECISIONES_PENDIENTES.md) | Lo que necesito que decidas |
| [08_MEJORAS_FLUIDEZ_Y_ANIMACION](08_MEJORAS_FLUIDEZ_Y_ANIMACION.md) | Pulido paso a paso: qué se cambió, cómo se midió y qué probar |
| [GLOSARIO](GLOSARIO.md) | Términos de desarrollo explicados |

## Cómo trabajamos

```
 Yo propongo / construyo  →  Tú pruebas (F5 en Godot)  →  OK  o  "cambia esto"
          ↑                                                      │
          └──────────────────────────────────────────────────────┘
```

1. **Yo** escribo código, escenas y configuración, y te explico en lenguaje simple qué hice.
2. **Tú** abres Godot, pulsas **F5** (o el botón ▶), juegas y me cuentas qué sientes.
   No necesitas saber programar: "la esquiva es muy lenta" o "no entiendo cuándo desviar"
   es exactamente el feedback que sirve.
3. Con tu **OK**, guardo el cambio en Git (punto de restauración).
4. Lo que yo no puedo hacer: crear cuentas (Adobe/Mixamo), y ver el juego en movimiento —
   para eso me describes lo que pasa o me pasas capturas/clips.

## Pruebas automáticas (TDD)

Cada mejora medible empieza con una prueba automática que reproduce el problema o fija el comportamiento esperado. Primero verificamos que falle; después hacemos el cambio y repetimos las pruebas relacionadas. Estas pruebas complementan tu revisión con F5: los números y las reglas se pueden automatizar, pero la sensación de movimiento y animación la validas tú. Los casos y resultados se anotan en `docs/08_MEJORAS_FLUIDEZ_Y_ANIMACION.md`.

## Reglas del proyecto

- No avanzamos de hito sin tu OK.
- Todo asset nuevo pasa la [guía de contenido](04_GUIA_DE_CONTENIDO.md).
- Primero que se **sienta bien** con cubos; el arte bonito va después.
