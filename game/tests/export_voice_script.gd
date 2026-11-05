extends SceneTree
## Genera docs/10_GUION_VOCES.md y tools/voice_lines.json a partir de VoiceLines (así el guion y el
## generador de voces nunca se desincronizan del juego).
## Ejecutar: Godot --headless --path game --script res://tests/export_voice_script.gd


## Cómo debe sonar cada voz y qué voz de Kokoro la interpreta (ver tools/gen_voices.py).
const VOICE_DESCRIPTIONS: Dictionary = {
	&"kael": "Hombre de unos 30 años, soldado de élite. Voz grave y contenida; en combate, esfuerzos secos y controlados. Kokoro: `bm_daniel`.",
	&"soldier": "Hombre de mediana edad, soldado raso curtido. Voz áspera y ruda. Kokoro: `am_onyx`, con algo de aspereza.",
	&"regent": "El Regente Malcor: hombre maduro, culto y frío; habla bajo, sin prisa, sin levantar la voz. Kokoro: `bm_george`, algo más grave, con eco de sala de piedra.",
	&"narrator": "Kael anciano contando la historia junto a una fogata. Voz grave y gastada; habla despacio, dubitativo al corregirse. Kokoro: `bm_lewis`, más lenta y grave, con eco de sala.",
}


func _init() -> void:
	var root_dir: String = ProjectSettings.globalize_path("res://").path_join("..")
	var md: PackedStringArray = []
	md.append("# 10 · Guion de voces")
	md.append("")
	md.append("Archivo generado por `game/tests/export_voice_script.gd` a partir de `game/scripts/systems/voice_lines.gd`.")
	md.append("**No editar a mano**: cambiar las líneas en `voice_lines.gd` y volver a generarlo.")
	md.append("")
	md.append("## Cómo se generan las voces")
	md.append("")
	md.append("En local y gratis con **Kokoro** (modelo de voz abierto, licencia Apache 2.0: se puede usar en un juego")
	md.append("comercial). Instalado en `G:\\Herramientas\\tts`. Sin cuenta ni internet.")
	md.append("")
	md.append("1. Si cambian las líneas: `--headless --path game --script res://tests/export_voice_script.gd`")
	md.append("   (regenera este documento y `tools/voice_lines.json`).")
	md.append("2. `G:\\Herramientas\\tts\\venv\\Scripts\\python tools/gen_voices.py` (desde `G:\\Game`): crea los `.wav` en")
	md.append("   `game/assets/audio/voice/<personaje>/`. Solo genera los que faltan; `--all` los rehace todos.")
	md.append("3. Abrir el juego: Godot los importa solo. Si falta alguno, el juego no falla: simplemente calla.")
	md.append("")
	md.append("Las **frases** suenan naturales. Los **esfuerzos** (gritos, quejidos) se generan leyendo una interjección")
	md.append("(columna *Lee*); son la parte más débil. Para mejorarlos, sustituir el `.wav` por uno grabado o de un banco")
	md.append("de sonidos libre (CC0) con el mismo nombre. La descripción indica cómo debería sonar.")
	md.append("")
	md.append("Guía de contenido (docs/04): nada sobrenatural en ningún texto. La prueba `voice_test` lo revisa sola.")
	for speaker: StringName in VoiceLines.LINES:
		md.append("")
		md.append("## %s (`%s`)" % [VoiceLines.SPEAKER_NAMES.get(speaker, speaker), speaker])
		md.append("")
		md.append("*Voz:* %s" % VOICE_DESCRIPTIONS.get(speaker, ""))
		md.append("")
		md.append("| Archivo | Cuándo suena | Lee | Cómo debería sonar / subtítulo |")
		md.append("|---|---|---|---|")
		for event: StringName in VoiceLines.LINES[speaker]:
			for line: Dictionary in VoiceLines.LINES[speaker][event]["lines"]:
				if line.has("en"):
					md.append("| `%s.wav` | %s | %s | Subtítulo: %s |" % [line["id"], event, line["en"], line["es"]])
				else:
					md.append("| `%s.wav` | %s | %s | %s |" % [line["id"], event, line["say"], line["effort"]])
	var doc := FileAccess.open(root_dir.path_join("docs/10_GUION_VOCES.md"), FileAccess.WRITE)
	doc.store_string("\n".join(md) + "\n")
	doc.close()
	print("Guion generado: docs/10_GUION_VOCES.md")

	# Datos para el generador local de voces (tools/gen_voices.py).
	var data: Dictionary = {}
	for speaker: StringName in VoiceLines.LINES:
		var lines: Array = []
		for event: StringName in VoiceLines.LINES[speaker]:
			for line: Dictionary in VoiceLines.LINES[speaker][event]["lines"]:
				lines.append({"id": line["id"], "event": String(event), "text": line.get("en", line.get("say", "")),
					"phrase": line.has("en")})
		data[String(speaker)] = lines
	var json := FileAccess.open(root_dir.path_join("tools/voice_lines.json"), FileAccess.WRITE)
	json.store_string(JSON.stringify(data, "  ") + "\n")
	json.close()
	print("Datos para el generador: tools/voice_lines.json")
	quit()
