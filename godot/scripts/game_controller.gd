extends Node3D

## The bridge between the headless Simulation (the rules) and the scene (ADR 0002).
## Owns one Simulation, feeds it Gizmo's position each physics frame, mirrors its
## enemy and Spark data onto visual nodes, and drives the HUD (0011). The Simulation
## is the source of truth; this node only renders it.

const EnemyScene := preload("res://scenes/enemy.tscn")
const SparkScene := preload("res://scenes/spark.tscn")

## The player node, read for its position (assign Gizmo in the Inspector).
@export var gizmo: Node3D

## The HUD to drive each frame (assign a hud.tscn instance in the Inspector; 0011).
## Optional — the bridge runs fine without it (the HUD just won't update).
@export var hud: Hud

var sim := Simulation.new()
var _enemy_views: Dictionary = {}  # Simulation.Enemy  -> Node3D
var _spark_views: Dictionary = {}  # Simulation.Pickup -> Node3D

func _physics_process(delta: float) -> void:
	var gizmo_position := gizmo.global_position if gizmo != null else Vector3.ZERO
	sim.tick(delta, gizmo_position)
	_sync(sim.enemies, _enemy_views, EnemyScene)
	_sync(sim.pickups, _spark_views, SparkScene)
	if hud != null:
		hud.render(sim)

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
