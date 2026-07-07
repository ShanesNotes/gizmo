class_name BeaconLandmark
extends Node3D

## Wrapper state driver for beacon lighting.
enum BeaconState { DORMANT, REKINDLING, REKINDLED }

@export var state: BeaconState = BeaconState.DORMANT:
	set(value):
		state = value
		_apply_state()

func _ready() -> void:
	_apply_state()

func _apply_state() -> void:
	var hearth_light := get_node_or_null("HearthLight") as OmniLight3D
	if hearth_light == null:
		return

	match state:
		BeaconState.DORMANT:
			hearth_light.light_energy = 0.0
		BeaconState.REKINDLING:
			hearth_light.light_energy = 2.6
			hearth_light.light_color = Color(1, 0.68, 0.35)
			hearth_light.omni_range = 14.0
		BeaconState.REKINDLED:
			hearth_light.light_energy = 5.5
			hearth_light.light_color = Color(1, 0.8, 0.52)
			hearth_light.omni_range = 20.0
		_:
			hearth_light.light_energy = 0.0
