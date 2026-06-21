extends Node3D

## The bridge between the headless Simulation (the rules) and the scene (ADR 0002).
## Owns one Simulation, feeds it Gizmo's position each physics frame, mirrors its
## enemy and Spark data onto visual nodes, drives the HUD (0011), and shows the
## win/lose screen when the run ends (0012). The Simulation is the source of truth;
## this node only renders it.

const EnemyScene := preload("res://scenes/enemy.tscn")
const SparkScene := preload("res://scenes/spark.tscn")
const HudScene := preload("res://scenes/hud.tscn")
const EndScreenScene := preload("res://scenes/end_screen.tscn")

signal simulation_events_emitted(events: Array)

## Arena pieces with these roles are the floor, not walls — never registered as
## obstacles. Everything else solid (has a collider) becomes a sim obstacle. (0014)
const WALKABLE_ROLES: Array[StringName] = [&"walkable_tile", &"foundation"]

## The player node, read for its position (assign Gizmo in the Inspector).
@export var gizmo: Node3D

## The HUD to drive each frame. Optional Inspector assignment; if left empty,
## _ready() instances hud.tscn so the playable scene always shows state.
@export var hud: Hud

## The win/lose screen, revealed once when the run ends. Optional Inspector
## assignment; if left empty, _ready() instances end_screen.tscn.
@export var end_screen: EndScreen

## Keep UI visible even while main.tscn is changing in the art stream. Disable only
## if a future scene composes a different UI controller deliberately.
@export var auto_instance_ui: bool = true

## Debug-build playtest shortcuts: F8 forces gameover, F9 forces run-complete.
## Lets 0012 be verified without waiting for balance to become lethal.
@export var debug_playtest_shortcuts: bool = true

var sim := Simulation.new()
var _enemy_views: Dictionary = {}  # Simulation.Enemy  -> Node3D
var _spark_views: Dictionary = {}  # Simulation.Pickup -> Node3D
var _prev_phase: String = Simulation.PHASE_PLAYING  # to fire the end screen once, on transition
var _prev_hp: float = 0.0  # detect the frame Gizmo is hurt, to drive camera/juice feedback

@onready var _camera: Node = get_node_or_null("../Camera3D")
@onready var _audio: Node = get_node_or_null("../GameAudio")

func _ready() -> void:
	if auto_instance_ui:
		_ensure_default_ui()
	_register_arena_obstacles()
	_prev_hp = sim.hp


## Mirror every SOLID world-kit piece's declared footprint into the Simulation as an
## obstacle, so enemies (rules-world) respect the same geometry Gizmo already collides
## with (physics-world, via each piece's StaticBody3D). One source of truth — the
## piece — fed into two worlds (ADR 0002). Walkable ground (floor tiles, the foundation)
## is excluded; decorative pieces with no collider don't block. Dormant if the scene
## has no world-kit pieces, so headless tests and a bare scene are unaffected. (0014)
func _register_arena_obstacles() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	for node in root.find_children("*", "Node3D", true, false):
		if not node is WorldKitPiece:
			continue
		var piece := node as WorldKitPiece
		if WALKABLE_ROLES.has(piece.placement_role) or piece.collision_shape_count() <= 0:
			continue
		var footprint := piece.footprint_meters
		var radius := maxf(footprint.x, footprint.y) * 0.5
		if radius > 0.0:
			sim.add_obstacle(piece.global_position, radius)


func _unhandled_input(event: InputEvent) -> void:
	if not debug_playtest_shortcuts or not OS.is_debug_build():
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.is_action_pressed(&"debug_force_gameover"):
		force_gameover_for_playtest()
		get_viewport().set_input_as_handled()
	elif key_event.is_action_pressed(&"debug_force_complete"):
		force_complete_for_playtest()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var gizmo_position := gizmo.global_position if gizmo != null else Vector3.ZERO
	sim.tick(delta, gizmo_position)
	var frame_events: Array = sim.last_events.duplicate(true)
	_apply_game_feel(frame_events)
	_sync(sim.enemies, _enemy_views, EnemyScene)
	_sync(sim.pickups, _spark_views, SparkScene)
	if hud != null:
		hud.render(sim)
	if not frame_events.is_empty():
		simulation_events_emitted.emit(frame_events)
	# The frame the run leaves "playing" (win or loss), show the end screen once.
	_show_end_screen_on_phase_edge()

## Mirror a list of data agents (each with a `position`) onto visual nodes:
## add a view for each new agent, move existing views, and free the view of any
## agent that's gone (enemy died / Spark collected). One map per agent type, so
## removal is by identity — no index bookkeeping.
func _sync(agents: Array, views: Dictionary, scene: PackedScene) -> void:
	for agent in agents:
		var view: Node3D = views.get(agent)
		if view == null:
			view = scene.instantiate()
			add_child(view)
			views[agent] = view
		view.global_position = agent.position
	for agent in views.keys():
		if not agents.has(agent):
			views[agent].queue_free()
			views.erase(agent)


## Game-feel layer: translate simulation state into camera shake + reactive audio.
## Additive and guarded — a null camera/audio (e.g. headless tests) is a no-op.
func _apply_game_feel(frame_events: Array) -> void:
	if _camera != null and _camera.has_method("add_trauma"):
		if sim.hp < _prev_hp:
			_camera.add_trauma(0.5)
		for ev in frame_events:
			match ev.get("type", ""):
				"defeat":
					_camera.add_trauma(0.12)
				"levelup":
					_camera.add_trauma(0.35)
	_prev_hp = sim.hp
	if _audio != null:
		var pressure := clampf(float(sim.enemies.size()) / 12.0, 0.0, 1.0)
		if _audio.has_method("set_swarm_intensity"):
			_audio.set_swarm_intensity(pressure)
		if _audio.has_method("duck_music"):
			_audio.duck_music(sim.enemies.size() >= 4)


func force_gameover_for_playtest() -> void:
	_force_finished_phase_for_playtest(Simulation.PHASE_GAMEOVER)


func force_complete_for_playtest() -> void:
	_force_finished_phase_for_playtest(Simulation.PHASE_COMPLETE)


func _ensure_default_ui() -> void:
	if hud == null:
		hud = HudScene.instantiate()
		add_child(hud)
	if end_screen == null:
		end_screen = EndScreenScene.instantiate()
		add_child(end_screen)


func _show_end_screen_on_phase_edge() -> void:
	if end_screen != null and sim.phase != Simulation.PHASE_PLAYING and _prev_phase == Simulation.PHASE_PLAYING:
		end_screen.show_outcome(sim)
	_prev_phase = sim.phase


func _force_finished_phase_for_playtest(phase: String) -> void:
	if phase != Simulation.PHASE_GAMEOVER and phase != Simulation.PHASE_COMPLETE:
		return
	if sim.phase != Simulation.PHASE_PLAYING:
		return
	if phase == Simulation.PHASE_GAMEOVER:
		sim.hp = 0
	else:
		sim.elapsed = sim.run_duration
	sim.phase = phase
	if hud != null:
		hud.render(sim)
	_show_end_screen_on_phase_edge()
