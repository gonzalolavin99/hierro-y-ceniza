# 10 · Guion de voces

Archivo generado por `game/tests/export_voice_script.gd` a partir de `game/scripts/systems/voice_lines.gd`.
**No editar a mano**: cambiar las líneas en `voice_lines.gd` y volver a generarlo.

## Cómo se generan las voces

En local y gratis con **Kokoro** (modelo de voz abierto, licencia Apache 2.0: se puede usar en un juego
comercial). Instalado en `G:\Herramientas\tts`. Sin cuenta ni internet.

1. Si cambian las líneas: `--headless --path game --script res://tests/export_voice_script.gd`
   (regenera este documento y `tools/voice_lines.json`).
2. `G:\Herramientas\tts\venv\Scripts\python tools/gen_voices.py` (desde `G:\Game`): crea los `.wav` en
   `game/assets/audio/voice/<personaje>/`. Solo genera los que faltan; `--all` los rehace todos.
3. Abrir el juego: Godot los importa solo. Si falta alguno, el juego no falla: simplemente calla.

Las **frases** suenan naturales. Los **esfuerzos** (gritos, quejidos) se generan leyendo una interjección
(columna *Lee*); son la parte más débil. Para mejorarlos, sustituir el `.wav` por uno grabado o de un banco
de sonidos libre (CC0) con el mismo nombre. La descripción indica cómo debería sonar.

Guía de contenido (docs/04): nada sobrenatural en ningún texto. La prueba `voice_test` lo revisa sola.

## Kael (`kael`)

*Voz:* Hombre de unos 30 años, soldado de élite. Voz grave y contenida; en combate, esfuerzos secos y controlados. Kokoro: `bm_daniel`.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `kael_attack_1.wav` | attack | Hut! | short sharp exhale through clenched teeth while swinging a sword, adult man |
| `kael_attack_2.wav` | attack | Hup! | quick low grunt of effort, adult man, sword swing |
| `kael_attack_3.wav` | attack | Hah! | brief controlled 'hah' of exertion, adult man |
| `kael_heavy_1.wav` | heavy | Haraah! | strong full-body grunt, adult man bringing a heavy sword down |
| `kael_heavy_2.wav` | heavy | Hyah! | forceful 'hyah', adult man, overhead strike |
| `kael_art_1.wav` | art | Haaah! | short fierce battle shout, adult man, controlled and determined |
| `kael_art_2.wav` | art | Rraaagh! | deep roar of effort, adult man, leaping sword attack |
| `kael_throw_1.wav` | throw | Huff! | quick exhale, adult man throwing a small object |
| `kael_hurt_1.wav` | hurt | Ugh! | pained grunt, adult man struck by a blade |
| `kael_hurt_2.wav` | hurt | Agh! | sharp gasp of pain, adult man |
| `kael_hurt_3.wav` | hurt | Ungh... | teeth-gritted groan of pain, adult man |
| `kael_deathblow_1.wav` | deathblow | Haaah... | low heavy exhale after a decisive final sword strike, adult man |
| `kael_death_1.wav` | death | Aaagh... ahh... | dying groan, adult man collapsing to the ground |

## Soldado (`soldier`)

*Voz:* Hombre de mediana edad, soldado raso curtido. Voz áspera y ruda. Kokoro: `am_onyx`, con algo de aspereza.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `soldier_spot_1.wav` | spot | You shouldn't have come here. | Subtítulo: No deberías haber venido. |
| `soldier_spot_2.wav` | spot | Halt! Who goes there? | Subtítulo: ¡Alto! ¿Quién va? |
| `soldier_spot_3.wav` | spot | Draw your blade. | Subtítulo: Desenvaina. |
| `soldier_attack_1.wav` | attack | Rah! | rough grunt, middle-aged man swinging a sword |
| `soldier_attack_2.wav` | attack | Hup! | short aggressive 'hup', middle-aged man |
| `soldier_danger_1.wav` | danger | Raaaagh! | loud aggressive war cry, middle-aged man, before a powerful attack |
| `soldier_danger_2.wav` | danger | Hyaaah! | deep shout of effort, middle-aged man, charging |
| `soldier_hurt_1.wav` | hurt | Ugh! | pained grunt, middle-aged man |
| `soldier_hurt_2.wav` | hurt | Aagh! | sharp cry of pain, middle-aged man |
| `soldier_broken_1.wav` | broken | Hah... agh... | staggered, out-of-breath groan, middle-aged man losing balance |
| `soldier_death_1.wav` | death | Aaargh... ahh... | final dying exhale, middle-aged man |
| `soldier_victory_1.wav` | victory | Stay down. | Subtítulo: No te levantes. |
| `soldier_victory_2.wav` | victory | That's the end of you. | Subtítulo: Hasta aquí llegaste. |

## El anciano (`narrator`)

*Voz:* Kael anciano contando la historia junto a una fogata. Voz grave y gastada; habla despacio, dubitativo al corregirse. Kokoro: `bm_lewis`, más lenta y grave, con eco de sala.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `narrator_death_1.wav` | player_death | No... no, that's not how it happened. | Subtítulo: No… no fue así. |
| `narrator_death_2.wav` | player_death | Wait. Let me start again. | Subtítulo: Espera. Déjame empezar de nuevo. |
| `narrator_death_3.wav` | player_death | No... I'm getting ahead of myself. | Subtítulo: No… me estoy adelantando. |
