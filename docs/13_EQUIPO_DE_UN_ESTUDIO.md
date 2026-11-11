# 13 · Los puestos de un estudio de videojuegos

Referencia (pregunta del jugador, 2026-11-08): qué departamentos y especialistas tendría una empresa que
hiciera este juego, y quién cubre cada papel en nuestro proyecto. Un estudio grande de souls-like tiene
entre 50 y 300 personas; un estudio indie, de 1 a 5.

| Departamento | Especialistas | Qué hacen (ejemplo en Hierro y Ceniza) | Aquí lo cubre |
|---|---|---|---|
| **Dirección y producción** | Director del juego | Visión de conjunto; decide qué entra y qué no | El jugador (prueba y da el OK) |
| | Productor | Calendario, presupuesto, prioridades (el roadmap y sus hitos) | Claude, con el OK del jugador |
| **Diseño** | Diseñador de combate | Duración de los ataques, ventana de desvío, postura | Claude |
| | Diseñador de niveles | Mapa, caminos, atajos, guiar al jugador (farolillos, puerta atrancada) | Claude |
| | Diseñador de sistemas | Economía, objetos, mejoras, guardado | Claude |
| | Diseñador narrativo / guionista | Historia, diálogos, lore (el Regente, Lira, el narrador) | Claude, con el OK del jugador |
| | Diseñador de experiencia (UX) | Que el jugador entienda qué hacer (carteles solo del mando o teclado en uso) | Claude + opiniones del jugador |
| **Programación** | Programador de gameplay | Movimiento, combate, Frank | Claude |
| | Programador de IA | Cómo piensan los enemigos (atacar, esperar, cubrirse) | Claude |
| | Programador de motor y gráficos | Rendimiento; que vaya bien en la GTX 1050 | Claude |
| | Programador de herramientas | Programas internos que aceleran el trabajo (pruebas, capturas) | Claude |
| | Programador de interfaz (UI) | Menús, HUD, avisos | Claude |
| **Arte** | Director de arte | Estilo visual de todo el juego | Pendiente (Hito 9, paso 7) |
| | Artista conceptual | Dibujos previos de personajes y lugares | Pendiente |
| | Modelador 3D | Personajes, armas, escenarios | Pendiente (hoy: maniquíes de Mixamo) |
| | Artista de entornos | "Vestir" los niveles que hoy son bloques grises | Pendiente |
| | Texturas y materiales | Que algo parezca hierro, madera o tela | Pendiente |
| | Artista técnico | Puente entre arte y programación (luces, sombras, rendimiento) | Claude |
| | Efectos visuales (VFX) | Chispas al desviar, polvo, fuego, humo | Claude (efectos sencillos) |
| **Animación** | Animador de personajes | Cada golpe, esquiva y caída; clave en un souls-like | Mixamo + ajustes de Claude |
| | Captura de movimiento | Grabar actores con trajes de sensores | Sustituido por Mixamo |
| | Rigger | El "esqueleto" dentro del modelo para animarlo | Mixamo |
| **Audio** | Diseñador de sonido | Choques de acero, pasos, chillidos de Frank (propios o CC0) | Claude |
| | Compositor | La música | Claude (música sencilla) |
| | Director de voces / actores | Las voces (hoy generadas en local con Kokoro) | Claude |
| **Calidad (QA)** | Testers | Jugar una y otra vez buscando fallos | El jugador (F5) + pruebas automáticas en `game/tests/` |
| **Otros** | Localización | Traducir a otros idiomas | Pendiente |
| | Marketing y comunidad | Tráileres, redes, página de Steam | Pendiente |
| | Publisher (editora) | Financia y distribuye (opcional) | No aplica |

**Lo que más nos falta respecto a un estudio real:** arte y animación propios. Por eso el arte es el último
paso del Hito 9; mientras tanto, bloques grises y animaciones de Mixamo.
