# 01 · Evaluación del PC

Detectado automáticamente el 2026-10-06.

| Componente | Detalle | Veredicto |
|---|---|---|
| Equipo | HP Pavilion Gaming Laptop 15-dk0xxx | Portátil gamer de gama de entrada (2019) |
| CPU | Intel Core i5-9300H (4 núcleos / 8 hilos) | ✅ Suficiente |
| GPU dedicada | NVIDIA GeForce GTX 1050 (3 GB VRAM) | ⚠️ Es el límite: define el estilo gráfico |
| GPU integrada | Intel UHD 630 | ❌ No usar: hay que forzar la NVIDIA |
| RAM | 16 GB | ✅ Bien |
| Disco G: | SSD Kingston 1,9 TB, **303 GB libres** | ✅ Aquí va todo |
| Disco C: | SSD 256 GB, **solo 21 GB libres** | ⚠️ No instalar nada pesado aquí |
| Pantalla | 1920×1080 | — |

## Conclusión

**Sí, tu PC puede hacer este juego**, con dos condiciones:

1. **Motor ligero → Godot 4.** Unreal Engine 5 funcionaría a tirones en el editor con 3 GB de VRAM
   (Epic recomienda 8 GB) y cada compilación tardaría mucho. Unity iría, pero es más pesado y
   sus archivos de escena son más difíciles de editar desde texto. Godot pesa ~150 MB, abre en
   segundos, y casi todo en él es **texto plano**, lo que me permite a mí escribir y modificar
   el juego directamente.
2. **Estilo gráfico estilizado / low-poly, no fotorrealista.** Sekiro te corría bien porque
   FromSoftware tiene un equipo de 300 personas optimizando. Nosotros apuntamos a un estilo
   tipo *"Tunic / Death's Door / Elden Ring visto con menos polígonos"*: siluetas claras,
   colores fuertes, niebla y luz para el ambiente.

## Objetivos de rendimiento (presupuesto)

| Métrica | Objetivo |
|---|---|
| Resolución / FPS | 1080p a 60 FPS (mínimo aceptable: 45) |
| Triángulos en pantalla | < 500.000 |
| VRAM usada | < 2 GB |
| Texturas | 512–1024 px como norma, 2048 solo para jefes |
| Enemigos activos a la vez | ≤ 8 con IA completa |
| Iluminación | Luz direccional + sombras; sin SDFGI/VoxelGI al inicio |

Medimos FPS desde el primer prototipo (contador en pantalla), así que si algo se pasa del
presupuesto lo veremos al momento, no al final.

## Configuración obligatoria antes de empezar

- **Forzar la NVIDIA para Godot:** Configuración de Windows → Sistema → Pantalla → Gráficos →
  agregar `Godot.exe` → *Alto rendimiento*. (Si no, usa la Intel UHD y todo irá lento.)
- **Portátil enchufado** mientras se trabaja/prueba (la batería limita la GPU).
- **Todo en G:\\** — Godot, Blender y el proyecto. C: tiene muy poco espacio.
- Drivers NVIDIA al día (los actuales parecen recientes, OK).

## Mediciones del Paso de Hierro (cifras de partida antes del arte, 2026-11-09)

Medido con `Godot --path game res://tests/perf_probe.tscn -- iron_pass`: con ventana a 1920×1080 y **sin
vsync** (lo que da de sí la tarjeta), en la GTX 1050, con los 21 enemigos del nivel quietos. Al vestir el
nivel (paso 7) se vuelve a medir: si una zona baja más de un 10 %, hay que revisarla.

| Zona | FPS medio | Peor fotograma | Llamadas de dibujo | VRAM |
|---|---|---|---|---|
| Camino (tutorial) | 111 | 25 ms | 52 | 206 MB |
| Arco → aldea | 88 | 32 ms | 279 | 206 MB |
| **Aldea (centro)** | **82** (la peor) | 36 ms | 374 | 206 MB |
| Bosque | 111 | 40 ms | 535 | 206 MB |
| Pie de la rampa | 114 | 26 ms | 622 | 206 MB |
| Fortaleza (patio) | 107 | 22 ms | 640 | 206 MB |
| Patio de Varga | 130 | 13 ms | 291 | 206 MB |

**Con los enemigos lejanos dormidos (Cimientos, 2026-11-11):** camino 210 · arco 153 · aldea 163 · bosque 146
· pie de la rampa **129 (la peor)** · fortaleza 183 · Varga 148 FPS de media. Los peores fotogramas bajan a
9–19 ms.

Todas las zonas pasan de sobra el mínimo de 45 FPS. Los picos de "peor fotograma" coinciden con el salto de
Kael de una zona a otra (carga de lo que se ve por primera vez), no con el juego normal. Las llamadas de
dibujo son las cosas que se dibujan por separado; el arte tiene que mantenerlas por debajo de unas 1.000.
