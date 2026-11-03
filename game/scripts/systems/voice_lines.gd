class_name VoiceLines
extends RefCounted
## Todo lo que dicen (o resoplan) los personajes. Voces en inglés con subtítulos en español (D8).
## Los archivos se generan con ElevenLabs siguiendo docs/10_GUION_VOCES.md y se guardan como
## assets/audio/voice/<personaje>/<id>.mp3 (o .ogg / .wav). Si falta un archivo, el juego no falla.
##
## Por evento: chance (0–1, probabilidad de hablar), cooldown (segundos sin repetir ese evento) y
## lines: frases {id, en, es} (llevan subtítulo) o esfuerzos {id, effort} (descripción para generarlos).

## Nombre que aparece en los subtítulos.
const SPEAKER_NAMES: Dictionary = {&"kael": "Kael", &"soldier": "Soldado", &"narrator": "El anciano"}
## El narrador no está en la escena: su voz suena igual en todas partes (no posicional).
const NARRATORS: Array[StringName] = [&"narrator"]

const LINES: Dictionary = {
	&"kael": {
		&"attack": {"chance": 0.35, "cooldown": 0.6, "lines": [
			{"id": "kael_attack_1", "effort": "short sharp exhale through clenched teeth while swinging a sword, adult man"},
			{"id": "kael_attack_2", "effort": "quick low grunt of effort, adult man, sword swing"},
			{"id": "kael_attack_3", "effort": "brief controlled 'hah' of exertion, adult man"},
		]},
		&"heavy": {"chance": 1.0, "cooldown": 0.8, "lines": [
			{"id": "kael_heavy_1", "effort": "strong full-body grunt, adult man bringing a heavy sword down"},
			{"id": "kael_heavy_2", "effort": "forceful 'hyah', adult man, overhead strike"},
		]},
		&"art": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "kael_art_1", "effort": "short fierce battle shout, adult man, controlled and determined"},
			{"id": "kael_art_2", "effort": "deep roar of effort, adult man, leaping sword attack"},
		]},
		&"throw": {"chance": 0.7, "cooldown": 0.8, "lines": [
			{"id": "kael_throw_1", "effort": "quick exhale, adult man throwing a small object"},
		]},
		&"hurt": {"chance": 1.0, "cooldown": 0.6, "lines": [
			{"id": "kael_hurt_1", "effort": "pained grunt, adult man struck by a blade"},
			{"id": "kael_hurt_2", "effort": "sharp gasp of pain, adult man"},
			{"id": "kael_hurt_3", "effort": "teeth-gritted groan of pain, adult man"},
		]},
		&"deathblow": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "kael_deathblow_1", "effort": "low heavy exhale after a decisive final sword strike, adult man"},
		]},
		&"death": {"chance": 1.0, "cooldown": 2.0, "lines": [
			{"id": "kael_death_1", "effort": "dying groan, adult man collapsing to the ground"},
		]},
	},
	&"soldier": {
		&"spot": {"chance": 1.0, "cooldown": 20.0, "lines": [
			{"id": "soldier_spot_1", "en": "You shouldn't have come here.", "es": "No deberías haber venido."},
			{"id": "soldier_spot_2", "en": "Halt! Who goes there?", "es": "¡Alto! ¿Quién va?"},
			{"id": "soldier_spot_3", "en": "Draw your blade.", "es": "Desenvaina."},
		]},
		&"attack": {"chance": 0.4, "cooldown": 0.7, "lines": [
			{"id": "soldier_attack_1", "effort": "rough grunt, middle-aged man swinging a sword"},
			{"id": "soldier_attack_2", "effort": "short aggressive 'hup', middle-aged man"},
		]},
		&"danger": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "soldier_danger_1", "effort": "loud aggressive war cry, middle-aged man, before a powerful attack"},
			{"id": "soldier_danger_2", "effort": "deep shout of effort, middle-aged man, charging"},
		]},
		&"hurt": {"chance": 0.8, "cooldown": 0.6, "lines": [
			{"id": "soldier_hurt_1", "effort": "pained grunt, middle-aged man"},
			{"id": "soldier_hurt_2", "effort": "sharp cry of pain, middle-aged man"},
		]},
		&"broken": {"chance": 1.0, "cooldown": 1.0, "lines": [
			{"id": "soldier_broken_1", "effort": "staggered, out-of-breath groan, middle-aged man losing balance"},
		]},
		&"death": {"chance": 1.0, "cooldown": 2.0, "lines": [
			{"id": "soldier_death_1", "effort": "final dying exhale, middle-aged man"},
		]},
		&"victory": {"chance": 1.0, "cooldown": 10.0, "lines": [
			{"id": "soldier_victory_1", "en": "Stay down.", "es": "No te levantes."},
			{"id": "soldier_victory_2", "en": "That's the end of you.", "es": "Hasta aquí llegaste."},
		]},
	},
	&"narrator": {
		&"player_death": {"chance": 1.0, "cooldown": 0.0, "lines": [
			{"id": "narrator_death_1", "en": "No... no, that's not how it happened.", "es": "No… no fue así."},
			{"id": "narrator_death_2", "en": "Wait. Let me start again.", "es": "Espera. Déjame empezar de nuevo."},
			{"id": "narrator_death_3", "en": "No... I'm getting ahead of myself.", "es": "No… me estoy adelantando."},
		]},
	},
}
