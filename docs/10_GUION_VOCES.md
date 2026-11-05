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
| `narrator_player_death_2_1.wav` | player_death_2 | No... he did not fall there. That much I remember. I think. | Subtítulo: No… él no cayó ahí. Eso lo recuerdo bien. Creo. |
| `narrator_player_death_2_2.wav` | player_death_2 | Hm. My memory is not what it was. | Subtítulo: Mm. Mi memoria ya no es lo que era. |
| `narrator_player_death_3_1.wav` | player_death_3 | No. Let me tell it right, at least this once. | Subtítulo: No. Deja que lo cuente bien, al menos esta vez. |
| `narrator_player_death_3_2.wav` | player_death_3 | That is not how... no. Again. | Subtítulo: No fue así… no. Otra vez. |
| `narrator_player_death_4_1.wav` | player_death_4 | I wish he had fallen there. No... that's not how it happened. | Subtítulo: Ojalá hubiera caído ahí. No… no fue así. |
| `narrator_player_death_4_2.wav` | player_death_4 | Let me rest a moment. Then I'll go on. | Subtítulo: Déjame descansar un momento. Luego sigo. |
| `narrator_story_prologue.wav` | story_prologue | This is the story of a warrior who saved a kingdom. Or so the songs say. | Subtítulo: Esta es la historia de un guerrero que salvó un reino. O eso dicen las canciones. |
| `narrator_story_camp_first.wav` | story_camp_first | The warrior rested by the fire. He never slept well. Not even then. | Subtítulo: El guerrero descansó junto al fuego. Nunca dormía bien. Ni siquiera entonces. |
| `narrator_story_prologue_order.wav` | story_prologue_order | It began with an order, in a hall of cold stone. | Subtítulo: Todo empezó con una orden, en una sala de piedra fría. |
| `narrator_story_prologue_summon.wav` | story_prologue_summon | They summoned the warrior at dawn. He had never stood so close to the Regent. | Subtítulo: Llamaron al guerrero al amanecer. Nunca había estado tan cerca del Regente. |
| `narrator_story_prologue_ribbon.wav` | story_prologue_ribbon | The warrior did not ask a single question. He only looked at the ribbon on his wrist. | Subtítulo: El guerrero no hizo ni una pregunta. Solo miró la cinta de su muñeca. |
| `narrator_story_prologue_end.wav` | story_prologue_end | His sister's ribbon. And at dawn, he set out for the Iron Pass. | Subtítulo: La cinta de su hermana. Y al amanecer partió hacia el Paso de Hierro. |
| `narrator_story_pass_village.wav` | story_pass_village | The village at the Iron Pass. The rebels had burned it. Everyone knew that. | Subtítulo: La aldea del Paso de Hierro. Los rebeldes la habían quemado. Todos lo sabían. |
| `narrator_story_pass_forest.wav` | story_pass_forest | Smoke rose above the trees. The warrior thought of his sister, and walked faster. | Subtítulo: Sobre los árboles subía humo. El guerrero pensó en su hermana y apuró el paso. |
| `narrator_story_pass_fortress.wav` | story_pass_fortress | The fortress gate. Behind it waited the Jailer and his chain. | Subtítulo: La puerta de la fortaleza. Tras ella esperaban el Carcelero y su cadena. |
| `narrator_story_bram_before.wav` | story_bram_before | They said the Jailer kept prisoners in the dark. They said a lot of things. | Subtítulo: Decían que el Carcelero tenía prisioneros a oscuras. Decían muchas cosas. |
| `narrator_story_bram_after.wav` | story_bram_after | The gate opened. People came out. He did not ask who they were. | Subtítulo: El portón se abrió. Salió gente. Él no preguntó quiénes eran. |
| `narrator_story_varga_before.wav` | story_varga_before | Captain Varga. The finest blade of the rebellion. And the cruelest, they said. | Subtítulo: La capitana Varga. La mejor espada de la rebelión. Y la más cruel, decían. |
| `narrator_story_varga_after.wav` | story_varga_after | The Pass was free. The Regent's wagons rolled in the next morning. Free... yes. | Subtítulo: El Paso quedó libre. Las caravanas del Regente entraron a la mañana siguiente. Libre… sí. |
| `narrator_story_mountain.wav` | story_mountain | The High Mountain. The villagers ran when they saw him. Fear of the war, I suppose. | Subtítulo: La Montaña Alta. Los aldeanos huían al verlo. Miedo a la guerra, supongo. |
| `narrator_story_ilse_before.wav` | story_ilse_before | Ilse the Huntress guarded the mountain road. Against whom, he never asked. | Subtítulo: Ilse, la Cazadora, vigilaba el camino de la montaña. Contra quién, él nunca lo preguntó. |
| `narrator_story_ilse_after.wav` | story_ilse_after | The road was open. Others climbed it after him. Many others. | Subtítulo: El camino quedó abierto. Otros subieron detrás de él. Muchos otros. |
| `narrator_story_river.wav` | story_river | The River City. Its wells were sealed, with signs he did not stop to read. | Subtítulo: La Ciudad del Río. Sus pozos estaban tapiados, con carteles que no se paró a leer. |
| `narrator_story_orme_before.wav` | story_orme_before | The Engineer and his great machine. A weapon against the capital. That is what they told him. | Subtítulo: El Ingeniero y su gran máquina. Un arma contra la capital. Eso le dijeron. |
| `narrator_story_orme_after.wav` | story_orme_after | He did not read the letter on the Engineer's desk. No... he read it. He kept it. | Subtítulo: No leyó la carta de la mesa del Ingeniero. No… sí la leyó. La guardó. |
| `narrator_story_frontier.wav` | story_frontier | The last cordon. I no longer know which part is mine and which part is the song. | Subtítulo: El último cordón. Ya no sé qué parte es mía y qué parte es la canción. |
| `narrator_story_aren_before.wav` | story_aren_before | General Aren did not draw his sword. He was waiting for him. He only wanted to talk. | Subtítulo: El general Aren no desenvainó. Lo estaba esperando. Solo quería hablar. |
| `narrator_story_ending_legend.wav` | story_ending_legend | The warrior saved the kingdom. That is what the songs say. I was that warrior. And I saved no one. | Subtítulo: El guerrero salvó el reino. Eso dicen las canciones. Yo fui ese guerrero. Y no salvé a nadie. |
| `narrator_story_ending_trial.wav` | story_ending_trial | I was that warrior. And at the end, I did the only thing left to me. I stopped obeying. | Subtítulo: Yo fui ese guerrero. Y al final hice lo único que me quedaba: dejé de obedecer. |

## El Regente (`regent`)

*Voz:* El Regente Malcor: hombre maduro, culto y frío; habla bajo, sin prisa, sin levantar la voz. Kokoro: `bm_george`, algo más grave, con eco de sala de piedra.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `regent_prologue_order.wav` | prologue_order | Five names. Five cordons. When they fall, the fever ends. | Subtítulo: Cinco nombres. Cinco cordones. Cuando caigan, la fiebre se acaba. |
| `regent_prologue_rebels.wav` | prologue_rebels | Traitors. They foul the wells and burn every village that will not feed them. | Subtítulo: Traidores. Ensucian los pozos y queman cada aldea que no los alimenta. |
| `regent_prologue_names.wav` | prologue_names | Here are their names. Bring me their banners, one by one. | Subtítulo: Aquí tienes sus nombres. Tráeme sus estandartes, uno por uno. |
| `regent_prologue_sister.wav` | prologue_sister | The fever took your sister, Kael. The rebels brought it to us. Make them pay. | Subtítulo: La fiebre se llevó a tu hermana, Kael. Nos la trajeron los rebeldes. Haz que paguen. |

## Kael (`kael_scene`)

*Voz:* Kael en las escenas (la misma voz que en combate, sin eco): sereno, obediente. Kokoro: `bm_daniel`.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `kael_scene_prologue_who.wav` | prologue_who | Who are they, my lord? | Subtítulo: ¿Quiénes son, mi señor? |
| `kael_scene_varga_1.wav` | varga_1 | The Regent says you burn villages. | Subtítulo: El Regente dice que quemáis aldeas. |
| `kael_scene_varga_2.wav` | varga_2 | I have my orders. | Subtítulo: Tengo mis órdenes. |
| `kael_scene_prologue_answer.wav` | prologue_answer | It will be done. | Subtítulo: Así se hará. |

## Varga (`varga`)

*Voz:* La Capitana Varga: mujer de unos 40 años, duelista y soldado veterana. Voz firme y cortante, cansada de la guerra; nunca grita salvo en los ataques peligrosos. Kokoro: `bf_isabella`, algo más grave.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `varga_spot_1.wav` | spot | So the Regent finally sent his hound. Draw, then. | Subtítulo: Así que el Regente por fin envió a su perro. Desenvaina, entonces. |
| `varga_spot_2.wav` | spot | You're far from the capital, soldier. You should have stayed there. | Subtítulo: Estás lejos de la capital, soldado. Deberías haberte quedado allí. |
| `varga_attack_1.wav` | attack | Hah! | short sharp exhale, adult woman, swift sword strike |
| `varga_attack_2.wav` | attack | Hup! | quick clipped grunt, adult woman, fencing lunge |
| `varga_attack_3.wav` | attack | Hyah! | light fierce cry, adult woman, fast slash |
| `varga_danger_1.wav` | danger | Haaah! | fierce battle shout, adult woman, before a powerful lunge |
| `varga_hurt_1.wav` | hurt | Ugh! | pained grunt, adult woman, struck by a blade |
| `varga_hurt_2.wav` | hurt | Ah! | sharp gasp of pain, adult woman |
| `varga_broken_1.wav` | broken | Hah... hah... | out of breath, adult woman losing her balance |
| `varga_intro_1.wav` | intro_1 | Stop there. That smoke is not a village burning. It's their clothes. The sick ones. | Subtítulo: Alto ahí. Ese humo no es una aldea ardiendo. Es su ropa. La de los enfermos. |
| `varga_intro_2.wav` | intro_2 | And did he tell you why his wagons are in such a hurry to cross a closed pass? | Subtítulo: ¿Y te dijo por qué sus carros tienen tanta prisa por cruzar un paso cerrado? |
| `varga_intro_3.wav` | intro_3 | Then come. I hope you live long enough to regret them. | Subtítulo: Entonces ven. Ojalá vivas lo bastante para arrepentirte de ellas. |
| `varga_phase_1.wav` | phase | Not yet. Look at the smoke, soldier. Ask yourself what we are burning. | Subtítulo: Todavía no. Mira el humo, soldado. Pregúntate qué estamos quemando. |
| `varga_death_1.wav` | death | He told you we burned villages? Look at the smoke... look at what we burn. | Subtítulo: ¿Te dijo que quemábamos aldeas? Mira el humo… mira qué quemamos. |
| `varga_victory_1.wav` | victory | Stay down. You don't know what you're doing. | Subtítulo: No te levantes. No sabes lo que haces. |
| `varga_victory_2.wav` | victory | Go home. Tell him the Pass is closed. | Subtítulo: Vuelve a casa. Dile que el Paso está cerrado. |
