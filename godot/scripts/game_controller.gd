extends Node3D

## The bridge between the headless Simulation (the rules) and the scene (ADR 0002).
## Owns one Simulation, feeds it Gizmo's position each physics frame, and mirrors
## its enemy data onto visual nodes. The Simulation is the source of truth; this
## node only renders it.

const EnemyScene := preload("res://scenes/enemy.tscn")

## The player node, read for its position (assign Gizmo in the Inspector).
@export var gizmo: Node3D

var sim := Simulation.new()
var _views: Array[Node3D] = []  # one visual per sim enemy, parallel by index

func _physics_process(delta: float) -> void:
	var gizmo_position := gizmo.global_position if gizmo != null else Vector3.ZERO
	sim.tick(delta, gizmo_position)

	# Enemies only grow in 0008 (no deaths yet), so add a visual for each new one…
	while _views.size() < sim.enemies.size():
		var view: Node3D = EnemyScene.instantiate()
		add_child(view)
		_views.append(view)

	# …then mirror each enemy's position onto its visual.
	for i in sim.enemies.size():
		_views[i].global_position = sim.enemies[i].position
