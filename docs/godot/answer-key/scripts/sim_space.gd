class_name SimSpace
extends RefCounted

## Sole coordinate seam between flat Simulation state and the 2.5D Godot stage.
## Simulation coordinates stay in source pixels/units. Stage coordinates are meters.

const SIM_UNITS_PER_METER: float = 100.0
const SIM_CENTER: Vector2 = Vector2(1300.0, 850.0)

static func to_world(sim_position: Vector2) -> Vector3:
	return Vector3(
		(sim_position.x - SIM_CENTER.x) / SIM_UNITS_PER_METER,
		0.0,
		(sim_position.y - SIM_CENTER.y) / SIM_UNITS_PER_METER
	)

static func to_world_from_snapshot(snapshot: Dictionary) -> Vector3:
	assert(snapshot.has("x") and snapshot.has("y"), "SimSpace snapshots must contain flat x/y coordinates")
	return to_world(Vector2(float(snapshot["x"]), float(snapshot["y"])))

static func to_sim(world_position: Vector3) -> Vector2:
	return Vector2(
		world_position.x * SIM_UNITS_PER_METER + SIM_CENTER.x,
		world_position.z * SIM_UNITS_PER_METER + SIM_CENTER.y
	)

static func to_world_radius(sim_radius: float) -> float:
	return sim_radius / SIM_UNITS_PER_METER

static func world_size_to_stage(world: Dictionary) -> Vector2:
	return Vector2(
		float(world.get("width", SIM_CENTER.x * 2.0)) / SIM_UNITS_PER_METER,
		float(world.get("height", SIM_CENTER.y * 2.0)) / SIM_UNITS_PER_METER
	)
