# Los Volsungos: rama de desarrollo visual

Rama: `dev/volsungos-3d`, basada en `main` / `86a8e5a94c5de7ffdf68ecb4a0e3e64840471785`.

**Distribución:** el código y las geometrías procedurales están en GitHub. Los cuatro renders y el vídeo están preparados y verificados en la copia local, pero quedan excluidos de Git hasta recibir autorización explícita para publicarlos en este repositorio público. Sin medios, el taller 3D sigue funcionando y muestra referencias sin imagen; la cinemática muestra un botón para volver.

## Qué cambia

- El menú utiliza el render local de Barnstokkr, si está instalado, y abre **Los Volsungos · taller 3D**.
- El taller muestra dos estudios articulados, con reposo, marcha y guardia; se puede girar y acercar la cámara. Los renders originales de Sigurd, Siggeir, Signy y el salón sirven de comparación visual.
- Con el medio local instalado, **Ver la forja** reproduce seis segundos de la animación original V07, convertida a Ogg Theora para Godot. Tiene encuadre 16:9, salida con Esc/B/botón y retorno automático. Es una cinemática pregrabada, sin audio.
- `NordicCostume` viste al jugador y a los enemigos del juego: túnica, cinturón, broche, hombreras, brazales, botas, capa corta y casco/capucha. Las piezas siguen los huesos existentes; la capa y los estandartes tienen movimiento de viento por shader.
- La aldea recibe bancos, estandartes, braseros, luz cálida y partículas de brasa. La decoración queda a los lados del camino; no introduce colisiones ni cambia el trazado.
- Los materiales 3D son originales y procedurales, inspirados en el vestuario de los renders. Se conserva la identidad de Kael, su cinta y los colores de peligro. No se introducen dragones, magia ni personajes de la saga en la historia del juego.

## Probar

Con los archivos Mixamo instalados según `06_ARQUITECTURA_TECNICA.md`, abrir `game/project.godot` en Godot 4.7 y pulsar F5. El menú da acceso al juego y al taller. El vestuario está activado por defecto en esta rama; se puede desactivar por instancia con `volsungos_costume = false` en `Mannequin`.

El repositorio original no incluye `assets/animations/mixamo/y_bot.fbx` ni `mixamo_library.res`. Para revisar el arte sin esos archivos:

```sh
python tools/volsungos/preview.py --godot /ruta/al/ejecutable/godot
python tools/volsungos/preview.py --godot /ruta/al/ejecutable/godot --test
python tools/volsungos/preview.py --godot /ruta/al/ejecutable/godot --test --without-media
```

El lanzador usa una copia temporal de las escenas y medios de esta rama, sin autoloads del combate. No modifica el proyecto ni las partidas guardadas. En el juego completo, el menú avisa si faltan los archivos Mixamo y no borra una partida al intentar iniciar sin ellos.

Para preparar una copia local si ya dispones de los originales y de FFmpeg con libtheora:

```sh
python tools/volsungos/import_media.py --source /ruta/proyecto-volsungos --ffmpeg /ruta/ffmpeg
```

Este comando solo prepara archivos locales; no publica ni cambia las exclusiones de Git.

## Alcance real y siguiente trabajo

Los originales disponibles de Los Volsungos son imágenes y vídeos, **no GLB/FBX/Blend con malla, esqueleto, pesos y clips**. No existe conversión automática fiel de esos renders a un personaje jugable. Los dos cuerpos del taller son estudios geométricos originales para comprobar vestuario y articulación; no son modelos finales ni animación extraída del vídeo.

La integración conserva las animaciones y temporizaciones existentes del combate. No sustituye ni redistribuye los FBX de Mixamo. Para alcanzar el aspecto de la serie falta modelado/retopología, UV y texturas PBR, pelo, rig, pesos y retargeting; después hay que revisar contactos, desvíos, rodadas y colisiones con cada enemigo. El vestuario rígido modular es una primera aproximación y puede requerir ajuste de volúmenes con el rig de producción.

Los archivos visuales preparados localmente suman aproximadamente 2,4 MB. Su procedencia y SHA-256 se generan en `game/assets/volsungos/manifest.json`, también local. Los renders conservan sus bytes originales; la única conversión es el fragmento de vídeo.

## Verificación

`volsungos_test.gd` ejecuta la escena real de revisión, comprueba ambos cuerpos, las uniones a huesos, el movimiento, carga de los cuatro renders, reproducción y salida de la cinemática, devolución del foco y limpieza de accesorios. El lanzador rechaza errores de script, errores del motor y códigos de salida distintos de cero.

La revisión completa del combate y la batería original requieren los archivos Mixamo externos. No se da por validado el ajuste sobre ese rig ni el rendimiento en GTX 1050 hasta ejecutar esas pruebas con los originales.

Validación realizada con Godot 4.7.2: taller con medios locales y sin medios; captura renderizada en Compatibility/OpenGL y revisión de encuadre. La prueba original del menú completa sus aserciones, incluidas las nuevas de acceso al taller y conservación de la partida sin Mixamo; el motor registra además los errores preexistentes por el FBX ausente, por lo que no se considera una ejecución limpia del juego completo.
