class_name VoiceLines
extends RefCounted
## Todo lo que dicen (o resoplan) los personajes. Voces en inglés con subtítulos en español (D8).
## Los archivos se generan en local con tools/gen_voices.py (voz Kokoro, gratuita) y se guardan como
## assets/audio/voice/<personaje>/<id>.wav (o .mp3 / .ogg). Si falta un archivo, el juego no falla.
##
## Por evento: chance (0–1, probabilidad de hablar), cooldown (segundos sin repetir ese evento) y
## lines: frases {id, en, es} (llevan subtítulo) o esfuerzos {id, say, effort}: `say` es la interjección que lee
## el generador de voz local (tools/gen_voices.py) y `effort` la descripción del sonido buscado.
## Frank (el tití) no habla: sus líneas son chillidos {id, chirp, es} o {id, chirp, effort}. `chirp` es el tipo de
## chillido que sintetiza tools/gen_frank.py y `es`, lo que Kael entiende (va entre «»).

## Nombre que aparece en los subtítulos.
const SPEAKER_NAMES: Dictionary = {&"kael": "Kael", &"soldier": "Soldado", &"narrator": "El anciano", &"regent": "El Regente", &"kael_scene": "Kael", &"varga": "Varga", &"frank": "Frank", &"lira": "Lira"}
## Voces que no salen de un personaje del nivel (el narrador; el Regente en las escenas): suenan igual en
## todas partes (no posicionales) y mandan sobre las demás.
const NARRATORS: Array[StringName] = [&"narrator", &"regent", &"kael_scene", &"lira"]
## Volumen propio (dB) de algunos personajes: Frank, más bajito (que acompañe, no que moleste).
const VOLUME_DB: Dictionary = {&"frank": -7.0}
## Importancia de cada evento cuando varias voces coinciden: la más importante interrumpe a la menos
## importante del mismo personaje o, si ya suenan demasiadas, a la menos importante de la escena.
## Los eventos que no aparecen valen 1 (esfuerzos de ataque, lanzar…).
const EVENT_PRIORITY: Dictionary = {
	&"player_death": 4, &"player_death_2": 4, &"player_death_3": 4, &"player_death_4": 4,
	&"death": 3, &"spot": 3, &"warn": 3, &"victory": 3,
	&"danger": 2, &"broken": 2, &"hurt": 2, &"deathblow": 2,
	&"offended": 3, &"offended_2": 3, &"meet_1": 3, &"meet_2": 3, &"meet_3": 3, &"scared": 2,
	&"hint_soldier": 3, &"hint_spear": 3, &"hint_archer": 3, &"hint_bandit": 3, &"hint_varga": 3, &"hint_danger": 3,
	&"death_first": 3, &"death_again": 3, &"heal_danger": 2, &"bandages_out": 2,
	&"warn_archer": 3, &"warn_behind": 3, &"warn_suspicious": 3, &"find_item": 2, &"gate_go": 3, &"gate_locked": 3, &"gate_done": 3,
	&"poacher_note": 3, &"throw_go": 2, &"throw_hit": 3, &"throw_distract": 3, &"throw_boss": 3,
}

const LINES: Dictionary = {
	&"kael": {
		&"attack": {"chance": 0.35, "cooldown": 0.6, "lines": [
			{"id": "kael_attack_1", "say": "Hut!", "effort": "short sharp exhale through clenched teeth while swinging a sword, adult man"},
			{"id": "kael_attack_2", "say": "Hup!", "effort": "quick low grunt of effort, adult man, sword swing"},
			{"id": "kael_attack_3", "say": "Hah!", "effort": "brief controlled 'hah' of exertion, adult man"},
		]},
		&"heavy": {"chance": 1.0, "cooldown": 0.8, "lines": [
			{"id": "kael_heavy_1", "say": "Haraah!", "effort": "strong full-body grunt, adult man bringing a heavy sword down"},
			{"id": "kael_heavy_2", "say": "Hyah!", "effort": "forceful 'hyah', adult man, overhead strike"},
		]},
		&"art": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "kael_art_1", "say": "Haaah!", "effort": "short fierce battle shout, adult man, controlled and determined"},
			{"id": "kael_art_2", "say": "Rraaagh!", "effort": "deep roar of effort, adult man, leaping sword attack"},
		]},
		&"throw": {"chance": 0.7, "cooldown": 0.8, "lines": [
			{"id": "kael_throw_1", "say": "Huff!", "effort": "quick exhale, adult man throwing a small object"},
		]},
		&"hurt": {"chance": 1.0, "cooldown": 0.6, "lines": [
			{"id": "kael_hurt_1", "say": "Ugh!", "effort": "pained grunt, adult man struck by a blade"},
			{"id": "kael_hurt_2", "say": "Agh!", "effort": "sharp gasp of pain, adult man"},
			{"id": "kael_hurt_3", "say": "Ungh...", "effort": "teeth-gritted groan of pain, adult man"},
		]},
		&"deathblow": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "kael_deathblow_1", "say": "Haaah...", "effort": "low heavy exhale after a decisive final sword strike, adult man"},
		]},
		&"death": {"chance": 1.0, "cooldown": 2.0, "lines": [
			{"id": "kael_death_1", "say": "Aaagh... ahh...", "effort": "dying groan, adult man collapsing to the ground"},
		]},
	},
	&"soldier": {
		&"spot": {"chance": 1.0, "cooldown": 20.0, "lines": [
			{"id": "soldier_spot_1", "en": "You shouldn't have come here.", "es": "No deberías haber venido."},
			{"id": "soldier_spot_2", "en": "Halt! Who goes there?", "es": "¡Alto! ¿Quién va?"},
			{"id": "soldier_spot_3", "en": "Draw your blade.", "es": "Desenvaina."},
		]},
		# Paso 4: los soldados de la aldea avisan antes de atacar (estado Warn). De momento solo subtítulo (sin .wav).
		&"warn": {"chance": 1.0, "cooldown": 5.0, "lines": [
			{"id": "soldier_warn_1", "en": "Back! Stay away from the houses.", "es": "¡Atrás! No te acerques a las casas."},
		]},
		&"attack": {"chance": 0.4, "cooldown": 0.7, "lines": [
			{"id": "soldier_attack_1", "say": "Rah!", "effort": "rough grunt, middle-aged man swinging a sword"},
			{"id": "soldier_attack_2", "say": "Hup!", "effort": "short aggressive 'hup', middle-aged man"},
		]},
		&"danger": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "soldier_danger_1", "say": "Raaaagh!", "effort": "loud aggressive war cry, middle-aged man, before a powerful attack"},
			{"id": "soldier_danger_2", "say": "Hyaaah!", "effort": "deep shout of effort, middle-aged man, charging"},
		]},
		&"hurt": {"chance": 0.8, "cooldown": 0.6, "lines": [
			{"id": "soldier_hurt_1", "say": "Ugh!", "effort": "pained grunt, middle-aged man"},
			{"id": "soldier_hurt_2", "say": "Aagh!", "effort": "sharp cry of pain, middle-aged man"},
		]},
		&"broken": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "soldier_broken_1", "say": "Hah... agh...", "effort": "staggered, out-of-breath groan, middle-aged man losing balance"},
		]},
		&"death": {"chance": 1.0, "cooldown": 2.0, "lines": [
			{"id": "soldier_death_1", "say": "Aaargh... ahh...", "effort": "final dying exhale, middle-aged man"},
		]},
		&"victory": {"chance": 1.0, "cooldown": 10.0, "lines": [
			{"id": "soldier_victory_1", "en": "Stay down.", "es": "No te levantes."},
			{"id": "soldier_victory_2", "en": "That's the end of you.", "es": "Hasta aquí llegaste."},
		]},
	},
	&"narrator": {
		# Al morir Kael: el anciano se corrige. Una lista por acto (Story.death_event()); envejecen con la historia.
		&"player_death": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_death_1", "en": "No... no, that's not how it happened.", "es": "No… no fue así."},
			{"id": "narrator_death_2", "en": "Wait. Let me start again.", "es": "Espera. Déjame empezar de nuevo."},
			{"id": "narrator_death_3", "en": "No... I'm getting ahead of myself.", "es": "No… me estoy adelantando."},
		]},
		&"player_death_2": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_player_death_2_1", "en": "No... he did not fall there. Every version agrees on that. Almost every one.", "es": "No… él no cayó ahí. En eso coinciden todas las versiones. Casi todas."},
			{"id": "narrator_player_death_2_2", "en": "Hm. My memory is not what it was.", "es": "Mm. Mi memoria ya no es lo que era."},
		]},
		&"player_death_3": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_player_death_3_1", "en": "No. Let me tell it right, at least this once.", "es": "No. Deja que lo cuente bien, al menos esta vez."},
			{"id": "narrator_player_death_3_2", "en": "That is not how... no. Again.", "es": "No fue así… no. Otra vez."},
		]},
		&"player_death_4": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_player_death_4_1", "en": "I wish he had fallen there. No... that's not how it happened.", "es": "Ojalá hubiera caído ahí. No… no fue así."},
			{"id": "narrator_player_death_4_2", "en": "Let me rest a moment. Then I'll go on.", "es": "Déjame descansar un momento. Luego sigo."},
		]},
		# Narraciones de historia (Story.narrate): suenan una sola vez por partida. Ver docs/11_GUION.md.
		# Prólogo y campamento.
		&"story_prologue": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue", "en": "This is the story of a warrior who saved a kingdom. Or so the songs say.", "es": "Esta es la historia de un guerrero que salvó un reino. O eso dicen las canciones."},
		]},
		&"story_camp_first": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_camp_first", "en": "The warrior rested by the fire. He never slept well. Not even then.", "es": "El guerrero descansó junto al fuego. Nunca dormía bien. Ni siquiera entonces."},
		]},
		# Frank (escena de la red, FrankMeet; o si Kael pasa de largo).
		&"story_frank_meet": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_frank_meet", "en": "The warrior never learned to speak monkey. But that look... that look, he understood.", "es": "El guerrero nunca aprendió a hablar mono. Pero aquella mirada… aquella sí la entendió."},
		]},
		&"story_frank_left": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_frank_left", "en": "The warrior walked right past him. He was not proud of it. The monkey followed him anyway.", "es": "El guerrero pasó de largo. No se sintió orgulloso. El mono lo siguió igual."},
		]},
		# Escena del prólogo (PrologueScene), después de story_prologue.
		&"story_prologue_order": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue_order", "en": "It all began in the palace. To the warrior, it did not feel like an order. It felt like a promise.", "es": "Todo empezó en el palacio. Al guerrero no le pareció una orden. Le pareció una promesa."},
		]},
		&"story_prologue_summon": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue_summon", "en": "They summoned the warrior at dawn. He had never stood so close to the Regent.", "es": "Llamaron al guerrero al amanecer. Nunca había estado tan cerca del Regente."},
		]},
		&"story_prologue_memory": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue_memory", "en": "When he came home, the bed was empty. All he had left was the ribbon.", "es": "Cuando volvió a casa, la cama estaba vacía. Solo le quedó la cinta."},
		]},
		&"story_prologue_ribbon": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue_ribbon", "en": "The warrior asked nothing more. He only looked at the ribbon on his wrist.", "es": "El guerrero no preguntó nada más. Solo miró la cinta de su muñeca."},
		]},
		&"story_prologue_end": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue_end", "en": "His sister's ribbon. And at dawn, he set out for the Iron Pass.", "es": "La cinta de su hermana. Y al amanecer partió hacia el Paso de Hierro."},
		]},
		# Acto I: el Paso de Hierro.
		&"story_pass_village": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_pass_village", "en": "The village at the Iron Pass. The rebels had burned it. Everyone knew that.", "es": "La aldea del Paso de Hierro. Los rebeldes la habían quemado. Todos lo sabían."},
		]},
		&"story_pass_forest": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_pass_forest", "en": "Smoke rose above the trees. The warrior thought of his sister, and walked faster.", "es": "Sobre los árboles subía humo. El guerrero pensó en su hermana y apuró el paso."},
		]},
		&"story_pass_fortress": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_pass_fortress", "en": "The fortress gate. Behind it waited the Jailer and his chain.", "es": "La puerta de la fortaleza. Tras ella esperaban el Carcelero y su cadena."},
		]},
		&"story_bram_before": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_bram_before", "en": "They said the Jailer kept prisoners in the dark. They said a lot of things.", "es": "Decían que el Carcelero tenía prisioneros a oscuras. Decían muchas cosas."},
		]},
		&"story_bram_after": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_bram_after", "en": "The gate opened. People came out. He did not ask who they were.", "es": "El portón se abrió. Salió gente. Él no preguntó quiénes eran."},
		]},
		&"story_varga_before": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_varga_before", "en": "Captain Varga. The finest blade of the rebellion. And the cruelest, they said.", "es": "La capitana Varga. La mejor espada de la rebelión. Y la más cruel, decían."},
		]},
		&"story_varga_after": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_varga_after", "en": "The Pass was free. The Regent's wagons rolled in the next morning. Free... yes.", "es": "El Paso quedó libre. Las caravanas del Regente entraron a la mañana siguiente. Libre… sí."},
		]},
		# Acto II: la Montaña Alta.
		&"story_mountain": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_mountain", "en": "The High Mountain. The villagers ran when they saw him. Fear of the war, I suppose.", "es": "La Montaña Alta. Los aldeanos huían al verlo. Miedo a la guerra, supongo."},
		]},
		&"story_ilse_before": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_ilse_before", "en": "Ilse the Huntress guarded the mountain road. Against whom, he never asked.", "es": "Ilse, la Cazadora, vigilaba el camino de la montaña. Contra quién, él nunca lo preguntó."},
		]},
		&"story_ilse_after": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_ilse_after", "en": "The road was open. Others climbed it after him. Many others.", "es": "El camino quedó abierto. Otros subieron detrás de él. Muchos otros."},
		]},
		# Acto III: la Ciudad del Río.
		&"story_river": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_river", "en": "The River City. Its wells were sealed, with signs he did not stop to read.", "es": "La Ciudad del Río. Sus pozos estaban tapiados, con carteles que no se paró a leer."},
		]},
		&"story_orme_before": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_orme_before", "en": "The Engineer and his great machine. A weapon against the capital. That is what they told him.", "es": "El Ingeniero y su gran máquina. Un arma contra la capital. Eso le dijeron."},
		]},
		&"story_orme_after": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_orme_after", "en": "He did not read the letter on the Engineer's desk. No... he read it. He kept it.", "es": "No leyó la carta de la mesa del Ingeniero. No… sí la leyó. La guardó."},
		]},
		# Acto IV: la Frontera.
		&"story_frontier": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_frontier", "en": "The last cordon. No one knows anymore which part is true and which part is the song.", "es": "El último cordón. Ya nadie sabe qué parte es verdad y qué parte es canción."},
		]},
		&"story_aren_before": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_aren_before", "en": "General Aren did not draw his sword. He was waiting for him. He only wanted to talk.", "es": "El general Aren no desenvainó. Lo estaba esperando. Solo quería hablar."},
		]},
		# Los dos finales (epílogo junto a la fogata).
		&"story_ending_legend": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_ending_legend", "en": "The warrior saved the kingdom. That is what the songs say. I was that warrior. And I saved no one.", "es": "El guerrero salvó el reino. Eso dicen las canciones. Yo fui ese guerrero. Y no salvé a nadie."},
		]},
		&"story_ending_trial": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_ending_trial", "en": "I was that warrior. And at the end, I did the only thing left to me. I stopped obeying.", "es": "Yo fui ese guerrero. Y al final hice lo único que me quedaba: dejé de obedecer."},
		]},
	},
	# El Regente Malcor: solo habla en las escenas (no está en el nivel).
	# El Regente (prólogo, versión 2): cálido, cercano, nunca dice "curar".
	&"regent": {
		&"prologue_rise": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_rise", "en": "Rise, Kael. You don't kneel here. Not today.", "es": "Levántate, Kael. Aquí no te arrodillas. Hoy no."},
		]},
		&"prologue_lira": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_lira", "en": "I heard about Lira. I'm sorry. Truly. The fever doesn't care whose daughter she was.", "es": "Supe lo de Lira. Lo siento. De verdad. A la fiebre no le importa de quién era hija."},
		]},
		&"prologue_grief": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_grief", "en": "I have buried people this winter, too.", "es": "Yo también he enterrado a gente este invierno."},
		]},
		&"prologue_hope": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_hope", "en": "There is a way no one else loses their Lira. The fever travels with people. Five of them hold the roads, and let no help through.", "es": "Hay una forma de que nadie más pierda a su Lira. La fiebre viaja con la gente. Hay cinco que cierran los caminos y no dejan pasar la ayuda."},
		]},
		&"prologue_bram": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_bram", "en": "Bram. A huge man. A good one, once. Now he guards a door, and lets no one out.", "es": "Bram. Un hombre enorme. Y bueno, en otro tiempo. Ahora guarda una puerta y no deja salir a nadie."},
		]},
		&"prologue_varga": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_varga", "en": "Varga. The finest captain I ever had. Something broke in her, up at the Pass. They say she burns villages.", "es": "Varga. La mejor capitana que tuve. Algo se le torció en el Paso. Dicen que quema aldeas."},
		]},
		&"prologue_ilse": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_ilse", "en": "Ilse hunts in the mountains. The messengers I send up there... don't come back.", "es": "Ilse caza en la montaña. Los mensajeros que envío allí… no vuelven."},
		]},
		&"prologue_orme": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_orme", "en": "Orme. The cleverest engineer in the kingdom. He holds the river dam in his hands.", "es": "Orme. El ingeniero más listo del reino. Tiene la presa del río en sus manos."},
		]},
		&"prologue_aren": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_aren", "en": "And Aren. Him... you will meet at the end.", "es": "Y Aren. A ese… lo conocerás al final."},
		]},
		&"prologue_vow_stop": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_vow_stop", "en": "Stop them. Yes. Do whatever is necessary, Kael. I trust your judgement.", "es": "Detenerlos. Sí. Haz lo que sea necesario, Kael. Confío en tu juicio."},
		]},
		&"prologue_vow_end": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_vow_end", "en": "Let them suffer no more than they must. I trust you, Kael.", "es": "Que no sufran más de lo necesario. Confío en ti, Kael."},
		]},
	},
	# Kael en las escenas (voz no posicional, como el narrador).
	&"kael_scene": {
		&"prologue_need": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_prologue_need", "en": "What do you need of me, my lord?", "es": "¿Qué necesitáis de mí, mi señor?"},
		]},
		&"prologue_promise": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_prologue_promise", "en": "I promise.", "es": "Lo prometo."},
		]},
		&"prologue_choice_stop": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_prologue_choice_stop", "en": "I will stop them, my lord.", "es": "Los detendré, mi señor."},
		]},
		&"prologue_choice_end": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_prologue_choice_end", "en": "I will put an end to them.", "es": "Acabaré con ellos."},
		]},
		&"varga_1": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_varga_1", "en": "The Regent says you burn villages.", "es": "El Regente dice que quemáis aldeas."},
		]},
		# Conversación con Varga ampliada (aviso del jugador, 2026-11-11: la razón para luchar era muy vaga). Kael
		# cree de verdad que ella deja morir a la gente: los carros del Regente traen grano y médicos, y ella
		# los manda de vuelta. Y lleva su herida: Lira murió de esta misma fiebre y nadie fue a ayudarla.
		&"varga_1b": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_varga_1b", "en": "It's closed because you close it. His wagons bring grain and physicians, and you turn them back while those people die behind your grey cloths.", "es": "Está cerrado porque tú lo cierras. Sus carros traen grano y médicos, y tú los mandas de vuelta mientras esa gente se muere detrás de tus telas grises."},
		]},
		&"varga_1c": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_varga_1c", "en": "I don't need him to. My sister died of this same fever. Nobody came for her. I won't let you make anyone else wait.", "es": "No necesito que me lo diga. Mi hermana murió de esta misma fiebre. Nadie vino a ayudarla. No dejaré que hagas esperar a nadie más."},
		]},
		&"varga_2": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_varga_2", "en": "I have my orders.", "es": "Tengo mis órdenes."},
		]},
		&"frank_1": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_frank_1", "en": "Go on. Back to your own kind.", "es": "Anda, vete. Vuelve con los tuyos."},
		]},
		&"frank_2": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "kael_scene_frank_2", "en": "...Do as you like.", "es": "…Haz lo que quieras."},
		]},
	},
	# Lira, la hermana de Kael, de niña (el recuerdo del prólogo).
	&"lira": {
		&"memory_promise": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "lira_memory_promise", "en": "So you come back. Promise me.", "es": "Para que vuelvas. Prométemelo."},
		]},
	},
	# La Capitana Varga (jefa del Paso de Hierro). Duelista: segura, cortante, cansada de la guerra.
	&"varga": {
		&"spot": {"chance": 1.0, "cooldown": 5.0, "lines": [
			{"id": "varga_spot_1", "en": "So the Regent finally sent his hound. Draw, then.", "es": "Así que el Regente por fin envió a su perro. Desenvaina, entonces."},
			{"id": "varga_spot_2", "en": "You're far from the capital, soldier. You should have stayed there.", "es": "Estás lejos de la capital, soldado. Deberías haberte quedado allí."},
		]},
		&"attack": {"chance": 0.5, "cooldown": 0.7, "lines": [
			{"id": "varga_attack_1", "say": "Hah!", "effort": "short sharp exhale, adult woman, swift sword strike"},
			{"id": "varga_attack_2", "say": "Hup!", "effort": "quick clipped grunt, adult woman, fencing lunge"},
			{"id": "varga_attack_3", "say": "Hyah!", "effort": "light fierce cry, adult woman, fast slash"},
		]},
		&"danger": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "varga_danger_1", "say": "Haaah!", "effort": "fierce battle shout, adult woman, before a powerful lunge"},
		]},
		&"hurt": {"chance": 0.7, "cooldown": 0.6, "lines": [
			{"id": "varga_hurt_1", "say": "Ugh!", "effort": "pained grunt, adult woman, struck by a blade"},
			{"id": "varga_hurt_2", "say": "Ah!", "effort": "sharp gasp of pain, adult woman"},
		]},
		&"broken": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "varga_broken_1", "say": "Hah... hah...", "effort": "out of breath, adult woman losing her balance"},
		]},
		# Escena antes del duelo (VargaIntro).
		&"intro_1": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "varga_intro_1", "en": "Stop there. That smoke is not a village burning. It's their clothes. The sick ones.", "es": "Alto ahí. Ese humo no es una aldea ardiendo. Es su ropa. La de los enfermos."},
		]},
		&"intro_1b": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "varga_intro_1b", "en": "The Regent says many things. Did he also tell you why this pass is closed?", "es": "El Regente dice muchas cosas. ¿Te dijo también por qué está cerrado este paso?"},
		]},
		&"intro_2b": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "varga_intro_2b", "en": "...Then you know what it does. And still you can't see what I'm doing here.", "es": "…Entonces sabes lo que hace. Y aun así no ves lo que hago aquí."},
		]},
		&"intro_2": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "varga_intro_2", "en": "And did he tell you why his wagons are in such a hurry to cross a closed pass?", "es": "¿Y te dijo por qué sus carros tienen tanta prisa por cruzar un paso cerrado?"},
		]},
		&"intro_3": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "varga_intro_3", "en": "Then come. I hope you live long enough to regret them.", "es": "Entonces ven. Ojalá vivas lo bastante para arrepentirte de ellas."},
		]},
		&"phase": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "varga_phase_1", "en": "Not yet. Look at the smoke, soldier. Ask yourself what we are burning.", "es": "Todavía no. Mira el humo, soldado. Pregúntate qué estamos quemando."},
		]},
		&"death": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "varga_death_1", "en": "He told you we burned villages? Look at the smoke... look at what we burn.", "es": "¿Te dijo que quemábamos aldeas? Mira el humo… mira qué quemamos."},
		]},
		&"victory": {"chance": 1.0, "cooldown": 10.0, "lines": [
			{"id": "varga_victory_1", "en": "Stay down. You don't know what you're doing.", "es": "No te levantes. No sabes lo que haces."},
			{"id": "varga_victory_2", "en": "Go home. Tell him the Pass is closed.", "es": "Vuelve a casa. Dile que el Paso está cerrado."},
		]},
	},
	# Frank, el tití: chilla; el subtítulo es lo que Kael entiende (D22). Suena desde su hombro.
	&"frank": {
		# Atrapado en la red, cuando Kael se acerca.
		&"trapped": {"chance": 1.0, "cooldown": 10.0, "lines": [
			{"id": "frank_trapped_1", "chirp": "call", "es": "«¡Eh! ¡Tú, el de la espada! ¡Aquí arriba!»"},
			{"id": "frank_trapped_2", "chirp": "call", "es": "«¡Sácame de aquí, por favor!»"},
			{"id": "frank_trapped_3", "chirp": "chatter", "es": "«No muerdo. Casi nunca.»"},
		]},
		# Escena de la red.
		&"meet_1": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_meet_1", "chirp": "happy", "es": "«¡Por fin! Dos días aquí colgado.»"},
		]},
		&"meet_2": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_meet_2", "chirp": "sad", "es": "«Los míos no me quieren. Por los rulos.»"},
		]},
		&"meet_3": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_meet_3", "chirp": "chatter", "es": "«Me quedo contigo. Alguien tiene que cuidarte.»"},
		]},
		# Si Kael pasa de largo: se suelta solo y lo sigue, ofendido.
		&"offended": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_offended_1", "chirp": "indignant", "es": "«¡Ni las gracias! Ya me solté yo solo, ¿eh?»"},
		]},
		&"offended_2": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_offended_2", "chirp": "chatter", "es": "«Bueno. Te sigo igual. Alguien tiene que cuidarte.»"},
		]},
		# --- Consejos y bromas (FrankAdvisor). Nunca da la respuesta exacta: da pistas. ---
		# Se venda con un enemigo alerta cerca: se tapa la cara.
		&"heal_danger": {"chance": 1.0, "cooldown": 60.0, "lines": [
			{"id": "frank_heal_danger_1", "chirp": "indignant", "es": "«¿Ahora? ¿En serio?»"},
			{"id": "frank_heal_danger_2", "chirp": "alarm_talk", "es": "«¡Que te está mirando!»"},
			{"id": "frank_heal_danger_3", "chirp": "chatter", "es": "«Vendarse delante de él… Valiente. O tonto.»"},
		]},
		&"heal": {"chance": 0.15, "cooldown": 180.0, "lines": [
			{"id": "frank_heal_1", "chirp": "chatter", "es": "«Aprieta fuerte. Así.»"},
			{"id": "frank_heal_2", "chirp": "twitter", "es": "«Ya está. Como nuevo. Casi.»"},
		]},
		&"bandages_out": {"chance": 1.0, "cooldown": 180.0, "lines": [
			{"id": "frank_bandages_out_1", "chirp": "chatter", "es": "«No quedan vendas. En un campamento te dan más.»"},
		]},
		# Al reaparecer tras morir.
		&"death_first": {"chance": 0.6, "cooldown": 0.0, "lines": [
			{"id": "frank_death_first_1", "chirp": "chatter", "es": "«Bueno. Otra vez. Yo no he visto nada.»"},
			{"id": "frank_death_first_2", "chirp": "twitter", "es": "«Te guardé el sitio en el hombro.»"},
			{"id": "frank_death_first_3", "chirp": "chatter", "es": "«Eso dolió de mirar. Vamos otra vez.»"},
		]},
		&"death_again": {"chance": 0.5, "cooldown": 0.0, "lines": [
			{"id": "frank_death_again_1", "chirp": "chatter", "es": "«Respira. Míralo antes de pegarle.»"},
			{"id": "frank_death_again_2", "chirp": "happy", "es": "«Cada vez aguantas más. Lo estoy contando.»"},
		]},
		# Pistas según quién lo venció (a partir de la segunda vez).
		&"hint_soldier": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_hint_soldier_1", "chirp": "chatter", "es": "«Para el golpe justo cuando llega. Se cansan antes que tú.»"},
			{"id": "frank_hint_soldier_2", "chirp": "chatter", "es": "«Cuando se tambalea, ¡ahí! No lo dejes respirar.»"},
		]},
		&"hint_spear": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_hint_spear_1", "chirp": "chatter", "es": "«La lanza llega lejos. Pégate a él.»"},
			{"id": "frank_hint_spear_2", "chirp": "chatter", "es": "«Si pincha en rojo, no te apartes: ve hacia la punta.»"},
		]},
		&"hint_archer": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_hint_archer_1", "chirp": "chatter", "es": "«El del arco no sabe pelear de cerca. Corre hacia él.»"},
		]},
		&"hint_bandit": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_hint_bandit_1", "chirp": "chatter", "es": "«Ese es rápido. Espera a que falle, y entonces, tú.»"},
		]},
		&"hint_varga": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_hint_varga_1", "chirp": "chatter", "es": "«Cuando salta, apártate. Cuando cae, ¡pégale!»"},
			{"id": "frank_hint_varga_2", "chirp": "chatter", "es": "«Sus cuchillos se paran con la espada. Como un golpe más.»"},
			{"id": "frank_hint_varga_3", "chirp": "chatter", "es": "«Cuando gira y barre en rojo… ¡salta!»"},
		]},
		&"hint_danger": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_hint_danger_1", "chirp": "chatter", "es": "«Rojo es que no se para. Si barre, salta; si pincha, ve hacia él.»"},
		]},
		# Lugares (después del anciano).
		&"zone_village": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_zone_village_1", "chirp": "twitter", "es": "«Huele a pan… y a humo. Más a humo.»"},
		]},
		&"zone_forest": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_zone_forest_1", "chirp": "happy", "es": "«¡Árboles! Por fin algo de mi tamaño. Bueno, más grande.»"},
		]},
		&"zone_fortress": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_zone_fortress_1", "chirp": "sad", "es": "«Muros altos. No me gustan los muros altos.»"},
		]},
		# Campamento.
		&"rest_first": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_rest_first_1", "chirp": "happy", "es": "«Fuego, comida y nadie persiguiéndonos. Me gusta.»"},
		]},
		&"rest": {"chance": 0.2, "cooldown": 300.0, "lines": [
			{"id": "frank_rest_1", "chirp": "twitter", "es": "«Duerme. Yo vigilo. …Un rato.»"},
			{"id": "frank_rest_2", "chirp": "chatter", "es": "«¿Has comido algo hoy? Yo sí. Tu pan.»"},
		]},
		# Le rompen la guardia a Kael.
		&"stagger": {"chance": 0.3, "cooldown": 60.0, "lines": [
			{"id": "frank_stagger_1", "chirp": "alarm_talk", "es": "«¡Respira, grandullón!»"},
			{"id": "frank_stagger_2", "chirp": "alarm_talk", "es": "«¡Apártate, que viene otra!»"},
		]},
		# Después de un golpe mortal: la conciencia de Kael (nunca en un duelo con jefe).
		&"kill": {"chance": 0.12, "cooldown": 240.0, "lines": [
			{"id": "frank_kill_1", "chirp": "sad", "es": "«Ese también tenía a alguien esperándolo en casa…»"},
			{"id": "frank_kill_2", "chirp": "sad", "es": "«¿Seguro que eran rebeldes?»"},
			{"id": "frank_kill_3", "chirp": "chatter", "es": "«El Regente no se mancha las manos, ¿eh? Para eso estás tú.»"},
		]},
		# Kael lleva rato quieto.
		&"idle_long": {"chance": 1.0, "cooldown": 240.0, "lines": [
			{"id": "frank_idle_long_1", "chirp": "chatter", "es": "«¿Nos quedamos a vivir aquí?»"},
			{"id": "frank_idle_long_2", "chirp": "chatter", "es": "«Si no vas tú, voy yo. …No. Mejor tú.»"},
			{"id": "frank_idle_long_3", "chirp": "twitter", "es": "«Me aburro. Te voy a peinar.»"},
		]},
		# --- Avisos de peligro (FrankAdvisor): chilla y señala. ---
		&"warn_archer": {"chance": 1.0, "cooldown": 25.0, "lines": [
			{"id": "frank_warn_archer_1", "chirp": "alarm_talk", "es": "«¡El del arco! ¡Te apunta!»"},
			{"id": "frank_warn_archer_2", "chirp": "alarm_talk", "es": "«¡Flecha! ¡Cúbrete!»"},
		]},
		&"warn_behind": {"chance": 1.0, "cooldown": 20.0, "lines": [
			{"id": "frank_warn_behind_1", "chirp": "alarm_talk", "es": "«¡Detrás de ti!»"},
			{"id": "frank_warn_behind_2", "chirp": "alarm_talk", "es": "«¡Por la espalda, grandullón!»"},
		]},
		&"warn_suspicious": {"chance": 1.0, "cooldown": 40.0, "lines": [
			{"id": "frank_warn_suspicious_1", "chirp": "whisper", "es": "«Shh… Ese ha oído algo.»"},
			{"id": "frank_warn_suspicious_2", "chirp": "whisper", "es": "«Quieto. Agáchate.»"},
		]},
		# --- Hallazgos: señala lo escondido y abre pestillos desde el otro lado. ---
		&"find_item": {"chance": 1.0, "cooldown": 6.0, "lines": [
			{"id": "frank_find_item_1", "chirp": "chatter", "es": "«¡Eh! Ahí hay algo.»"},
			{"id": "frank_find_item_2", "chirp": "chatter", "es": "«Mira allí. ¿Lo ves? Yo sí.»"},
		]},
		&"found_item": {"chance": 0.4, "cooldown": 30.0, "lines": [
			{"id": "frank_found_item_1", "chirp": "happy", "es": "«¡La mitad es mía!»"},
			{"id": "frank_found_item_2", "chirp": "happy", "es": "«¿Ves? Sin mí, ni lo encuentras.»"},
		]},
		&"poacher_note": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_poacher_note_1", "chirp": "sad", "es": "«…Esa jaula era para mí.»"},
		]},
		&"gate_locked": {"chance": 1.0, "cooldown": 30.0, "lines": [
			{"id": "frank_gate_locked_1", "chirp": "chatter", "es": "«Cerrado por dentro… Déjame a mí.»"},
		]},
		&"gate_go": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_gate_go_1", "chirp": "chatter", "es": "«Espera aquí. No toques nada.»"},
		]},
		&"gate_done": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_gate_done_1", "chirp": "happy", "es": "«¡Pestillo fuera! De nada, ¿eh?»"},
		]},
		# --- Distraer (FrankThrow): lanza una fruta. ---
		&"throw_go": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_throw_go_1", "chirp": "squeak", "effort": "little effort squeak, small monkey throwing something"},
		]},
		&"throw_hit": {"chance": 0.6, "cooldown": 0.0, "lines": [
			{"id": "frank_throw_hit_1", "chirp": "happy", "es": "«¡En toda la cara!»"},
			{"id": "frank_throw_hit_2", "chirp": "happy", "es": "«¡Ja! ¿Quieres otra?»"},
		]},
		&"throw_distract": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_throw_distract_1", "chirp": "whisper", "es": "«Ya mira para otro lado. ¡Ahora!»"},
			{"id": "frank_throw_distract_2", "chirp": "whisper", "es": "«Shh… Por detrás. Despacio.»"},
		]},
		&"throw_boss": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "frank_throw_boss_1", "chirp": "indignant", "es": "«Ni la ha despeinado.»"},
		]},
		&"throw_wait": {"chance": 1.0, "cooldown": 8.0, "lines": [
			{"id": "frank_throw_wait_1", "chirp": "chatter", "es": "«Espera, que busco otra fruta.»"},
			{"id": "frank_throw_wait_2", "chirp": "chatter", "es": "«Me la comí. Dame un momento.»"},
		]},
		&"throw_nobody": {"chance": 1.0, "cooldown": 8.0, "lines": [
			{"id": "frank_throw_nobody_1", "chirp": "chatter", "es": "«¿A quién se la tiro? No veo a nadie.»"},
		]},
		# Sonidos sin subtítulo.
		&"happy": {"chance": 0.6, "cooldown": 3.0, "lines": [
			{"id": "frank_happy_1", "chirp": "happy", "effort": "little rising trill of a happy small monkey"},
			{"id": "frank_happy_2", "chirp": "squeak", "effort": "short cheerful squeak"},
		]},
		&"idle": {"chance": 0.3, "cooldown": 90.0, "lines": [
			{"id": "frank_idle_1", "chirp": "twitter", "effort": "soft twittering to himself, small monkey"},
			{"id": "frank_idle_2", "chirp": "squeak", "effort": "curious little squeak"},
		]},
		&"scared": {"chance": 0.2, "cooldown": 15.0, "lines": [
			{"id": "frank_scared_1", "chirp": "alarm", "effort": "sharp startled shriek of a small monkey"},
			{"id": "frank_scared_2", "chirp": "squeak", "effort": "frightened squeak"},
		]},
	},
}
