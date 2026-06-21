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

func _ready() -> void:
	if auto_instance_ui:
		_ensure_default_ui()


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
	_sync(sim.enemies, _enemy_views, EnemyScene)
	_sync(sim.pickups, _spark_views, SparkScene)
	if hud != null:
		hud.render(sim)
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
