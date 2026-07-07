class_name RunLifecycle
extends RefCounted

const BoonDraft := preload("res://scripts/boons/boon_draft.gd")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RunBonuses := preload("res://scripts/meta/run_bonuses.gd")

## Small orchestration seam for death -> bank meta currency -> hub -> new run.
## It is intentionally not a scene controller; future hub/run scenes can call
## these methods and listen to these signals.

signal run_started()
signal player_died(banked_scrap: int, banked_sparks: int)
signal returned_to_hub(meta_state: MetaState)
signal run_reset()

enum Phase { HUB, RUNNING }

var meta_state: MetaState
var boon_draft: BoonDraft
var phase: Phase = Phase.HUB
var run_scrap: int = 0
var run_sparks: int = 0
var current_room_id: String = ""
var run_bonuses: Dictionary = {}

func _init(initial_meta_state: MetaState = null, initial_boon_draft: BoonDraft = null) -> void:
	meta_state = initial_meta_state if initial_meta_state != null else MetaState.new()
	boon_draft = initial_boon_draft if initial_boon_draft != null else BoonDraft.new()

func start_new_run(entry_room_id: String = "") -> void:
	_reset_run_scoped_state()
	current_room_id = entry_room_id
	run_bonuses = RunBonuses.from_meta(meta_state)
	phase = Phase.RUNNING
	run_started.emit()

func add_run_currency(scrap: int, sparks: int = 0) -> void:
	run_scrap = maxi(0, run_scrap + maxi(0, scrap))
	run_sparks = maxi(0, run_sparks + maxi(0, sparks))

func handle_player_death(save_path: String = "") -> Error:
	var banked_scrap := run_scrap
	var banked_sparks := run_sparks
	meta_state.bank_currency(banked_scrap, banked_sparks)
	_reset_run_scoped_state()
	phase = Phase.HUB

	var save_error := OK
	if save_path != "":
		save_error = meta_state.save_to_path(save_path)

	player_died.emit(banked_scrap, banked_sparks)
	returned_to_hub.emit(meta_state)
	run_reset.emit()
	return save_error

func _reset_run_scoped_state() -> void:
	run_scrap = 0
	run_sparks = 0
	current_room_id = ""
	run_bonuses = {}
	if boon_draft != null:
		boon_draft.reset_run()
