class_name VoiceLines
extends RefCounted
## Todo lo que dicen (o resoplan) los personajes. Voces en inglés con subtítulos en español (D8).
## Los archivos se generan en local con tools/gen_voices.py (voz Kokoro, gratuita) y se guardan como
## assets/audio/voice/<personaje>/<id>.wav (o .mp3 / .ogg). Si falta un archivo, el juego no falla.
##
## Por evento: chance (0–1, probabilidad de hablar), cooldown (segundos sin repetir ese evento) y
## lines: frases {id, en, es} (llevan subtítulo) o esfuerzos {id, say, effort}: `say` es la interjección que lee
## el generador de voz local (tools/gen_voices.py) y `effort` la descripción del sonido buscado.

## Nombre que aparece en los subtítulos.
const SPEAKER_NAMES: Dictionary = {&"kael": "Kael", &"soldier": "Soldado", &"narrator": "El anciano", &"regent": "El Regente"}
## Voces que no salen de un personaje del nivel (el narrador; el Regente en las escenas): suenan igual en
## todas partes (no posicionales) y mandan sobre las demás.
const NARRATORS: Array[StringName] = [&"narrator", &"regent"]
## Importancia de cada evento cuando varias voces coinciden: la más importante interrumpe a la menos
## importante del mismo personaje o, si ya suenan demasiadas, a la menos importante de la escena.
## Los eventos que no aparecen valen 1 (esfuerzos de ataque, lanzar…).
const EVENT_PRIORITY: Dictionary = {
	&"player_death": 4, &"player_death_2": 4, &"player_death_3": 4, &"player_death_4": 4,
	&"death": 3, &"spot": 3, &"victory": 3,
	&"danger": 2, &"broken": 2, &"hurt": 2, &"deathblow": 2,
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
			{"id": "narrator_player_death_2_1", "en": "No... he did not fall there. That much I remember. I think.", "es": "No… él no cayó ahí. Eso lo recuerdo bien. Creo."},
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
		# Escena del prólogo (PrologueScene), después de story_prologue.
		&"story_prologue_order": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue_order", "en": "It began with an order, in a hall of cold stone.", "es": "Todo empezó con una orden, en una sala de piedra fría."},
		]},
		&"story_prologue_ribbon": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_story_prologue_ribbon", "en": "The warrior did not ask a single question. He only looked at the ribbon on his wrist.", "es": "El guerrero no hizo ni una pregunta. Solo miró la cinta de su muñeca."},
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
			{"id": "narrator_story_frontier", "en": "The last cordon. I no longer know which part is mine and which part is the song.", "es": "El último cordón. Ya no sé qué parte es mía y qué parte es la canción."},
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
	&"regent": {
		&"prologue_order": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_order", "en": "Five names. Five cordons. When they fall, the fever ends.", "es": "Cinco nombres. Cinco cordones. Cuando caigan, la fiebre se acaba."},
		]},
		&"prologue_sister": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "regent_prologue_sister", "en": "The fever took your sister, Kael. The rebels brought it to us. Make them pay.", "es": "La fiebre se llevó a tu hermana, Kael. Nos la trajeron los rebeldes. Haz que paguen."},
		]},
	},
}
