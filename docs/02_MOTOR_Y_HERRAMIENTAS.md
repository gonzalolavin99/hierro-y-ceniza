# 02 · Motor y herramientas

## Lo que hay que instalar (todo gratis)

| Herramienta | Para qué | Cuándo | Tamaño aprox. |
|---|---|---|---|
| **Godot 4.x** (última estable, versión *estándar*, no .NET) | El motor del juego | Hito 0 | ~150 MB |
| **Git** | Guardar historial del proyecto y poder deshacer cualquier error | Hito 0 | ~300 MB |
| **Blender** | Ajustar/importar modelos 3D (lo uso yo vía scripts; tú solo si quieres) | Hito 2 | ~1 GB |
| Cuenta Adobe (gratis) para **Mixamo** | Animaciones humanas (ataques, esquivas, caminar) | Hito 2 | — |

> La cuenta de Adobe la tienes que crear tú (yo no creo cuentas ni pongo contraseñas).

Todo se instala en `G:\Herramientas\` (o similar) para no llenar C:.

## Por qué Godot y GDScript

- **Lenguaje GDScript**: parecido a Python, fácil de leer aunque no sepas programar.
- **Escenas en texto** (`.tscn`): puedo crear personajes, niveles y menús escribiendo archivos.
- **Sin tiempos de compilación**: cambias algo y lo pruebas en 2 segundos (F5).
- **Licencia MIT**: el juego es 100% tuyo, sin regalías, puedes venderlo en Steam.
- **Exporta a Windows** con un clic.

## Fuentes de arte y sonido (gratis y con licencia segura)

| Fuente | Qué aporta | Licencia |
|---|---|---|
| Quaternius (quaternius.com) | Personajes, armas, naturaleza, castillos low-poly | CC0 (libre total) |
| KayKit (kaylousberg.itch.io) | Caballeros, mazmorras, armas | CC0 |
| Kenney (kenney.nl) | Props, UI, sonidos | CC0 |
| Mixamo | Animaciones de combate humanas | Gratis para juegos comerciales |
| Poly Haven | Texturas de suelo/roca/madera | CC0 |
| Freesound / Sonniss GDC bundles | Efectos de sonido (choque de espadas, pasos) | Revisar cada uno (CC0 preferido) |

Regla: **cada asset que entra queda anotado en `CREDITOS.md`** con su origen y licencia.
Todo asset se revisa contra la [guía de contenido](04_GUIA_DE_CONTENIDO.md) antes de usarlo
(muchos packs "fantasy" incluyen magos, calaveras ocultistas, runas, etc. → esos se descartan).

## Lo que NO vamos a usar (por ahora)

- Unreal Engine (demasiado pesado para la GTX 1050).
- Iluminación global en tiempo real (SDFGI/VoxelGI): cara en GPU.
- Generadores de arte por IA: calidad inconsistente para 3D animado; quizás para conceptos.
