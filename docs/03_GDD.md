# 03 · Documento de Diseño del Juego (GDD)

> Estado: **v0.2** — decisiones D1–D8 aplicadas. Lo marcado con 🔶 sigue pendiente de tu OK.

## 1. Concepto

- **Título provisional:** *Hierro y Ceniza*
- **Género:** Acción-RPG souls-like en tercera persona, con combate y movimiento al estilo Sekiro.
- **Una frase:** *Un anciano cuenta la leyenda de un guerrero que recorrió un reino en guerra para
  salvarlo… pero cuanto más avanza el relato, más claro queda que fue él quien lo destruyó.*
- **Ambientación:** reino medieval-feudal que mezcla Europa y Japón (armaduras, castillos,
  templos civiles, aldeas de montaña), en plena guerra civil y con una peste. Sin elementos
  sobrenaturales (ver [guía de contenido](04_GUIA_DE_CONTENIDO.md)).

## 2. Pilares (lo que nunca se sacrifica)

1. **Combate preciso estilo Sekiro**: el desvío es el centro de todo.
2. **Aprender al enemigo**: patrones legibles, avisados y castigables.
3. **Una historia que se cuenta mientras juegas** y que al final se da vuelta.
4. **Ligero y pulido**: mejor 1 zona excelente que 5 mediocres.

## 3. Qué tomamos de cada juego

| De… | Tomamos |
|---|---|
| **Sekiro** (base principal) | Movimiento ágil (paso rápido en vez de rodar, salto, agacharse), **postura**, **desvío**, golpe mortal, ataques peligrosos con aviso, sigilo y ataque sorpresa, sangre mínima |
| **Dark Souls** | Campamentos, pérdida y recuperación de experiencia, atajos que conectan el mapa, enemigos que reaparecen al descansar |
| **Elden Ring** | Zonas más abiertas con caminos opcionales, jefes opcionales |

**Sin gancho** (decisión D6). La verticalidad sale del salto, las escaladas y las cornisas.

## 4. Sistema de combate (núcleo, fiel a Sekiro)

### Recursos del jugador
- **Vida**: se recupera con vendajes o ungüento (cargas limitadas).
- **Postura**: sube al bloquear o recibir golpes y se recupera sola (más rápido si mantienes
  la guardia). Si se llena, quedas aturdido.
- **Sin barra de aguante**, como en Sekiro: puedes atacar y esquivar libremente, y el límite
  lo pone la postura.

### Controles (mando Xbox)
| Acción | Botón | Notas |
|---|---|---|
| Ataque | RB | Combo de 3–4 golpes |
| Bloquear / **Desviar** | LB | Mantener = bloqueo. Pulsar justo antes del golpe = **desvío** (unos 150 ms), sin daño y la postura sube al **enemigo** |
| Paso rápido | B | Movimiento corto con invulnerabilidad breve. Mantener = correr |
| Salto | A | Saltar un barrido (aviso rojo) permite pisar al enemigo |
| Fijar objetivo | R3 | |
| Curarse | X | Te deja vulnerable |
| Objeto / arma secundaria | RT | Ballesta de muñeca, bombas de humo y pólvora, cuchillos |
| Técnica | RB + LB | Movimiento especial aprendido |
| Agacharse / sigilo | L3 | |
| Interactuar | Y | |

### Enemigos
- Vida + **postura**. Romper la postura (o dejar la vida a 0) abre el **golpe mortal**.
- **Aviso rojo** en los ataques que no se pueden bloquear: el **barrido** se salta, la
  **estocada** se esquiva o se contrarresta, del **agarre** hay que alejarse.
- Ataque sorpresa por la espalda o desde sigilo = golpe mortal instantáneo (enemigos comunes).
- Los jefes tienen varias barras de golpe mortal (como Sekiro).

### Sangre (D2)
- Mínima, como Sekiro: pequeñas salpicaduras al golpear y chispas en los desvíos.
  Sin cortes de miembros ni charcos. Opción en ajustes para reducirla aún más (solo chispas).

### Muerte
- Vuelves al último campamento. La experiencia queda donde caíste y la recuperas volviendo.
- Lo explica el narrador (ver §10): *"No… no fue así. Déjame empezar de nuevo."*

## 5. Progresión

- **Atributos** (se suben en el campamento): Vigor (vida), Temple (postura), Fuerza, Destreza.
- **Arma principal fija** (katana-espada larga del protagonista), que se mejora con el herrero.
  Las técnicas se aprenden de maestros o se encuentran.
- **Armas secundarias**: ballesta de muñeca, bombas de pólvora, bomba de humo, cuchillos.
- **Atuendos** (más adelante, D5): cosméticos temáticos.

## 6. Enemigos (catálogo inicial)

| Tipo | Ejemplos |
|---|---|
| Humanos comunes | Bandido con cuchillo, soldado con lanza, arquero, desertor con escudo |
| Humanos élite | Caballero pesado, duelista, ejecutor con hacha enorme |
| Bestias | Lobos (en manada), jabalí, oso, perros de guerra |
| Jefes (vertical slice) | 🔶 **Mini-jefe:** El Carcelero (gigante con cadena). **Jefe:** Capitana Varga, duelista |
| Jefes futuros | Oso blanco de la montaña, máquina de asedio, el "General traidor" |

## 7. Mundo y estructura

- Zonas conectadas por atajos (como Dark Souls 1) dentro de cada región, y regiones más
  abiertas (como Elden Ring) unidas entre sí.
- **Primera región (vertical slice): "El Paso de Hierro"** 🔶. Aldea en ruinas, bosque y la
  puerta de una fortaleza. Entre 15 y 25 minutos, 2 campamentos, 1 atajo, 1 mini-jefe, 1 jefe.

## 8. Arte, cámara, sonido

- **Estilo:** low-poly estilizado, paleta desaturada con acentos (el rojo para el peligro,
  el naranja de la fogata) y niebla.
- **Cámara:** tercera persona con fijado de objetivo.
- **Voces en inglés + subtítulos en español** (D8). Narrador con mucha presencia.
- Sonido del combate como prioridad: el clang del desvío, la postura rota, el golpe mortal.

## 9. Alcance realista

1. Prototipo de combate con cubos: ¿se siente como Sekiro?
2. Vertical slice: una zona completa de unos 20 minutos.
3. Si (2) es divertido, se expande región por región.

## 10. Historia (borrador 🔶)

### Estructura narrativa
- Un **anciano** cuenta la historia junto a una fogata a alguien que no vemos. Su voz acompaña
  el juego: comenta al entrar en zonas nuevas, en las cinemáticas, antes de los jefes y al morir.
- Cuenta la historia como una **leyenda heroica**. Al principio todo encaja. Poco a poco
  aparecen grietas: enemigos que suplican, cartas, aldeanos que huyen *de ti*, jefes que dicen
  cosas raras antes de morir. El narrador las justifica… cada vez con menos seguridad.

### Trama (propuesta)
- **El protagonista**, *Kael* 🔶, soldado de élite del **Regente**, recibe una misión: el reino
  se hunde en guerra y peste, y los culpables serían los "rebeldes" del General Aren, que
  envenenan pozos y queman aldeas. Kael debe eliminar a sus líderes uno por uno.
- **Cada jefe** es un líder "rebelde". Al jugar se ve que defendían algo: la Capitana Varga
  protegía una aldea en cuarentena, el Carcelero custodiaba a enfermos para que la peste no se
  extendiera, el oso blanco era la "bestia" que espantaba a los saqueadores de un paso de montaña...
- **El giro**: los rebeldes contenían la peste. El Regente la usaba para vaciar tierras y
  quedarse con el reino. Cada líder que Kael mató abrió una puerta a la enfermedad y al saqueo.
  El "General traidor" del final es el último que la contenía. El verdadero villano de la
  historia es Kael, y el Regente lo usó como arma.
- **Las muertes del jugador** encajan: el anciano corrige el relato porque *recuerda mal… o no
  quiere recordar*.

### ¿Quién es el narrador? (D9, eliges tú)
- **A)** El propio **Kael, ya viejo**, que se lo cuenta a un niño. Al final dice: *"Yo fui ese
  guerrero"*. Es una confesión y un arrepentimiento.
- **B)** El **hijo del General Aren**, que sobrevivió. Cuenta la leyenda "oficial" a propósito,
  hasta revelar quién es.
- **C)** Un **cronista del Regente** que escribió la versión heroica y al final no puede
  sostener la mentira.

Mi favorita es la **A**: le da sentido a cada *"No… no fue así"*, porque es alguien que no
quiere aceptar lo que hizo.

### Final (ideas)
- Final principal: el jugador vence al General, y el anciano termina la historia en silencio.
- Final alternativo opcional: si el jugador perdonó a ciertos enemigos durante el viaje
  (decisiones al estilo de los NPCs de Souls), puede negarse a dar el último golpe.
