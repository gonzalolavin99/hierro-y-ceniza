# 10 · Guion de voces (ElevenLabs)

Archivo generado por `game/tests/export_voice_script.gd` a partir de `game/scripts/systems/voice_lines.gd`.
**No editar a mano**: cambiar las líneas en `voice_lines.gd` y volver a generarlo.

## Cómo generar las voces

1. **Frases** (tienen texto): en ElevenLabs → *Text to Speech*, con la voz descrita para cada personaje.
   Pegar el texto en inglés tal cual. El subtítulo en español ya está en el juego.
2. **Esfuerzos** (gritos, quejidos, respiraciones): en ElevenLabs → *Sound Effects*, pegando la descripción.
   Generar 2–3 versiones y quedarse con la más natural y corta (menos de 1 segundo).
3. Descargar en **MP3** y guardar con el **nombre exacto** de la columna *Archivo* en
   `game/assets/audio/voice/<personaje>/` (por ejemplo `game/assets/audio/voice/kael/kael_hurt_1.mp3`).
4. Abrir el juego (F5): Godot importa los archivos solo. Si falta alguno, el juego no falla: simplemente calla.

Recordatorio de la guía de contenido (docs/04): nada sobrenatural en ningún texto.
La prueba `voice_test` revisa automáticamente que no aparezcan palabras prohibidas.

## Kael (`kael`)

*Voz:* Hombre de unos 30 años, soldado de élite. Voz grave y contenida; en combate, esfuerzos secos y controlados, nunca exagerados.

| Archivo | Cuándo suena | Tipo | Texto en inglés / descripción del esfuerzo | Subtítulo |
|---|---|---|---|---|
| `kael_attack_1.mp3` | attack | Esfuerzo | short sharp exhale through clenched teeth while swinging a sword, adult man | — |
| `kael_attack_2.mp3` | attack | Esfuerzo | quick low grunt of effort, adult man, sword swing | — |
| `kael_attack_3.mp3` | attack | Esfuerzo | brief controlled 'hah' of exertion, adult man | — |
| `kael_heavy_1.mp3` | heavy | Esfuerzo | strong full-body grunt, adult man bringing a heavy sword down | — |
| `kael_heavy_2.mp3` | heavy | Esfuerzo | forceful 'hyah', adult man, overhead strike | — |
| `kael_art_1.mp3` | art | Esfuerzo | short fierce battle shout, adult man, controlled and determined | — |
| `kael_art_2.mp3` | art | Esfuerzo | deep roar of effort, adult man, leaping sword attack | — |
| `kael_throw_1.mp3` | throw | Esfuerzo | quick exhale, adult man throwing a small object | — |
| `kael_hurt_1.mp3` | hurt | Esfuerzo | pained grunt, adult man struck by a blade | — |
| `kael_hurt_2.mp3` | hurt | Esfuerzo | sharp gasp of pain, adult man | — |
| `kael_hurt_3.mp3` | hurt | Esfuerzo | teeth-gritted groan of pain, adult man | — |
| `kael_deathblow_1.mp3` | deathblow | Esfuerzo | low heavy exhale after a decisive final sword strike, adult man | — |
| `kael_death_1.mp3` | death | Esfuerzo | dying groan, adult man collapsing to the ground | — |

## Soldado (`soldier`)

*Voz:* Hombre de mediana edad, soldado raso curtido. Voz áspera y ruda, algo cansada.

| Archivo | Cuándo suena | Tipo | Texto en inglés / descripción del esfuerzo | Subtítulo |
|---|---|---|---|---|
| `soldier_spot_1.mp3` | spot | Frase | You shouldn't have come here. | No deberías haber venido. |
| `soldier_spot_2.mp3` | spot | Frase | Halt! Who goes there? | ¡Alto! ¿Quién va? |
| `soldier_spot_3.mp3` | spot | Frase | Draw your blade. | Desenvaina. |
| `soldier_attack_1.mp3` | attack | Esfuerzo | rough grunt, middle-aged man swinging a sword | — |
| `soldier_attack_2.mp3` | attack | Esfuerzo | short aggressive 'hup', middle-aged man | — |
| `soldier_danger_1.mp3` | danger | Esfuerzo | loud aggressive war cry, middle-aged man, before a powerful attack | — |
| `soldier_danger_2.mp3` | danger | Esfuerzo | deep shout of effort, middle-aged man, charging | — |
| `soldier_hurt_1.mp3` | hurt | Esfuerzo | pained grunt, middle-aged man | — |
| `soldier_hurt_2.mp3` | hurt | Esfuerzo | sharp cry of pain, middle-aged man | — |
| `soldier_broken_1.mp3` | broken | Esfuerzo | staggered, out-of-breath groan, middle-aged man losing balance | — |
| `soldier_death_1.mp3` | death | Esfuerzo | final dying exhale, middle-aged man | — |
| `soldier_victory_1.mp3` | victory | Frase | Stay down. | No te levantes. |
| `soldier_victory_2.mp3` | victory | Frase | That's the end of you. | Hasta aquí llegaste. |

## El anciano (`narrator`)

*Voz:* Kael anciano (unos 70 años) contando la historia junto a una fogata. Voz cálida, grave y gastada; habla despacio. Al morir el jugador suena dubitativo, como quien se corrige.

| Archivo | Cuándo suena | Tipo | Texto en inglés / descripción del esfuerzo | Subtítulo |
|---|---|---|---|---|
| `narrator_death_1.mp3` | player_death | Frase | No... no, that's not how it happened. | No… no fue así. |
| `narrator_death_2.mp3` | player_death | Frase | Wait. Let me start again. | Espera. Déjame empezar de nuevo. |
| `narrator_death_3.mp3` | player_death | Frase | No... I'm getting ahead of myself. | No… me estoy adelantando. |
