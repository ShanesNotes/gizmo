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

## The rekindle channel radius (metres) authored into the sim at the Beacon (0019,
## ADR 0005). Lives controller-side because the NorthBeaconDaisZone marker is a bare
## Marker3D with no radius metadata to read — the controller is the radius source.
@export var beacon_radius: float = 3.0

var sim := Simulation.new()
var _enemy_views: Dictionary = {}  # Simulation.Enemy  -> Node3D
var _spark_views: Dictionary = {}  # Simulation.Pickup -> Node3D
var _prev_phase: String = Simulation.PHASE_PLAYING  # to fire the end screen once, on transition

@onready var _audio: Node = get_node_or_null("../GameAudio")

func _ready() -> void:
	if auto_instance_ui:
		_ensure_default_ui()
	_register_arena_obstacles()
	_register_beacon()


## Mirror every SOLID arena piece's declared footprint into the Simulation as an
## obstacle, so enemies (rules-world) respect the same geometry Gizmo already collides
## with (physics-world, via each piece's StaticBody3D). One source of truth — the
## piece — fed into two worlds (ADR 0002). Walkable ground (floor tiles, the foundation)
## is excluded; decorative pieces with no collider don't block.
##
## DUCK-TYPED ON PURPOSE: the obstacle-bearing pieces (the art stream's WorldKitPiece)
## live in a separate, not-yet-committed workstream. We match on declared shape — a
## `footprint_meters` + `placement_role` + a `collision_shape_count()` — instead of the
## class, so this teaching tree compiles and runs with OR without those art assets
## present (no pieces → no obstacles; the headless Simulation tests own correctness). (0014)
func _register_arena_obstacles() -> void:
	_register_obstacles_under(get_tree().current_scene)

## Register every solid arena piece under `root` as a Simulation obstacle. Split from
## _register_arena_obstacles so the duck-typed predicate is unit-testable with a fake
## arena (no current_scene needed) — see run_game_controller_tests.gd.
func _register_obstacles_under(root: Node) -> void:
	if root == null:
		return
	for node in root.find_children("*", "Node3D", true, false):
		var piece := node as Node3D
		if piece == null:
			continue
		var footprint_value: Variant = piece.get(&"footprint_meters")
		if not (footprint_value is Vector2):
			continue  # not an arena piece
		if WALKABLE_ROLES.has(piece.get(&"placement_role")):
			continue  # floor / foundation — the ground, not a wall
		if not piece.has_method(&"collision_shape_count") or int(piece.call(&"collision_shape_count")) <= 0:
			continue  # decorative, no collider — not solid
		var footprint := footprint_value as Vector2
		var radius := maxf(footprint.x, footprint.y) * 0.5
		if radius > 0.0:
			sim.add_obstacle(piece.global_position, radius)


## Author the Beacon into the sim from the scene's NorthBeaconDaisZone marker (ADR
## 0005/0006). Mirrors the obstacle-registration seam: the scene holds the position,
## the controller feeds it to the rules engine (ADR 0002). No marker → beacon stays
## inert (headless tests, or a scene without the dais), exactly like empty obstacles.
func _register_beacon() -> void:
	_register_beacon_under(get_tree().current_scene)

## Split out so the marker-reading is unit-testable with a fake scene — see
## run_game_controller_tests.gd.
func _register_beacon_under(root: Node) -> void:
	if root == null:
		return
	var dais := root.find_child("NorthBeaconDaisZone", true, false)
	if dais is Node3D:
		sim.beacon_position = (dais as Node3D).global_position
		sim.beacon_radius = beacon_radius


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


## Game-feel layer: translate simulation state into reactive audio. Camera shake was
## stripped 2026-06-21 (the shake/bob read as bad juice). Guarded — a null GameAudio
## (headless tests, or the quarantined art stream) is a no-op.
func _apply_game_feel(_frame_events: Array) -> void:
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
		# A faithful forced win is a completed rekindle, not a spent clock (ADR 0005).
		sim.beacon_channel_progress = 1.0
		sim.beacon_state = Simulation.BEACON_REKINDLED
	sim.phase = phase
	if hud != null:
		hud.render(sim)
	_show_end_screen_on_phase_edge()
