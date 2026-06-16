extends SceneTree

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const OUTPUT_RELATIVE := "../docs/godot/visual-smoke/main_2_5d_pivot_smoke.png"

func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var root := get_root()
	root.size = Vector2i(1280, 720)

	var main := MainScene.instantiate()
	root.add_child(main)

	for i in 12:
		await process_frame

	var output_path := ProjectSettings.globalize_path("res://" + OUTPUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("Main 2.5D visual smoke capture requires a real display driver; headless may use dummy rendering.")
		quit(1)
		return
	var image := viewport_texture.get_image()
	if image.is_empty():
		push_error("Main 2.5D visual smoke capture produced an empty image")
		quit(1)
		return
	image.crop(1280, 720)
	var err := image.save_png(output_path)
	if err != OK:
		push_error("Failed to save main 2.5D visual smoke PNG: %s" % err)
		quit(1)
		return
	print("Main 2.5D visual smoke saved: %s" % output_path)
	quit(0)
