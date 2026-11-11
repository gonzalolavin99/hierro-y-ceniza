extends Node
## Prueba automática de los canales de sonido y el ambiente (Cimientos, revisión del estudio): existen los 4
## canales; cada sonido va al suyo; la música y el ambiente bajan solos mientras alguien habla y luego vuelven;
## los efectos no cortan uno que sigue sonando ni repiten la misma variante dos veces seguidas; en el Paso de
## Hierro sopla el viento, suena el arroyo y cantan pájaros lejanos (no en el duelo con un jefe).
## Ejecutar: Godot --headless --path game res://tests/audio_mix_test.tscn

var _failures: int = 0


func _ready() -> void:
	for bus: StringName in AudioMix.ALL:
		_check("Existe el canal %s" % bus, AudioMix.bus_index(bus) > 0)
	_check("Los efectos van al canal Efectos", Sfx._pool.all(func(p: AudioStreamPlayer3D) -> bool: return p.bus == AudioMix.SFX))
	_check("Las voces van al canal Voz", Voice._pool.all(func(p: AudioStreamPlayer3D) -> bool: return p.bus == AudioMix.VOICE) and Voice._narrator.bus == AudioMix.VOICE)

	add_child(load("res://scenes/levels/iron_pass.tscn").instantiate())
	await _wait(1.0)
	var arena := get_tree().get_first_node_in_group("arenas") as VargaArena
	_check("La música del duelo va al canal Música", arena._music.all(func(p: AudioStreamPlayer) -> bool: return p.bus == AudioMix.MUSIC))

	# Ducking: el narrador habla → música y ambiente bajan; al callar, vuelven.
	Voice.always_speak = true
	Voice.say(&"narrator", &"story_pass_village")
	await _wait(0.6)
	var low: float = AudioMix.volume(AudioMix.MUSIC)
	_check("Mientras habla, la música baja (%.1f dB)" % low, low <= AudioMix.DUCK_DB + 0.5)
	_check("…y el ambiente también (%.1f dB)" % AudioMix.volume(AudioMix.AMBIENT), AudioMix.volume(AudioMix.AMBIENT) <= AudioMix.DUCK_DB + 0.5)
	Voice.reset()
	await _wait(1.5)
	_check("Al callar vuelven (%.1f dB)" % AudioMix.volume(AudioMix.MUSIC), AudioMix.volume(AudioMix.MUSIC) > -0.5 and AudioMix.volume(AudioMix.AMBIENT) > -0.5)

	# Efectos: sin repetir variante y sin cortar uno que suena.
	var repeats: int = 0
	var last: AudioStream
	for i in 12:
		Sfx.play(&"deflect", Vector3.ZERO)
		var current: AudioStream = Sfx._last_variant[&"deflect"]
		if current == last:
			repeats += 1
		last = current
	_check("Doce desvíos seguidos sin repetir la misma variante dos veces (%d repeticiones)" % repeats, repeats == 0)
	var busy: int = Sfx._pool.filter(func(p: AudioStreamPlayer3D) -> bool: return p.playing).size()
	_check("Cada sonido usó un reproductor libre (%d sonando de 12)" % busy, busy >= 12)

	# Ambiente.
	var ambience := get_tree().get_first_node_in_group("ambience") as Ambience
	_check("El Paso tiene ambiente", ambience != null)
	if ambience:
		_check("Sopla el viento, en bucle y en el canal Ambiente", ambience.wind.playing and ambience.wind.bus == AudioMix.AMBIENT
				and (ambience.wind.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD)
		var rivers: int = ambience.get_children().filter(func(n: Node) -> bool: return n is AudioStreamPlayer3D and n.playing).size()
		_check("Suena el arroyo (%d puntos)" % rivers, rivers >= 3)
		_check("Canta un pájaro lejos", ambience.sing() and ambience._bird_player.global_position.distance_to(get_tree().get_first_node_in_group("player").global_position) >= 18.0)
		_check("Suena la música de exploración, suave y en el canal Música", ambience.explore.playing and ambience.explore.bus == AudioMix.MUSIC and ambience.explore.volume_db < -8.0)
		_check("Sin peligro, la capa de tensión calla (%.0f dB)" % ambience.tension.volume_db, ambience.tension.volume_db <= Ambience.SILENT_DB + 1.0)
		# Un soldado ve a Kael de cerca: entra la tensión.
		var player := get_tree().get_first_node_in_group("player") as Player
		var soldier: Enemy
		for node in get_tree().get_nodes_in_group("enemies"):
			if (node as Enemy).display_name == "Soldado de práctica":
				soldier = node
		player.set_spawn(soldier.global_position + Vector3(0, 0, 5), 180.0)
		player.respawn()
		await _wait(2.5)
		_check("Un enemigo te descubre cerca: entra la capa de tensión (%.0f dB)" % ambience.tension.volume_db, ambience.in_danger() and ambience.tension.volume_db > -20.0)
		_check("…en el mismo punto del compás que la exploración", absf(ambience.tension.get_playback_position() - ambience.explore.get_playback_position()) < 0.15)
		var before: int = ambience.birds_sung
		arena.start_fight()
		ambience._bird_left = 0.0
		await _wait(0.3)
		_check("En el duelo con un jefe no cantan pájaros", ambience.birds_sung == before)
		await _wait(2.0)
		_check("…y calla la música de exploración (la pone el jefe)", ambience.explore.volume_db < -40.0)
	Voice.always_speak = false
	print("RESULTADO: %s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	get_tree().quit(_failures)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["OK" if ok else "FALLO", label])
	if not ok:
		_failures += 1
