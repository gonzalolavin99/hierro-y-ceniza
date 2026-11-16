extends SceneTree
## Integration checks using the actual review scene and assets, without the external Mixamo rig.
var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var scene = load("res://scenes/volsungos/visual_review.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check("Two articulated studies", scene.actors.size() == 2)
	var actor: VolsungosReviewActor = scene.actors[0]
	for piece: String in ["WoolTunic", "TunicSkirt", "LeatherBelt", "BeltClasp", "LeftShoulder", "RightShoulder", "LeftBracer", "RightBracer", "LeftBoot", "RightBoot", "ShortCape", "CapeClasp"]:
		check("Bone attachment: " + piece, actor.skeleton.get_node_or_null("Volsungos_" + piece) is BoneAttachment3D)
	check("Hero keeps bare head", actor.skeleton.get_node_or_null("Volsungos_Helmet") == null)
	check("Enemy silhouette has helmet", scene.actors[1].skeleton.has_node("Volsungos_Helmet"))
	var attachment: BoneAttachment3D = actor.costume.attachments[0]
	var before := attachment.global_transform
	scene._cycle_motion()
	check("Walk selected on both actors", scene.actors[0].motion == 1 and scene.actors[1].motion == 1)
	scene._cycle_motion()
	await create_timer(0.3).timeout
	check("Attachments move with animated skeleton", not attachment.global_transform.is_equal_approx(before))
	for file: String in ["hall", "sigurd", "siggeir", "signy"]:
		var render_path := "res://assets/volsungos/%s.jpg" % file
		if ResourceLoader.exists(render_path):
			var texture = load(render_path)
			check("Imported render " + file, texture is Texture2D and texture.get_width() > 0)
		else:
			check("Missing render is an explicit placeholder: " + file, _has_placeholder(scene, file))
	var has_clip := ResourceLoader.exists("res://assets/volsungos/forge.ogv")
	if has_clip:
		check("Native Theora stream", load("res://assets/volsungos/forge.ogv") is VideoStreamTheora)
	scene._show_forge()
	await process_frame
	check("Cinema visibility and playback", scene._cinema.player.is_playing() == has_clip and not scene._ui.visible)
	if not has_clip:
		check("Absent video has a return button", scene._cinema._back.text.contains("no disponible"))
	scene._cinema.close()
	await process_frame
	check("Return restores review and focus", scene._ui.visible and scene._motion_button.has_focus())
	if has_clip:
		scene._show_forge()
		await process_frame
		await create_timer(6.7).timeout
		check("End of clip returns automatically", scene._cinema == null and scene._ui.visible)
	var followers: Array[BoneAttachment3D] = actor.costume.attachments.duplicate()
	actor.costume.queue_free()
	await process_frame
	await process_frame
	check("Costume cleanup removes bone attachments", not is_instance_valid(followers[0]))
	scene.queue_free()
	await process_frame
	print("RESULTADO: " + ("TODO OK" if failures == 0 else str(failures) + " FALLOS"))
	quit(failures)


func _has_placeholder(scene: Node, file: String) -> bool:
	var label_text: String = {"hall": "Salón", "sigurd": "Sigurd", "siggeir": "Siggeir", "signy": "Signy"}[file]
	for label: Node in scene.find_children("*", "Label", true, false):
		if label.text.contains(label_text) and label.text.contains("Sin imagen local"):
			return true
	return false


func check(label: String, passed: bool) -> void:
	print("[%s] %s" % ["OK" if passed else "FALLO", label])
	if not passed:
		failures += 1
