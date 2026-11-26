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
| `soldier_warn_1.wav` | warn | Back! Stay away from the houses. | Subtítulo: ¡Atrás! No te acerques a las casas. |
| `soldier_surrender_1.wav` | surrender | No... no more. Take it. I only wanted to go home. | Subtítulo: No… no más. Tómala. Yo solo quería volver a casa. |
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
| `narrator_player_death_2_1.wav` | player_death_2 | No... he did not fall there. Every version agrees on that. Almost every one. | Subtítulo: No… él no cayó ahí. En eso coinciden todas las versiones. Casi todas. |
| `narrator_player_death_2_2.wav` | player_death_2 | Hm. My memory is not what it was. | Subtítulo: Mm. Mi memoria ya no es lo que era. |
| `narrator_player_death_3_1.wav` | player_death_3 | No. Let me tell it right, at least this once. | Subtítulo: No. Deja que lo cuente bien, al menos esta vez. |
| `narrator_player_death_3_2.wav` | player_death_3 | That is not how... no. Again. | Subtítulo: No fue así… no. Otra vez. |
| `narrator_player_death_4_1.wav` | player_death_4 | I wish he had fallen there. No... that's not how it happened. | Subtítulo: Ojalá hubiera caído ahí. No… no fue así. |
| `narrator_player_death_4_2.wav` | player_death_4 | Let me rest a moment. Then I'll go on. | Subtítulo: Déjame descansar un momento. Luego sigo. |
| `narrator_story_prologue.wav` | story_prologue | This is the story of a warrior who saved a kingdom. Or so the songs say. | Subtítulo: Esta es la historia de un guerrero que salvó un reino. O eso dicen las canciones. |
| `narrator_story_camp_first.wav` | story_camp_first | The warrior rested by the fire. He never slept well. Not even then. | Subtítulo: El guerrero descansó junto al fuego. Nunca dormía bien. Ni siquiera entonces. |
| `narrator_story_frank_meet.wav` | story_frank_meet | The warrior never learned to speak monkey. But that look... that look, he understood. | Subtítulo: El guerrero nunca aprendió a hablar mono. Pero aquella mirada… aquella sí la entendió. |
| `narrator_story_frank_left.wav` | story_frank_left | The warrior walked right past him. He was not proud of it. The monkey followed him anyway. | Subtítulo: El guerrero pasó de largo. No se sintió orgulloso. El mono lo siguió igual. |
| `narrator_story_prologue_order.wav` | story_prologue_order | It all began in the palace. To the warrior, it did not feel like an order. It felt like a promise. | Subtítulo: Todo empezó en el palacio. Al guerrero no le pareció una orden. Le pareció una promesa. |
| `narrator_story_prologue_summon.wav` | story_prologue_summon | They summoned the warrior at dawn. He had never stood so close to the Regent. | Subtítulo: Llamaron al guerrero al amanecer. Nunca había estado tan cerca del Regente. |
| `narrator_story_prologue_memory.wav` | story_prologue_memory | When he came home, the bed was empty. All he had left was the ribbon. | Subtítulo: Cuando volvió a casa, la cama estaba vacía. Solo le quedó la cinta. |
| `narrator_story_prologue_ribbon.wav` | story_prologue_ribbon | The warrior asked nothing more. He only looked at the ribbon on his wrist. | Subtítulo: El guerrero no preguntó nada más. Solo miró la cinta de su muñeca. |
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
| `narrator_story_frontier.wav` | story_frontier | The last cordon. No one knows anymore which part is true and which part is the song. | Subtítulo: El último cordón. Ya nadie sabe qué parte es verdad y qué parte es canción. |
| `narrator_story_aren_before.wav` | story_aren_before | General Aren did not draw his sword. He was waiting for him. He only wanted to talk. | Subtítulo: El general Aren no desenvainó. Lo estaba esperando. Solo quería hablar. |
| `narrator_story_ending_legend.wav` | story_ending_legend | The warrior saved the kingdom. That is what the songs say. I was that warrior. And I saved no one. | Subtítulo: El guerrero salvó el reino. Eso dicen las canciones. Yo fui ese guerrero. Y no salvé a nadie. |
| `narrator_story_ending_trial.wav` | story_ending_trial | I was that warrior. And at the end, I did the only thing left to me. I stopped obeying. | Subtítulo: Yo fui ese guerrero. Y al final hice lo único que me quedaba: dejé de obedecer. |

## El Regente (`regent`)

*Voz:* El Regente Malcor: hombre maduro, culto y cálido (prólogo, versión 2: tiene que parecer bueno); habla bajo, cercano, sin prisa. Kokoro: `bm_george`, con poco eco.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `regent_prologue_rise.wav` | prologue_rise | Rise, Kael. You don't kneel here. Not today. | Subtítulo: Levántate, Kael. Aquí no te arrodillas. Hoy no. |
| `regent_prologue_lira.wav` | prologue_lira | I heard about Lira. I'm sorry. Truly. The fever doesn't care whose daughter she was. | Subtítulo: Supe lo de Lira. Lo siento. De verdad. A la fiebre no le importa de quién era hija. |
| `regent_prologue_grief.wav` | prologue_grief | I have buried people this winter, too. | Subtítulo: Yo también he enterrado a gente este invierno. |
| `regent_prologue_hope.wav` | prologue_hope | There is a way no one else loses their Lira. The fever travels with people. Five of them hold the roads, and let no help through. | Subtítulo: Hay una forma de que nadie más pierda a su Lira. La fiebre viaja con la gente. Hay cinco que cierran los caminos y no dejan pasar la ayuda. |
| `regent_prologue_bram.wav` | prologue_bram | Bram. A huge man. A good one, once. Now he guards a door, and lets no one out. | Subtítulo: Bram. Un hombre enorme. Y bueno, en otro tiempo. Ahora guarda una puerta y no deja salir a nadie. |
| `regent_prologue_varga.wav` | prologue_varga | Varga. The finest captain I ever had. Something broke in her, up at the Pass. They say she burns villages. | Subtítulo: Varga. La mejor capitana que tuve. Algo se le torció en el Paso. Dicen que quema aldeas. |
| `regent_prologue_ilse.wav` | prologue_ilse | Ilse hunts in the mountains. The messengers I send up there... don't come back. | Subtítulo: Ilse caza en la montaña. Los mensajeros que envío allí… no vuelven. |
| `regent_prologue_orme.wav` | prologue_orme | Orme. The cleverest engineer in the kingdom. He holds the river dam in his hands. | Subtítulo: Orme. El ingeniero más listo del reino. Tiene la presa del río en sus manos. |
| `regent_prologue_aren.wav` | prologue_aren | And Aren. Him... you will meet at the end. | Subtítulo: Y Aren. A ese… lo conocerás al final. |
| `regent_prologue_vow_stop.wav` | prologue_vow_stop | Stop them. Yes. Do whatever is necessary, Kael. I trust your judgement. | Subtítulo: Detenerlos. Sí. Haz lo que sea necesario, Kael. Confío en tu juicio. |
| `regent_prologue_vow_end.wav` | prologue_vow_end | Let them suffer no more than they must. I trust you, Kael. | Subtítulo: Que no sufran más de lo necesario. Confío en ti, Kael. |

## Kael (`kael_scene`)

*Voz:* Kael en las escenas (la misma voz que en combate, sin eco): sereno, obediente. Kokoro: `bm_daniel`.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `kael_scene_prologue_need.wav` | prologue_need | What do you need of me, my lord? | Subtítulo: ¿Qué necesitáis de mí, mi señor? |
| `kael_scene_prologue_promise.wav` | prologue_promise | I promise. | Subtítulo: Lo prometo. |
| `kael_scene_prologue_choice_stop.wav` | prologue_choice_stop | I will stop them, my lord. | Subtítulo: Los detendré, mi señor. |
| `kael_scene_prologue_choice_end.wav` | prologue_choice_end | I will put an end to them. | Subtítulo: Acabaré con ellos. |
| `kael_scene_varga_1.wav` | varga_1 | The Regent says you burn villages. | Subtítulo: El Regente dice que quemáis aldeas. |
| `kael_scene_varga_1b.wav` | varga_1b | It's closed because you close it. His wagons bring grain and physicians, and you turn them back while those people die behind your grey cloths. | Subtítulo: Está cerrado porque tú lo cierras. Sus carros traen grano y médicos, y tú los mandas de vuelta mientras esa gente se muere detrás de tus telas grises. |
| `kael_scene_varga_1c.wav` | varga_1c | I don't need him to. My sister died of this same fever. Nobody came for her. I won't let you make anyone else wait. | Subtítulo: No necesito que me lo diga. Mi hermana murió de esta misma fiebre. Nadie vino a ayudarla. No dejaré que hagas esperar a nadie más. |
| `kael_scene_varga_2.wav` | varga_2 | I have my orders. | Subtítulo: Tengo mis órdenes. |
| `kael_scene_frank_1.wav` | frank_1 | Go on. Back to your own kind. | Subtítulo: Anda, vete. Vuelve con los tuyos. |
| `kael_scene_frank_2.wav` | frank_2 | ...Do as you like. | Subtítulo: …Haz lo que quieras. |

## Lira (`lira`)

*Voz:* Lira, la hermana de Kael, de niña (solo en el recuerdo del prólogo). Voz clara y dulce. Kokoro: `bf_emma`, más aguda.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `lira_memory_promise.wav` | memory_promise | So you come back. Promise me. | Subtítulo: Para que vuelvas. Prométemelo. |

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
| `varga_intro_1b.wav` | intro_1b | The Regent says many things. Did he also tell you why this pass is closed? | Subtítulo: El Regente dice muchas cosas. ¿Te dijo también por qué está cerrado este paso? |
| `varga_intro_2b.wav` | intro_2b | ...Then you know what it does. And still you can't see what I'm doing here. | Subtítulo: …Entonces sabes lo que hace. Y aun así no ves lo que hago aquí. |
| `varga_intro_2.wav` | intro_2 | And did he tell you why his wagons are in such a hurry to cross a closed pass? | Subtítulo: ¿Y te dijo por qué sus carros tienen tanta prisa por cruzar un paso cerrado? |
| `varga_intro_3.wav` | intro_3 | Then come. I hope you live long enough to regret them. | Subtítulo: Entonces ven. Ojalá vivas lo bastante para arrepentirte de ellas. |
| `varga_phase_1.wav` | phase | Not yet. Look at the smoke, soldier. Ask yourself what we are burning. | Subtítulo: Todavía no. Mira el humo, soldado. Pregúntate qué estamos quemando. |
| `varga_death_1.wav` | death | He told you we burned villages? Look at the smoke... look at what we burn. | Subtítulo: ¿Te dijo que quemábamos aldeas? Mira el humo… mira qué quemamos. |
| `varga_victory_1.wav` | victory | Stay down. You don't know what you're doing. | Subtítulo: No te levantes. No sabes lo que haces. |
| `varga_victory_2.wav` | victory | Go home. Tell him the Pass is closed. | Subtítulo: Vuelve a casa. Dile que el Paso está cerrado. |

## Frank (`frank`)

*Voz:* Frank, el tití: no habla, chilla. Chillidos sintetizados (tools/gen_frank.py, sin Kokoro): agudos, rápidos y tiernos. El subtítulo es lo que Kael entiende.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `frank_trapped_1.wav` | trapped | (chillido: call) | «¡Eh! ¡Tú, el de la espada! ¡Aquí arriba!» |
| `frank_trapped_2.wav` | trapped | (chillido: call) | «¡Sácame de aquí, por favor!» |
| `frank_trapped_3.wav` | trapped | (chillido: chatter) | «No muerdo. Casi nunca.» |
| `frank_meet_1.wav` | meet_1 | (chillido: happy) | «¡Por fin! Dos días aquí colgado.» |
| `frank_meet_2.wav` | meet_2 | (chillido: sad) | «Los míos no me quieren. Por los rulos.» |
| `frank_meet_3.wav` | meet_3 | (chillido: chatter) | «Me quedo contigo. Alguien tiene que cuidarte.» |
| `frank_offended_1.wav` | offended | (chillido: indignant) | «¡Ni las gracias! Ya me solté yo solo, ¿eh?» |
| `frank_offended_2.wav` | offended_2 | (chillido: chatter) | «Bueno. Te sigo igual. Alguien tiene que cuidarte.» |
| `frank_heal_danger_1.wav` | heal_danger | (chillido: indignant) | «¿Ahora? ¿En serio?» |
| `frank_heal_danger_2.wav` | heal_danger | (chillido: alarm_talk) | «¡Que te está mirando!» |
| `frank_heal_danger_3.wav` | heal_danger | (chillido: chatter) | «Vendarse delante de él… Valiente. O tonto.» |
| `frank_heal_1.wav` | heal | (chillido: chatter) | «Aprieta fuerte. Así.» |
| `frank_heal_2.wav` | heal | (chillido: twitter) | «Ya está. Como nuevo. Casi.» |
| `frank_bandages_out_1.wav` | bandages_out | (chillido: chatter) | «No quedan vendas. En un campamento te dan más.» |
| `frank_death_first_1.wav` | death_first | (chillido: chatter) | «Bueno. Otra vez. Yo no he visto nada.» |
| `frank_death_first_2.wav` | death_first | (chillido: twitter) | «Te guardé el sitio en el hombro.» |
| `frank_death_first_3.wav` | death_first | (chillido: chatter) | «Eso dolió de mirar. Vamos otra vez.» |
| `frank_death_again_1.wav` | death_again | (chillido: chatter) | «Respira. Míralo antes de pegarle.» |
| `frank_death_again_2.wav` | death_again | (chillido: happy) | «Cada vez aguantas más. Lo estoy contando.» |
| `frank_hint_soldier_1.wav` | hint_soldier | (chillido: chatter) | «Para el golpe justo cuando llega. Se cansan antes que tú.» |
| `frank_hint_soldier_2.wav` | hint_soldier | (chillido: chatter) | «Cuando se tambalea, ¡ahí! No lo dejes respirar.» |
| `frank_hint_spear_1.wav` | hint_spear | (chillido: chatter) | «La lanza llega lejos. Pégate a él.» |
| `frank_hint_spear_2.wav` | hint_spear | (chillido: chatter) | «Si pincha en rojo, no te apartes: ve hacia la punta.» |
| `frank_hint_archer_1.wav` | hint_archer | (chillido: chatter) | «El del arco no sabe pelear de cerca. Corre hacia él.» |
| `frank_hint_bandit_1.wav` | hint_bandit | (chillido: chatter) | «Ese es rápido. Espera a que falle, y entonces, tú.» |
| `frank_hint_varga_1.wav` | hint_varga | (chillido: chatter) | «Cuando salta, apártate. Cuando cae, ¡pégale!» |
| `frank_hint_varga_2.wav` | hint_varga | (chillido: chatter) | «Sus cuchillos se paran con la espada. Como un golpe más.» |
| `frank_hint_varga_3.wav` | hint_varga | (chillido: chatter) | «Cuando gira y barre en rojo… ¡salta!» |
| `frank_hint_danger_1.wav` | hint_danger | (chillido: chatter) | «Rojo es que no se para. Si barre, salta; si pincha, ve hacia él.» |
| `frank_zone_village_1.wav` | zone_village | (chillido: twitter) | «Huele a pan… y a humo. Más a humo.» |
| `frank_zone_forest_1.wav` | zone_forest | (chillido: happy) | «¡Árboles! Por fin algo de mi tamaño. Bueno, más grande.» |
| `frank_zone_fortress_1.wav` | zone_fortress | (chillido: sad) | «Muros altos. No me gustan los muros altos.» |
| `frank_rest_first_1.wav` | rest_first | (chillido: happy) | «Fuego, comida y nadie persiguiéndonos. Me gusta.» |
| `frank_rest_1.wav` | rest | (chillido: twitter) | «Duerme. Yo vigilo. …Un rato.» |
| `frank_rest_2.wav` | rest | (chillido: chatter) | «¿Has comido algo hoy? Yo sí. Tu pan.» |
| `frank_stagger_1.wav` | stagger | (chillido: alarm_talk) | «¡Respira, grandullón!» |
| `frank_stagger_2.wav` | stagger | (chillido: alarm_talk) | «¡Apártate, que viene otra!» |
| `frank_kill_1.wav` | kill | (chillido: sad) | «Ese también tenía a alguien esperándolo en casa…» |
| `frank_kill_2.wav` | kill | (chillido: sad) | «¿Seguro que eran rebeldes?» |
| `frank_kill_3.wav` | kill | (chillido: chatter) | «El Regente no se mancha las manos, ¿eh? Para eso estás tú.» |
| `frank_idle_long_1.wav` | idle_long | (chillido: chatter) | «¿Nos quedamos a vivir aquí?» |
| `frank_idle_long_2.wav` | idle_long | (chillido: chatter) | «Si no vas tú, voy yo. …No. Mejor tú.» |
| `frank_idle_long_3.wav` | idle_long | (chillido: twitter) | «Me aburro. Te voy a peinar.» |
| `frank_warn_archer_1.wav` | warn_archer | (chillido: alarm_talk) | «¡El del arco! ¡Te apunta!» |
| `frank_warn_archer_2.wav` | warn_archer | (chillido: alarm_talk) | «¡Flecha! ¡Cúbrete!» |
| `frank_warn_behind_1.wav` | warn_behind | (chillido: alarm_talk) | «¡Detrás de ti!» |
| `frank_warn_behind_2.wav` | warn_behind | (chillido: alarm_talk) | «¡Por la espalda, grandullón!» |
| `frank_warn_suspicious_1.wav` | warn_suspicious | (chillido: whisper) | «Shh… Ese ha oído algo.» |
| `frank_warn_suspicious_2.wav` | warn_suspicious | (chillido: whisper) | «Quieto. Agáchate.» |
| `frank_find_item_1.wav` | find_item | (chillido: chatter) | «¡Eh! Ahí hay algo.» |
| `frank_find_item_2.wav` | find_item | (chillido: chatter) | «Mira allí. ¿Lo ves? Yo sí.» |
| `frank_found_item_1.wav` | found_item | (chillido: happy) | «¡La mitad es mía!» |
| `frank_found_item_2.wav` | found_item | (chillido: happy) | «¿Ves? Sin mí, ni lo encuentras.» |
| `frank_poacher_note_1.wav` | poacher_note | (chillido: sad) | «…Esa jaula era para mí.» |
| `frank_gate_locked_1.wav` | gate_locked | (chillido: chatter) | «Cerrado por dentro… Déjame a mí.» |
| `frank_gate_go_1.wav` | gate_go | (chillido: chatter) | «Espera aquí. No toques nada.» |
| `frank_gate_done_1.wav` | gate_done | (chillido: happy) | «¡Pestillo fuera! De nada, ¿eh?» |
| `frank_throw_go_1.wav` | throw_go | (chillido: squeak) | little effort squeak, small monkey throwing something |
| `frank_throw_hit_1.wav` | throw_hit | (chillido: happy) | «¡En toda la cara!» |
| `frank_throw_hit_2.wav` | throw_hit | (chillido: happy) | «¡Ja! ¿Quieres otra?» |
| `frank_throw_distract_1.wav` | throw_distract | (chillido: whisper) | «Ya mira para otro lado. ¡Ahora!» |
| `frank_throw_distract_2.wav` | throw_distract | (chillido: whisper) | «Shh… Por detrás. Despacio.» |
| `frank_throw_boss_1.wav` | throw_boss | (chillido: indignant) | «Ni la ha despeinado.» |
| `frank_throw_wait_1.wav` | throw_wait | (chillido: chatter) | «Espera, que busco otra fruta.» |
| `frank_throw_wait_2.wav` | throw_wait | (chillido: chatter) | «Me la comí. Dame un momento.» |
| `frank_throw_nobody_1.wav` | throw_nobody | (chillido: chatter) | «¿A quién se la tiro? No veo a nadie.» |
| `frank_happy_1.wav` | happy | (chillido: happy) | little rising trill of a happy small monkey |
| `frank_happy_2.wav` | happy | (chillido: squeak) | short cheerful squeak |
| `frank_idle_1.wav` | idle | (chillido: twitter) | soft twittering to himself, small monkey |
| `frank_idle_2.wav` | idle | (chillido: squeak) | curious little squeak |
| `frank_scared_1.wav` | scared | (chillido: alarm) | sharp startled shriek of a small monkey |
| `frank_scared_2.wav` | scared | (chillido: squeak) | frightened squeak |

## Aldeano (`villager`)

*Voz:* Gente de la aldea, cansada y con miedo (la fiebre, los soldados del Regente). Hablan bajo y sin adornos. Una voz por persona: Aldeana `bf_alice`, Viejo `am_adam` (más lento y grave), Niño `af_sky` (más aguda), Madre `bf_lily`, Aldeano `bm_fable`.

| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |
|---|---|---|---|
| `villager_sweeper_1.wav` | sweeper | No one goes in. The captain said so. Not even for bread. | Subtítulo: No se entra. La capitana lo dijo. Ni por pan. |
| `villager_sweeper_after_1.wav` | sweeper_after | No one came to the door today. Nor yesterday. | Subtítulo: Hoy nadie vino a la puerta. Ni ayer. |
| `villager_old_man_1.wav` | old_man | My son's blankets... they burned them yesterday. Better that than the other thing. | Subtítulo: Las mantas de mi hijo… las quemaron ayer. Mejor eso que lo otro. |
| `villager_old_man_after_1.wav` | old_man_after | No one burns the clothes anymore. She said it was the only thing that worked. | Subtítulo: Ya nadie quema la ropa. Ella decía que era lo único que servía. |
| `villager_child_1.wav` | child | That's the captain. She brings us water when there's none. | Subtítulo: Es la capitana. Nos trae el agua cuando no hay. |
| `villager_child_after_1.wav` | child_after | Have you seen the captain? She didn't bring the water today. | Subtítulo: ¿Ha visto a la capitana? Hoy no ha traído el agua. |
| `villager_road_man_1.wav` | road_man | They sent soldiers, not physicians. Again. | Subtítulo: Mandaron soldados, no médicos. Otra vez. |
| `villager_road_man_after_1.wav` | road_man_after | Now the Regent's men will come. Those don't warn you. | Subtítulo: Ahora vendrán los del Regente. Esos no avisan. |
| `villager_mother_1.wav` | mother | Don't look. He's one of the Regent's men. | Subtítulo: No mires. Es de los del Regente. |
| `villager_mother_after_1.wav` | mother_after | Don't look, girl. He's leaving. | Subtítulo: No mires, hija. Ya se va. |
| `villager_child_vow_stop_1.wav` | child_vow_stop | Are you here to stop them? The bad ones, I mean? | Subtítulo: ¿Usted viene a detenerlos? ¿A los malos, digo? |
| `villager_mother_vow_stop_1.wav` | mother_vow_stop | Look, girl. Maybe this one listens. | Subtítulo: Mire, hija. Quizá este sí escucha. |
| `villager_mother_vow_end_1.wav` | mother_vow_end | Come, girl. Away from him. | Subtítulo: Ven, hija. Lejos de él. |
