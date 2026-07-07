class_name RoomHazard
extends Area3D

## Ember hazard strip: scalds whatever stands on it — Gizmo AND enemies — on a
## fixed tick (playtest-2 world mechanic). Authored as flat glowing floor strips
## with no blocking collision, so spawn containment and camera clamps are
## untouched; the danger is positional, readable, and works both ways.

@export_range(1, 99, 1) var damage_per_tick: int = 6
@export_range(0.1, 5.0, 0.05) var tick_seconds: float = 0.75
@export var player_group: StringName = &"player"

var _tick_accumulator := 0.0

func _init() -> void:
	monitoring = true

func _physics_process(delta: float) -> void:
	_tick_accumulator += maxf(delta, 0.0)
	if _tick_accumulator < tick_seconds:
		return
	_tick_accumulator = 0.0
	apply_tick()

## Scald every overlapping body once; returns how many were hit.
func apply_tick() -> int:
	var victims := 0
	for body in get_overlapping_bodies():
		if _scald(body):
			victims += 1
	return victims

func _scald(body: Node3D) -> bool:
	if body is CharacterBody3D and body.is_in_group(player_group):
		var vitals := body.find_child("PlayerVitals", false, false)
		if vitals != null and vitals.has_method("apply_damage"):
			vitals.call("apply_damage", damage_per_tick)
			return true
		return false
	# Hazards burn enemies too, but never charge Spark Surge — the burn is the
	# world's, not Gizmo's.
	if body.has_method("take_damage") and body.has_method("is_dead"):
		if bool(body.call("is_dead")):
			return false
		body.call("take_damage", float(damage_per_tick), false)
		return true
	return false
