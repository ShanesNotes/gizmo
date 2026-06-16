extends SceneTree

const PanelScene := preload("res://ui/components/panel/panel.tscn")
const LumenTheme := preload("res://ui/theme.tres")
const OUTPUT_RELATIVE := "../docs/godot/visual-smoke/panel_phase1_smoke.png"

func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var root := get_root()
	root.size = Vector2i(640, 360)

	var background := ColorRect.new()
	background.color = LumenTheme.get_color("void", "LumenTokens")
	background.size = Vector2(640, 360)
	root.add_child(background)

	var panel := PanelScene.instantiate()
	panel.position = Vector2(142, 112)
	panel.size = Vector2(356, 136)
	panel.set("eyebrow_text", "Covenant")
	panel.set("body_text", "Pulse Driver · Spark Magnet · Echo Coil")
	background.add_child(panel)

	for i in 5:
		await process_frame

	var output_path := ProjectSettings.globalize_path("res://" + OUTPUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("Visual smoke capture requires a real display driver; headless uses dummy rendering.")
		quit(1)
		return
	var image := viewport_texture.get_image()
	if image.is_empty():
		push_error("Visual smoke capture produced an empty image")
		quit(1)
		return
	image.crop(640, 360)
	var err := image.save_png(output_path)
	if err != OK:
		push_error("Failed to save visual smoke PNG: %s" % err)
		quit(1)
		return
	print("Panel visual smoke saved: %s" % output_path)
	quit(0)
