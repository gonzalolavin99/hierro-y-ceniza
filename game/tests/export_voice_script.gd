extends SceneTree
## Genera docs/10_GUION_VOCES.md a partir de VoiceLines (así el guion nunca se desincroniza del juego).
## Ejecutar: Godot --headless --path game --script res://tests/export_voice_script.gd


## Cómo debe sonar cada voz (para elegir o diseñar la voz en ElevenLabs).
const VOICE_DESCRIPTIONS: Dictionary = {
	&"kael": "Hombre de unos 30 años, soldado de élite. Voz grave y contenida; en combate, esfuerzos secos y controlados, nunca exagerados.",
	&"soldier": "Hombre de mediana edad, soldado raso curtido. Voz áspera y ruda, algo cansada.",
	&"narrator": "Kael anciano (unos 70 años) contando la historia junto a una fogata. Voz cálida, grave y gastada; habla despacio. Al morir el jugador suena dubitativo, como quien se corrige.",
}


func _init() -> void:
	var md: PackedStringArray = []
	md.append("# 10 · Guion de voces (ElevenLabs)")
	md.append("")
	md.append("Archivo generado por `game/tests/export_voice_script.gd` a partir de `game/scripts/systems/voice_lines.gd`.")
	md.append("**No editar a mano**: cambiar las líneas en `voice_lines.gd` y volver a generarlo.")
	md.append("")
	md.append("## Cómo generar las voces")
	md.append("")
	md.append("1. **Frases** (tienen texto): en ElevenLabs → *Text to Speech*, con la voz descrita para cada personaje.")
	md.append("   Pegar el texto en inglés tal cual. El subtítulo en español ya está en el juego.")
	md.append("2. **Esfuerzos** (gritos, quejidos, respiraciones): en ElevenLabs → *Sound Effects*, pegando la descripción.")
	md.append("   Generar 2–3 versiones y quedarse con la más natural y corta (menos de 1 segundo).")
	md.append("3. Descargar en **MP3** y guardar con el **nombre exacto** de la columna *Archivo* en")
	md.append("   `game/assets/audio/voice/<personaje>/` (por ejemplo `game/assets/audio/voice/kael/kael_hurt_1.mp3`).")
	md.append("4. Abrir el juego (F5): Godot importa los archivos solo. Si falta alguno, el juego no falla: simplemente calla.")
	md.append("")
	md.append("Recordatorio de la guía de contenido (docs/04): nada sobrenatural en ningún texto.")
	md.append("La prueba `voice_test` revisa automáticamente que no aparezcan palabras prohibidas.")
	for speaker: StringName in VoiceLines.LINES:
		md.append("")
		md.append("## %s (`%s`)" % [VoiceLines.SPEAKER_NAMES.get(speaker, speaker), speaker])
		md.append("")
		md.append("*Voz:* %s" % VOICE_DESCRIPTIONS.get(speaker, ""))
		md.append("")
		md.append("| Archivo | Cuándo suena | Tipo | Texto en inglés / descripción del esfuerzo | Subtítulo |")
		md.append("|---|---|---|---|---|")
		for event: StringName in VoiceLines.LINES[speaker]:
			var data: Dictionary = VoiceLines.LINES[speaker][event]
			for line: Dictionary in data["lines"]:
				var is_phrase: bool = line.has("en")
				md.append("| `%s.mp3` | %s | %s | %s | %s |" % [line["id"], event, "Frase" if is_phrase else "Esfuerzo",
					line["en"] if is_phrase else line["effort"], line.get("es", "—")])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/10_GUION_VOCES.md"), FileAccess.WRITE)
	file.store_string("\n".join(md) + "\n")
	file.close()
	print("Guion generado: docs/10_GUION_VOCES.md")
	quit()
