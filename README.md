# Hierro y Ceniza

Un souls-like de acción en tercera persona, con combate inspirado en **Sekiro**: postura, desvío y golpe mortal.
Sin magia ni elementos sobrenaturales: un reino medieval-feudal destrozado por la guerra y la peste,
contado por la voz de un anciano que quizá no sea tan inocente como parece.

> 🚧 En desarrollo. Por ahora el mundo es de bloques y los personajes son provisionales: el arte llega al final del Hito 9.

## Estado

| Hito | Estado |
|---|---|
| 0 · Preparación | ✅ |
| 1 · Movimiento (paso rápido, correr, salto, cámara) | ✅ |
| 2 · Combate básico (combo, guardia, desvío, golpe mortal) | ✅ |
| 3 · Pulido del combate I: sensación | ✅ |
| 4 · Pulido del combate II: opciones (9 movimientos, técnicas, armas secundarias, voces) | ✅ |
| 5 · IA inteligente y enemigos | ✅ |
| 6 · El loop souls (vendajes, fogatas, experiencia, atributos, guardado) | ✅ |
| 7 · Historia | ✅ |
| 8 · Primer jefe | ✅ |
| Extra · Frank, el tití (compañero) | ✅ |
| 9 · Vertical slice «El Paso de Hierro»: pasos 1–3 y 6a (menú principal y `.exe`) hechos; paso 4 en curso | 🔨 |

Plan completo en [docs/05_ROADMAP.md](docs/05_ROADMAP.md).

## Probarlo

**Sin instalar nada:** descargar `HierroYCeniza.exe` (Windows) de la versión de prueba más reciente en
[Releases](https://github.com/gonzalolavin99/hierro-y-ceniza/releases); trae un `LEEME_como_jugar.txt`.

**Desde el código:**
1. Instalar [Godot 4.7](https://godotengine.org) (versión estándar).
2. Abrir `game/project.godot` y pulsar **F5**.
3. Las animaciones de Mixamo no están en el repositorio (su licencia no permite redistribuirlas): ver
   [docs/06](docs/06_ARQUITECTURA_TECNICA.md) § Animaciones.

Se juega con mando de Xbox o con teclado (tabla de botones en
[docs/09](docs/09_ESTADO_Y_TRASPASO.md) § 2).

## Documentación

- [Índice de toda la documentación](docs/00_LEEME.md)
- [Diseño del juego](docs/03_GDD.md)
- [Guía de contenido](docs/04_GUIA_DE_CONTENIDO.md)
- [Arquitectura técnica](docs/06_ARQUITECTURA_TECNICA.md)

## Créditos

Ver [CREDITOS.md](CREDITOS.md). Los efectos, el ambiente, la música y los chillidos de Frank se generan por síntesis con scripts propios (`tools/`); las voces, en local con Kokoro.

© 2026 Gonzalo Lavín. Todos los derechos reservados.
