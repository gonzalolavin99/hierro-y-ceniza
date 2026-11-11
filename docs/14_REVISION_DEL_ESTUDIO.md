# 14 · Revisión del "estudio" (2026-11-09)

El jugador pidió que un experto de cada departamento del [13_EQUIPO_DE_UN_ESTUDIO](13_EQUIPO_DE_UN_ESTUDIO.md)
revisara todo lo hecho hasta el Hito 9, paso 3. A cada uno se le presentó como alguien con más de 20 años de
experiencia en souls-like de primer nivel y se le pidió honestidad, sin adular. Ninguno cambió nada del
proyecto. Este documento resume lo que dijeron.

## 1. Las notas

| Departamento | Nota | En una frase |
|---|---|---|
| Programación | **7** | La base es de estudio profesional; lo que preocupa es cómo va a crecer |
| Dirección y producción | **6,5** | Buen método y mucha velocidad, pero el arte está metido en un solo paso al final |
| Diseño | **6** | Combate 7 · Varga 7 · niveles 5 · sistemas 6 · historia 8 en papel y 4 dentro del juego · UX 5 |
| Calidad (QA) | **6** | Hay muchas más pruebas de lo normal, pero el guardado y el ejecutor de pruebas son frágiles. Las 4 que ejecutó pasaron |
| Animación | **6** | La técnica es excelente; en pantalla todavía se nota que es Mixamo retocado |
| Audio | **5** | La lógica está bien resuelta; falta contenido (pasos, ambiente) y faltan canales de mezcla |
| Localización y marketing | **4** | El juego tiene buenos ganchos, pero no está preparado para traducirse ni para venderse |
| Arte | **3** | Todavía no hay arte ni un estilo decidido (es pronto, pero urge decidirlo) |

**Todos dijeron que tiene futuro**, con una condición que repitieron casi todos: el arte tiene que estar a
la altura del combate, y lo que hará destacar al juego es **la historia (el narrador, el Regente) y Frank**.

## 2. Lo que todos valoraron

- El **combate al estilo Sekiro está bien medido**: desvío de 0,2 s, ataques peligrosos que se leen bien y la idea propia de "pisar la hoja".
- El **guion** es lo mejor del proyecto: el narrador poco fiable, un Regente que parece bueno y un final bueno que sale de actos pequeños.
- **Frank** es un gancho que vende y que ningún otro souls-like tiene.
- El **método de trabajo**: pruebas automáticas, cada queja convertida en una prueba y el documento de traspaso. Pocos estudios pequeños lo tienen.
- La **IA** es honesta: solo ve lo que vería un rival real. Los turnos de ataque en grupo están bien hechos.
- El **rendimiento** se cuida desde el principio.

## 3. Los problemas, ordenados por urgencia

### Urgente (se puede perder trabajo o una partida)
1. **Trabajo sin guardar en Git**: el nivel nuevo entero y 17 archivos modificados, más 3 commits sin subir a GitHub (dirección, programación).
2. **Guardado frágil** (`save_game.gd`): escribe directamente sobre el archivo y, si se corta a mitad, la partida queda rota. No hay copia de respaldo, no comprueba la versión y depende de la ruta exacta del nivel (QA, programación).

### Afecta a cómo se juega hoy (antes del OK del paso 3)
3. **Todas las técnicas están desbloqueadas en el nivel real** (`Player.start_with_all_arts = true` por defecto; confirmado). Vencer a Varga no da ningún premio (diseño).
4. **La IA castiga el desvío con retrasos al azar**: a partir de 3 desvíos seguidos, el enemigo retrasa el golpe 0,25–0,5 s al azar. En Sekiro los retrasos son siempre iguales y se aprenden. Con los combos largos de Varga se activa solo. Desviar bien acaba sintiéndose peor (diseño).
5. **El tutorial apenas enseña**: nunca explica el aviso rojo, el golpe mortal, la patada, las técnicas ni las armas. El segundo enemigo es el bandido, que es difícil (diseño).
6. **El ritmo del nivel**: unos 17 enemigos entre una fogata y otra con solo 3 vendajes, y el atajo no acorta nada porque ya hay una fogata cerca (diseño).

### Importante pronto
7. **Decidir el estilo de arte ahora**, no en el último paso, y dividir el "paso 7: arte" en partes. Propuesta: low-poly pintado, con paleta corta (pizarra, ceniza, más rojo óxido, naranja y azul acero), personajes tapados (yelmos, capuchas) y kits CC0 (Quaternius, Kenney) (arte, dirección).
8. **Nadie de fuera lo ha jugado**. Recomiendan adelantar el `.exe` (paso 6) y dárselo a 3–5 personas, aunque todavía sea en bloques (dirección, diseño, QA).
9. **Los textos están escritos directamente en el código**: traducir después costará semanas. Si se hace ahora, son unos días (marketing).
10. **Los nombres de huesos de Mixamo están escritos a mano en 16 archivos**. Si se cambian a nombres comunes, el paso al Kael definitivo no rompe nada (animación).
11. **Los enemigos nunca "duermen"**: los 20 trabajan en cada fotograma aunque estén lejos. Nunca se ha medido el rendimiento en el Paso de Hierro (programación).
12. **Audio**: faltan canales de mezcla (música, voz, efectos), pasos, ambiente y música para el Paso. Los gritos hechos con voz sintética suenan robóticos (audio).

### Más adelante
- Poner los ataques de los enemigos en archivos de datos aparte. Hacer que las pruebas vayan más rápidas, ejecutando 4 a la vez (programación).
- Añadir reacciones a los golpes según la dirección, y caídas; quitar los giros instantáneos (animación).
- Que el ejecutor de pruebas diga claramente "29/29 OK" o qué prueba falló; abrir un registro de fallos (QA).
- Revisar el título (es genérico), añadir un archivo de licencia al repositorio, llevar un registro de qué se hizo con IA para declararlo en Steam y abrir la página de Steam cuando haya unas 5 capturas bonitas (marketing).
- Dar menos pistas del giro en el prólogo (diseño). Sigue pendiente decidir si el narrador revela "Yo fui ese guerrero".
- Poner al día los documentos que se contradicen (ElevenLabs/Kokoro, "solo mando") (dirección).

## 4. Decisiones tras la revisión (2026-11-09)

- **El juego no se va a vender.** Es un proyecto personal. Por eso no se planifican la localización, el
  marketing, Steam, el título ni las licencias comerciales (el punto 9 y lo de marketing en "Más adelante"
  quedan descartados).
- **Arreglados los puntos 2, 3 y 4:**
  - **Guardado seguro** (`save_game.gd`, versión 2): primero se escribe un archivo temporal y después se
    renombra; se guarda una copia `.bak`, que se carga si la buena está rota; las partidas de la versión 1 se
    adaptan; una partida de una versión más nueva no se toca; se comprueba cada dato; el nivel se identifica
    por su nombre y no por la ruta; también se guardan las técnicas. "Empezar de nuevo" borra la copia.
    Se comprueba en `save_test`.
  - **Técnicas en el nivel real**: `iron_pass.tscn` tiene `start_with_all_arts = false`. Empiezas solo con el
    Torbellino y la Ráfaga se gana venciendo a Varga. El Golpe de Martillo todavía no tiene un sitio donde
    ganarse. Se comprueba en `iron_pass_test`.
  - **Retrasos de la IA siempre iguales**: cada ataque tiene una sola versión retrasada, que es siempre la
    misma (`EnemyAttackState.HOLDS`: qué tajo y cuántos segundos). La IA solo decide si la usa. La racha
    cuenta ataques desviados, no tajos (`EnemyMind.begin_attack`). Los ataques de Varga nunca se retrasan.
    Se comprueba en `ai_test`.

## 5. Riesgo de fondo

Varios expertos coinciden en que el peligro no es la calidad de lo hecho, sino **añadir sin recortar**.
Recomiendan congelar lo que entra en la vertical slice y, en lugar de sumar sistemas, dedicar el próximo
tramo a **enseñar** (que un novato entienda el desvío) y a **contar** (los aldeanos del paso 4).
