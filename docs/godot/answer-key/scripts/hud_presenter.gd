class_name HudPresenter
extends CanvasLayer

## Screen-space presenter for simulation state. It does not own gameplay rules.

@onready var title: Label = %Title

func apply_state(state: Dictionary) -> void:
	var player: Dictionary = state["player"]
	if state.get("phase") == "complete":
		title.text = str(state["message"])
	else:
		title.text = "Elapsed: %.1f s\nPosition: %.0f, %.0f" % [state["elapsed"], player["x"], player["y"]]
