# 05 · Hoja de ruta (Roadmap)

Cada hito termina con una **PRUEBA** que haces tú y un **OK** (o lista de cambios). No avanzamos
sin tu OK. Los tiempos son estimaciones de calendario trabajando unas horas por semana.

Las pruebas manuales se complementan con pruebas automáticas en `game/tests/`. Para cada ajuste medible se registra primero una prueba que reproduce el fallo; tras el cambio se vuelven a ejecutar las pruebas relacionadas. Los comandos y resultados se guardan en la documentación del paso. La prueba automática no reemplaza tu OK visual y de control.

---

## Hito 0 — Preparación (1 sesión)
- [x] Instalar Godot 4.7.2 en `G:\Herramientas\Godot\` (usa la NVIDIA automáticamente).
- [x] Git (ya estaba instalado) y repositorio creado.
- [x] Proyecto Godot base (carpetas, configuración, panel de FPS/GPU/mandos).

**🧪 PRUEBA:** abres el proyecto, pulsas F5, ves una escena vacía con suelo, cielo y FPS ≥ 60.

## Hito 1 — Moverse bien (1–2 semanas)
- [x] Personaje cápsula: caminar, correr, paso rápido, saltar (al estilo Sekiro).
- [x] Cámara en tercera persona con mando Xbox.
- [x] Barra de postura (sin aguante, como Sekiro).
- [x] Escenario de pruebas (rampas, escaleras, plataformas).

**🧪 PRUEBA:** ¿el movimiento se siente "pesado pero responsivo" como Souls/Sekiro? Ajustamos
velocidades y tiempos hasta que digas OK.

## Hito 2 — Combate básico (2–3 semanas)
- [x] Combo de ataque (RB, 3 golpes) con zonas de golpe.
- [x] Bloqueo, **desvío**, barra de postura (jugador y enemigo).
- [x] Fijar objetivo con R3 (stick derecho cambia de objetivo; sin enemigos, recentra la cámara).
- [x] Un enemigo maniquí con IA simple (se acerca, ataca, telegrafía).
- [x] Golpe mortal al romper postura.
- [→] Animaciones de Mixamo: movido al Hito 3 (pulido).

**🧪 PRUEBA:** pelear 5 minutos contra el maniquí. ¿Es satisfactorio desviar? ¿Se entiende cuándo atacar?

## Prioridades (decisión D14)
1. **Combate y movimiento** pulidos, fluidos, con muchas opciones y nada "cuadrado".
2. **Historia** de gran calidad.
3. **Diseño de personajes** al final. El mundo, por ahora, solo como escenario de pruebas.

## Hito 3 — Pulido del combate I: sensación (2–3 semanas)
- [x] **Sonido**: clang de desvío "que da dopamina" (estilo Sekiro), bloqueo, impacto, tajos al aire, pasos.
- [x] Animaciones Mixamo con un maniquí neutro (no es el diseño final de Kael): correr, paso rápido,
      saltar, tajos, guardia, desvío, golpe recibido, golpe mortal, muerte.
- [x] Transiciones suaves (hecho: mezclas, paso real, ritmo de esgrima, postura baja, giro de cadera, estela, esquivas direccionales, reacciones según dirección, choque que empuja a ambos, inclinación corporal y apoyo individual de pies en rampas).
- [x] Cámara: suavizado al fijar, encuadre en peleas cercanas (vista por encima del hombro).

✅ **Hito 3 cerrado con OK del jugador (2026-10-20).**

**🧪 PRUEBA:** ¿se siente "como un juego de verdad" y no como cápsulas?

## Hito 4 — Pulido del combate II: opciones (3–4 semanas)
- [x] **Ataques peligrosos** con aviso rojo: barrido (se salta), estocada (contraataque especial pisando
      el arma), agarre (hay que alejarse). Hecho, con prueba automática y OK del jugador.
      Animaciones provisionales (estocada y agarre) hasta tener unas propias.
- [x] Ataque en salto, ataque tras paso rápido, golpe pesado, ataque a la carrera, patada que rompe guardia.
- [x] Pisar al enemigo tras saltar su barrido (como Sekiro).
- [x] **Técnicas** de combate (LB+RB, una equipada; cruceta ↑ cambia): Torbellino, Golpe de Martillo y
      Ráfaga, con desbloqueo. Hechas con prueba automática y OK del jugador.
- [x] Armas secundarias: ballesta de muñeca, bomba de humo, bomba de pólvora. Hechas, con prueba
      automática y OK del jugador. Gestos provisionales (sin animaciones propias de disparo/lanzamiento).
- [x] Voces y esfuerzos en combate (gritos de ataque, quejidos, frases de enemigos). Sistema hecho, con
      subtítulos y prueba automática. Audios generados en local con Kokoro (gratis), con turnos para que no se pisen.
      Pendiente para más adelante: pulido fino de audio y diálogo (volúmenes, mezcla, más variedad).

**🧪 PRUEBA:** ¿hay varias formas de ganar una pelea?

✅ **Hito 4 cerrado con OK del jugador (2026-11-03).**

## Hito 5 — IA inteligente y enemigos (3–4 semanas) ✅ CERRADO (OK del jugador)
- [x] **Una sola dificultad** (D13): la IA tiene que ser lista, no tramposa.
- [x] IA que lee al jugador: castiga curarse a destiempo y el abuso del paso rápido, cambia el ritmo,
      hace fintas y retrasa golpes si siempre desvías igual, se retira y flanquea en grupo.
      Paso 1 hecho (`EnemyMind`, OK del jugador): retrasa golpes y amaga si desvías mucho, estocadas
      si abusas del paso rápido, barridos/agarres si te escondes tras la guardia, contraataca antes si atacas
      sin pausa. Pendiente: curarse a destiempo (Hito 6).
      Paso 2 hecho (OK del jugador): pelea en grupo con turnos (`Squad`): ataca uno cada vez,
      con respiro entre uno y otro; los demás esperan a ~3,6 m con la guardia alta y te rodean hacia los
      costados y la espalda; no se hieren entre ellos; al caer el fijado, la cámara pasa al siguiente.
- [x] Patrulla, alerta, sigilo y ataque sorpresa. Paso 3 hecho (OK del jugador): agacharse
      (C / L3), los guardias desprevenidos hacen su ronda, te ven (cono de 120°, 15 m, se tapan con muros;
      agachado cuesta más) y te oyen (correr hace ruido, agachado casi nada), sospechan ("?") y van a mirar,
      te descubren ("!") y avisan a los cercanos; si te pierden 4 s, buscan y vuelven a la ronda. Golpe mortal
      por sorpresa por la espalda. Patio de sigilo en el escenario. Pendiente: animaciones de caminar
      agachado (Mixamo, las descarga el jugador; de momento se usan las de caminar de pie).
- [x] 3 tipos: bandido, soldado con lanza, arquero. Paso 4a hecho (OK del jugador): **bandido**
      (`bandit.tscn`, hereda del soldado): 80 de vida, postura 75, más rápido e impaciente; tajos rápidos,
      ráfaga de 3, embestida desde lejos, barrido y agarre (sin estocadas); ve empezar tu ataque y a veces se
      aparta de un salto (estado `Evade`) y contraataca embistiendo.
      Paso 4b hecho (OK del jugador): **lancero** (`spearman.tscn`): lanza de 2,3 m, alcance 3,3 m,
      sobre todo estocadas, golpe amplio, estocada y barrido peligrosos; si te pegas a él salta atrás y
      contraataca. **Arquero** (`archer.tscn`, animaciones Longbow de Mixamo): dispara flechas que se bloquean
      y desvían (aviso con destello al apuntar), retrocede si te acercas, patada si te pegas, no bloquea.

**🧪 PRUEBA:** grupo de 3 enemigos mixtos. ¿Es difícil pero justo? ¿Se siente que piensan?
Zona "GRUPO MIXTO" montada (soldado + lancero + arquero, x=34, z=46). El arquero también pide turno: tensa y
apunta solo cuando nadie más ataca y suelta el turno al disparar. ✅ OK del jugador: Hito 5 cerrado.
Quedan para más adelante: castigar curarse a destiempo (cuando exista la curación, Hito 6) y las animaciones
de caminar agachado (Mixamo, las descarga el jugador).

## Hito 6 — El loop souls (2 semanas)
- [~] Curación con vendajes, campamento, reaparición de enemigos al descansar.
      Paso 1 hecho y probado (OK del jugador): **vendajes** (X / R): 3 cargas, cada una cura el 45 % de la vida;
      vendarse dura 1,4 s quieto y sin guardia (se aprieta a los 0,9 s); un golpe antes lo interrumpe sin gastar
      el vendaje; se reponen al reaparecer. Los enemigos alerta a ≤7 m que te ven empezar a vendarte se lanzan
      a castigarte (embestida o tajo rápido; el arquero dispara), salvo que otro ya esté atacando. Animación
      provisional (`idle_4`: mano al cuello); pendiente una de vendarse de Mixamo.
      Paso 2 hecho y probado (OK del jugador): **campamento** (fogata con tienda, junto al inicio del patio).
      Y / E junto al fuego = descansar (3,6 s, fundido a negro): repone vida, postura, vendajes y herramientas,
      todos los enemigos vuelven vivos a su puesto, y pasa a ser el punto de reaparición. No se puede con un
      enemigo que te tenga en la mira a ≤20 m (el aviso dice "Hay enemigos cerca"). Los enemigos muertos ya no
      reaparecen solos: solo al descansar o al morir Kael (que reaparece en el último campamento, con fundido).
- [ ] Experiencia: perderla al morir y recuperarla. Subir atributos.
- [ ] Guardado/carga. Menú de pausa.
- [ ] Muerte con la voz del narrador: "No… no fue así".

**🧪 PRUEBA:** ciclo completo: explorar → morir → recuperar → subir nivel.

## Hito 7 — Historia (2–4 semanas, en paralelo con lo anterior)
- [ ] Guion completo: actos, personajes, cada jefe y su verdad oculta, pistas, los dos finales.
- [ ] Textos del narrador (Kael anciano) por zona, por jefe y por muerte.
- [ ] Descripciones de objetos que cuentan la historia.
- [ ] Sistema de narración: voz en inglés + subtítulos en español, primera cinemática.

**🧪 PRUEBA:** leer el guion y escuchar la primera narración. ¿Engancha?

## Hito 8 — Primer jefe (2–3 semanas)
- [ ] Capitana Varga: duelo de 2 fases, varias barras de golpe mortal, música, arena con niebla.

**🧪 PRUEBA:** ¿lo puedes vencer en 5–15 intentos aprendiendo patrones?

## Hito 9 — Vertical slice "El Paso de Hierro" + diseño de personajes (6–10 semanas)
- [ ] Diseño final de Kael y enemigos.
- [ ] Nivel completo con arte real, iluminación, 2 campamentos, 1 atajo, secretos.
- [ ] Menú principal, opciones (gráficos, sangre, subtítulos). Exportar `.exe`.

**🧪 PRUEBA FINAL:** otra persona lo juega de principio a fin.

---

Después: nuevas regiones, jefes y capítulos de la historia, con el mismo método.
