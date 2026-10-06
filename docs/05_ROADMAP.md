# 05 · Hoja de ruta (Roadmap)

Cada hito termina con una **PRUEBA** que haces tú y un **OK** (o lista de cambios). No avanzamos
sin tu OK. Los tiempos son estimaciones de calendario trabajando unas horas por semana.

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
- [ ] **Sonido**: clang de desvío "que da dopamina" (estilo Sekiro), bloqueo, impacto, tajos al aire, pasos.
- [ ] Animaciones Mixamo con un maniquí neutro (no es el diseño final de Kael): correr, paso rápido,
      saltar, tajos, guardia, desvío, golpe recibido, golpe mortal, muerte.
- [ ] Transiciones suaves entre animaciones (mezcla), giro con inercia, arrancar/frenar natural.
- [ ] Cámara: suavizado al fijar, encuadre en peleas cercanas.

**🧪 PRUEBA:** ¿se siente "como un juego de verdad" y no como cápsulas?

## Hito 4 — Pulido del combate II: opciones (3–4 semanas)
- [ ] **Ataques peligrosos** con aviso rojo: barrido (se salta), estocada (contraataque especial pisando
      el arma), agarre (hay que alejarse).
- [ ] Ataque en salto, ataque tras paso rápido, ataque cargado.
- [ ] Pisar al enemigo tras saltar su barrido (como Sekiro).
- [ ] 2–3 **técnicas** de combate desbloqueables.
- [ ] Armas secundarias: ballesta de muñeca, bomba de humo, bomba de pólvora.
- [ ] Voces y esfuerzos en combate (gritos de ataque, quejidos, frases de enemigos).

**🧪 PRUEBA:** ¿hay varias formas de ganar una pelea?

## Hito 5 — IA inteligente y enemigos (3–4 semanas)
- [ ] **Una sola dificultad** (D13): la IA tiene que ser lista, no tramposa.
- [ ] IA que lee al jugador: castiga curarse a destiempo y el abuso del paso rápido, cambia el ritmo,
      hace fintas y retrasa golpes si siempre desvías igual, se retira y flanquea en grupo.
- [ ] 3 tipos: bandido, soldado con lanza, arquero. Patrulla, alerta, sigilo y ataque sorpresa.

**🧪 PRUEBA:** grupo de 3 enemigos mixtos. ¿Es difícil pero justo? ¿Se siente que piensan?

## Hito 6 — El loop souls (2 semanas)
- [ ] Curación con vendajes, campamento, reaparición de enemigos al descansar.
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
