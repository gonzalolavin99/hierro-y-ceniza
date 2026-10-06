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
- [ ] Ataque ligero/pesado con combos, hitboxes.
- [ ] Bloqueo, **desvío**, barra de postura (jugador y enemigo).
- [ ] Fijar objetivo (lock-on).
- [ ] Un enemigo maniquí con IA simple (se acerca, ataca, telegrafía).
- [ ] Golpe mortal al romper postura.
- [ ] Primer personaje con animaciones de Mixamo (reemplaza la cápsula).

**🧪 PRUEBA:** pelear 5 minutos contra el maniquí. ¿Es satisfactorio desviar? ¿Se entiende cuándo atacar?

## Hito 3 — El loop souls (2 semanas)
- [ ] Vida, curación con vendajes, muerte y reaparición.
- [ ] Campamento: descansar, recargar curas, reaparecer enemigos.
- [ ] Experiencia: perderla al morir y recuperarla.
- [ ] Subir atributos. Guardado/carga de partida.
- [ ] HUD y menú de pausa.

**🧪 PRUEBA:** jugar un ciclo completo: explorar → morir → recuperar → subir nivel.

## Hito 4 — Enemigos de verdad (3–4 semanas)
- [ ] IA con estados (patrulla, alerta, combate, retirada).
- [ ] 3 tipos: bandido, soldado con lanza, arquero.
- [ ] Ataques peligrosos con aviso rojo.
- [ ] Sigilo básico y ataque sorpresa.

**🧪 PRUEBA:** grupo de 3 enemigos mixtos. ¿Es difícil pero justo?

## Hito 5 — Primer jefe (2–3 semanas)
- [ ] Mini-jefe o jefe con 2 fases, barra de vida especial, música.
- [ ] Arena con niebla de entrada.

**🧪 PRUEBA:** ¿lo puedes vencer en 5–15 intentos aprendiendo patrones?

## Hito 6 — Vertical slice "El Paso de Hierro" (4–8 semanas)
- [ ] Nivel completo con arte real (assets CC0), iluminación, niebla.
- [ ] 2 campamentos, 1 atajo, secretos, objetos.
- [ ] Armas secundarias: ballesta de muñeca y bombas.
- [ ] Sonido, música, narrador (voz en inglés + subtítulos ES) y una cinemática.
- [ ] Menú principal, opciones (gráficos, sangre, subtítulos).
- [ ] Exportar `.exe` jugable.

**🧪 PRUEBA FINAL:** se lo das a otra persona y lo juega de principio a fin. Si les gusta → seguimos expandiendo.

---

**Total estimado hasta la vertical slice:** ~4–6 meses a ritmo de hobby.
Después: nuevas regiones, armas, jefes, historia — iterando con el mismo método.
