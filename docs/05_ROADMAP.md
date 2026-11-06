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

## Hito 6 — El loop souls (2 semanas) ✅ OK del jugador: hito cerrado
- [x] Curación con vendajes, campamento, reaparición de enemigos al descansar.
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
- [x] Experiencia: perderla al morir y recuperarla. Subir atributos.
      Paso 3 hecho y probado (OK del jugador): **experiencia**. Cada enemigo da la suya al morir (soldado 40,
      bandido 35, arquero 45, lancero 55); HUD abajo a la derecha con "+N" al ganarla. Al morir, Kael la pierde
      y queda en su **morral** donde cayó (bolsa de cuero con un jirón rojo en una estaca, se ve de lejos, con
      letrero "Tu morral · N"). Pasar junto a él la recupera. Si muere antes de recogerlo, ese morral se pierde.
      Descansar no lo borra.
      Paso 4 hecho y probado (OK del jugador): **atributos**. Al descansar se abre el menú del campamento
      (arriba/abajo elige, A / Intro sube, B / Esc se levanta). Vigor +10 vida, Temple +8 postura, Fuerza
      +6 % daño, Destreza +6 % daño a la postura, por punto; tope 10 cada uno. Nivel = suma − 3; cada punto
      cuesta 60 + 20 × (nivel − 1) de experiencia.
- [x] Guardado/carga. Menú de pausa.
      Paso 5 hecho y probado (OK del jugador): **guardado automático** en `user://save.json`
      (`%APPDATA%\Godot\app_userdata\Hierro y Ceniza\save.json`). Se guarda al descansar, al subir atributos,
      al morir y al recoger el morral; al abrir el juego Kael aparece en su último campamento con atributos,
      experiencia y morral. Archivo roto = empieza de cero. Las pruebas usan otro archivo.
      Paso 6 hecho y probado (OK del jugador): **menú de pausa** (Start / Esc, congela el juego): Continuar,
      Controles (lista de botones), Empezar de nuevo (confirmación con "No" señalado; borra la partida y
      recarga el nivel) y Salir. B / Esc vuelve atrás. No se abre con el menú de atributos abierto.
- [x] Muerte con la voz del narrador: "No… no fue así" (hecho en el Hito 4 con el sistema de voces).

**🧪 PRUEBA:** ciclo completo: explorar → morir → recuperar → subir nivel.

## Hito 7 — Historia (2–4 semanas, en paralelo con lo anterior) ✅ OK del jugador: hito cerrado
- [x] Guion completo: actos, personajes, cada jefe y su verdad oculta, pistas, los dos finales.
      Paso 1 hecho y revisado (OK del jugador): borrador en `docs/11_GUION.md` (decisiones del §11 tomadas: D18–D21).
- [x] Textos del narrador (Kael anciano) por zona, por jefe y por muerte.
      Paso 2 hecho y probado (OK del jugador): 19 narraciones de historia (prólogo, primer descanso, zonas
      de los 4 actos, antes/después de cada jefe y los dos finales) + frases de muerte por acto (2 por acto,
      el anciano envejece con el relato). Voces generadas con Kokoro, subtítulos en español. Cada narración
      suena una sola vez por partida y se guarda. En el nivel de pruebas: prólogo al empezar, aldea en la
      pelea en grupo, bosque en el patio de sigilo, fortaleza en el grupo mixto y la del primer descanso.
- [x] Descripciones de objetos que cuentan la historia.
      Paso 3 hecho y probado (OK del jugador): **inventario** en el menú de pausa (Pausa → Inventario) con
      13 descripciones: espada, cinta de Lira, vendaje, las 3 armas secundarias, las 3 técnicas y 4 objetos
      clave de la historia (tela gris, llave del Carcelero, carta del Regente, registro de la capital) que
      aparecerán cuando se consigan. Muestra cuántos vendajes y usos quedan.
- [x] Sistema de narración: voz en inglés + subtítulos en español, primera cinemática.
      Paso 4 hecho y probado (OK del jugador): **escena del prólogo** al empezar una partida nueva (~40 s,
      mantener A la salta): la fogata del anciano con el niño → la sala del Regente, que da la orden ("Cinco
      nombres. Cinco cordones…") → primer plano de la cinta de Lira → título → el patio. Voz del Regente
      nueva (Kokoro `bm_george`). Kael lleva ahora la cinta azul en la muñeca también al jugar.
      Ampliada tras la prueba (~70 s): Kael entra caminando y se arrodilla, pregunta "¿Quiénes son?", el
      Regente baja del estrado y le da un pergamino con los nombres, primeros planos al hablar. Arreglados
      los subtítulos que desaparecían a mitad de frase.

**🧪 PRUEBA:** leer el guion y escuchar la primera narración. ¿Engancha?

## Hito 8 — Primer jefe (2–3 semanas) ✅ OK del jugador: hito cerrado
- [x] Capitana Varga: duelo de 2 fases, varias barras de golpe mortal, música, arena con niebla.
      Paso 1 hecho y probado (OK del jugador): **arena** (patio de la fortaleza al este del nivel de pruebas,
      x = 84, con pasillo, niebla baja, braseros y "Campamento de la fortaleza" a la entrada). Al entrar, el
      **rastrillo** baja detrás de Kael y aparece la **barra de jefa** arriba (nombre, vida, postura y un punto
      rojo por golpe mortal). **2 golpes mortales**: el primero la tumba y se rehace con todo (fase 2). Si Kael
      muere, el rastrillo sube y todo vuelve a empezar; vencida, no vuelve (se guarda).
      Pasos 2 y 3 hechos y probados (OK del jugador), tras pedir el jugador más dificultad y movimiento
      (inspiración: duelista acrobática al estilo de la Dama Mariposa de Sekiro, sin espíritus ni cuerdas):
      **repertorio propio** (combo de cuatro con cambio de ritmo, torbellino, salto desde lejos con tajo al
      caer, salto atrás lanzando 3 cuchillos, cuchillos a distancia; esquiva el 50 % y contraataca con
      cuchillos o salto) y **fase 2** (más rápida, +daño, abanico de 3 cuchillos, combo largo de cinco).
      **Voz propia** (Kokoro `bf_isabella`): frases al verte, al cambiar de fase, al vencerte y al caer.
      Paso 4 hecho y probado (OK del jugador), pulido pedido por el jugador:
      **reacciones a los golpes** según fuerza y dirección (ligero ~0,3 m, medio ~0,6 m tambaleándose,
      fuerte ~1,1 m despedido con los pies en el aire; por la espalda trastabilla sin girarse; más pausa de
      impacto y temblor cuanto más fuerte; los enemigos retroceden y se sacuden fuera de sus ataques);
      **escena antes del duelo** (solo la primera vez; Varga junto a la ropa de los enfermos que arde: "Ese
      humo no es una aldea ardiendo…", Kael: "Tengo mis órdenes"); **música del duelo** propia
      (tools/gen_music.py: taikos, bordón y cuerda pulsada en frigio; la fase 2 dobla los tambores); al caer
      deja su **estandarte** (objeto clave) y enseña la **Ráfaga**.
      Prueba del jugador: "bastante difícil, así que está bueno". Arreglado: al rehacerse (y al morir) los
      enemigos apagaban su cuerpo y caían a través del suelo; ahora solo dejan de recibir golpes y de chocar
      con Kael. Red de seguridad: un enemigo que cae del mapa vuelve a su puesto.

**🧪 PRUEBA:** ¿lo puedes vencer en 5–15 intentos aprendiendo patrones?

## Extra — Frank, el tití (compañero; guion §12, D22)
- [x] Paso 1: crear a Frank. Hecho y probado (OK del jugador): tití pequeño con el pelo lleno de **rulos**,
      cola larga, ojos grandes; hecho en código y animado por código (respira, parpadea, mece la cola,
      cabecea al chillar, gestos: agarrarse, taparse los ojos, señalar, triste, tocarse los rulos). **No
      habla: chilla** (chillidos sintetizados propios, `tools/gen_frank.py`) y el subtítulo es lo que Kael
      entiende, entre «». **La red de los cazadores** junto al inicio: Frank pide ayuda al acercarse; con
      **Y** sale la escena (Kael corta la cuerda, Frank cae, se sacude, Kael lo manda con los suyos, Frank
      cuenta que no lo quieren por los rulos, el anciano recuerda y Frank se le sube al hombro). Si Kael
      **pasa de largo**, Frank se suelta solo, lo alcanza corriendo y se le sube, ofendido. Desde entonces
      va en el **hombro izquierdo** de Kael; parlotea a ratos y se asusta si a Kael le pegan.
- [x] Paso 2: consejos y bromas. Hecho y probado (OK del jugador): vendarse con un enemigo alerta cerca → se
      tapa la cara («¿Ahora? ¿En serio?»); sin vendas → «En un campamento te dan más»; al morir se tapa los
      ojos y al reaparecer anima; desde la 2.ª muerte con el mismo enemigo, **pistas** de ese enemigo
      (soldado, lancero, arquero, bandido, Varga) alternadas con ánimos y una pista de los ataques rojos;
      guardia rota → «¡Respira, grandullón!»; comentario al entrar en cada zona (tras el anciano); primer
      descanso; broma tras 25 s quieto; a veces, tras un golpe mortal, **la conciencia de Kael** («¿Seguro que
      eran rebeldes?»). **Momentos serios**: en el duelo con un jefe no bromea (solo pistas); en la escena de
      la ropa ardiendo y tras la muerte de Varga se queda cabizbajo y callado. 35 chillidos nuevos.
- [x] Paso 3: avisa y encuentra. Hecho y probado (OK del jugador): **avisos** chillando y señalando (se gira en
      el hombro y estira el brazo): un arquero tensa el arco contra Kael («¡El del arco! ¡Te apunta!»), un
      enemigo se lanza a por él por la espalda («¡Detrás de ti!»), uno sospecha («Shh… Ese ha oído algo.»).
      **Escondites**: a 8 m los huele, los señala y brillan; "Y  Recoger" (experiencia y, a veces, un objeto
      clave). Dos en el escenario: detrás del bloque alto y dentro de la despensa. **Despensa de los
      cazadores** cerrada por dentro: "Y  Que Frank abra el pestillo" → salta el muro, abre y vuelve al
      hombro; queda abierta para siempre. Dentro, la **Nota de los cazadores** (objeto clave: el palacio
      compraba animales raros… y ya no compra, porque en la capital hay fiebre); Frank: «…Esa jaula era
      para mí.»
- [ ] Paso 4: distrae (le tira fruta a un enemigo para abrir un golpe por la espalda).

## Hito 9 — Vertical slice "El Paso de Hierro" + diseño de personajes (6–10 semanas)
- [ ] Diseño final de Kael y enemigos.
- [ ] Nivel completo con arte real, iluminación, 2 campamentos, 1 atajo, secretos.
- [ ] Menú principal, opciones (gráficos, sangre, subtítulos). Exportar `.exe`.

**🧪 PRUEBA FINAL:** otra persona lo juega de principio a fin.

---

Después: nuevas regiones, jefes y capítulos de la historia, con el mismo método.
