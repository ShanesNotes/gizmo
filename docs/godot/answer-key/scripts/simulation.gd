class_name Simulation
extends RefCounted

## First headless-testable slice of game-src-phaser/src/game/simulation.ts.
## Owns pure run state, timers, and player movement. Scenes and input adapters stay outside this file.

const WORLD_WIDTH: int = 2600
const WORLD_HEIGHT: int = 1700
const RUN_DURATION: float = 240.0
const START_X: float = WORLD_WIDTH / 2.0
const START_Y: float = WORLD_HEIGHT / 2.0
const MAX_TICK_DT: float = 0.05
const FIRST_BOUNTY_DELAY: float = 6.2
const FLOW_BURST_STEP: int = 144
const PLAYER_WORLD_MARGIN: float = 70.0
const BASE_MOVE_SPEED: float = 266.0
const SPRINT_SPEED_GAIN: float = 24.0
const EVOLVED_SPRINT_GAIN: float = 34.0

const STATE_SCHEMA_KEYS: Array[String] = [
	"phase",
	"elapsed",
	"run_duration",
	"world",
	"player",
	"enemies",
	"pickups",
	"upgrades",
	"evolved",
	"timers",
	"director",
	"choices",
	"kills",
	"elite_kills",
	"caches_opened",
	"catalyst_caches",
	"cache_evolutions",
	"close_calls",
	"close_call_cooldown",
	"clutch",
	"cache_drop_cooldown",
	"recovery_drop_cooldown",
	"recovery_drops",
	"surge_charge",
	"surge_bursts",
	"flow_bursts",
	"boost_scoops",
	"perfect_scoops",
	"snap_boosts",
	"dash_threads",
	"best_dash_thread",
	"dash_thread_ids",
	"rerolls",
	"rerolls_used",
	"power_echo",
	"echo_charge",
	"echo_bursts",
	"bounty",
	"bounty_cooldown",
	"bounties_cleared",
	"bounty_streak",
	"best_bounty_streak",
	"second_wind_used",
	"combo",
	"flow_save",
	"rarity_finds",
	"rarity_dry_streak",
	"message",
	"message_timer",
]

const PLAYER_SCHEMA_KEYS: Array[String] = [
	"x",
	"y",
	"vx",
	"vy",
	"facing_x",
	"hp",
	"max_hp",
	"invulnerable",
	"dash_cooldown",
	"dash_timer",
	"boost_buffer",
	"boost_queued",
	"level",
	"xp",
	"next_xp",
	"score",
]

const UPGRADE_IDS: Array[String] = [
	"spark",
	"pulse",
	"orbit",
	"magnet",
	"sprint",
	"heart",
	"focus",
	"jackpot",
	"nova",
]

func get_state_schema_keys() -> Array[String]:
	return STATE_SCHEMA_KEYS.duplicate()

func get_player_schema_keys() -> Array[String]:
	return PLAYER_SCHEMA_KEYS.duplicate()

func get_upgrade_ids() -> Array[String]:
	return UPGRADE_IDS.duplicate()

func create_game_state() -> Dictionary:
	return {
		"phase": "playing",
		"elapsed": 0.0,
		"run_duration": RUN_DURATION,
		"world": {
			"width": WORLD_WIDTH,
			"height": WORLD_HEIGHT,
		},
		"player": {
			"x": START_X,
			"y": START_Y,
			"vx": 0.0,
			"vy": 0.0,
			"facing_x": 1.0,
			"hp": 7,
			"max_hp": 7,
			"invulnerable": 0.0,
			"dash_cooldown": 0.0,
			"dash_timer": 0.0,
			"boost_buffer": 0.0,
			"boost_queued": false,
			"level": 1,
			"xp": 0,
			"next_xp": next_xp_for_level(1),
			"score": 0,
		},
		"enemies": [],
		"pickups": [],
		"upgrades": {
			"spark": 1,
			"pulse": 0,
			"orbit": 0,
			"magnet": 0,
			"sprint": 0,
			"heart": 0,
			"focus": 0,
			"jackpot": 0,
			"nova": 0,
		},
		"evolved": {
			"spark": false,
			"pulse": false,
			"orbit": false,
			"magnet": false,
			"sprint": false,
			"heart": false,
			"focus": false,
			"jackpot": false,
			"nova": false,
		},
		"timers": {
			"spawn": 0.0,
			"spark": 0.3,
			"pulse": 1.6,
			"orbit": 0.55,
		},
		"director": {
			"budget": 0.0,
			"next_elite_at": 55.0,
			"wave": 1,
		},
		"choices": [],
		"kills": 0,
		"elite_kills": 0,
		"caches_opened": 0,
		"catalyst_caches": 0,
		"cache_evolutions": 0,
		"close_calls": 0,
		"close_call_cooldown": 0.0,
		"clutch": {
			"count": 0,
			"timer": 0.0,
			"best": 0,
			"bursts": 0,
		},
		"cache_drop_cooldown": 0.0,
		"recovery_drop_cooldown": 0.0,
		"recovery_drops": 0,
		"surge_charge": 0.0,
		"surge_bursts": 0,
		"flow_bursts": 0,
		"boost_scoops": 0,
		"perfect_scoops": 0,
		"snap_boosts": 0,
		"dash_threads": 0,
		"best_dash_thread": 0,
		"dash_thread_ids": [],
		"rerolls": 1,
		"rerolls_used": 0,
		"power_echo": 0.0,
		"echo_charge": 0.0,
		"echo_bursts": 0,
		"bounty": null,
		"bounty_cooldown": FIRST_BOUNTY_DELAY,
		"bounties_cleared": 0,
		"bounty_streak": 0,
		"best_bounty_streak": 0,
		"second_wind_used": false,
		"combo": {
			"count": 0,
			"timer": 0.0,
			"best": 0,
			"next_burst_at": FLOW_BURST_STEP,
		},
		"flow_save": {
			"count": 0,
			"timer": 0.0,
			"best": 0,
			"saves": 0,
		},
		"rarity_finds": {
			"common": 0,
			"uncommon": 0,
			"rare": 0,
			"epic": 0,
		},
		"rarity_dry_streak": 0,
		"message": "Move, dodge, collect shards, pick upgrades.",
		"message_timer": 4.5,
	}

func update_state(state: Dictionary, input: Dictionary = {}, dt: float = 0.0) -> Array[Dictionary]:
	if state.get("phase") != "playing":
		return []

	var events: Array[Dictionary] = []
	var safe_dt: float = clampf(dt, 0.0, MAX_TICK_DT)
	state["elapsed"] = float(state.get("elapsed", 0.0)) + safe_dt
	state["message_timer"] = maxf(0.0, float(state.get("message_timer", 0.0)) - safe_dt)

	var player: Dictionary = state["player"]
	player["invulnerable"] = maxf(0.0, float(player.get("invulnerable", 0.0)) - safe_dt)
	player["dash_cooldown"] = maxf(0.0, float(player.get("dash_cooldown", 0.0)) - safe_dt)
	player["dash_timer"] = maxf(0.0, float(player.get("dash_timer", 0.0)) - safe_dt)
	player["boost_buffer"] = maxf(0.0, float(player.get("boost_buffer", 0.0)) - safe_dt)
	if float(player["boost_buffer"]) <= 0.0:
		player["boost_queued"] = false
	state["player"] = player

	if state.has("dash_thread_ids") and float(player["dash_timer"]) <= 0.0:
		state["dash_thread_ids"] = []

	var had_power_echo: bool = float(state.get("power_echo", 0.0)) > 0.0
	state["power_echo"] = maxf(0.0, float(state.get("power_echo", 0.0)) - safe_dt)
	if had_power_echo and float(state["power_echo"]) <= 0.0:
		state["echo_charge"] = 0.0

	state["close_call_cooldown"] = maxf(0.0, float(state.get("close_call_cooldown", 0.0)) - safe_dt)
	state["cache_drop_cooldown"] = maxf(0.0, float(state.get("cache_drop_cooldown", 0.0)) - safe_dt)
	state["recovery_drop_cooldown"] = maxf(0.0, float(state.get("recovery_drop_cooldown", 0.0)) - safe_dt)

	_update_player(state, input, safe_dt)

	if float(state["elapsed"]) >= float(state["run_duration"]):
		state["phase"] = "complete"
		state["message"] = "Four minutes survived. The playground is yours."
		state["message_timer"] = 99.0
		events.append({"type": "complete"})

	return events

func _update_player(state: Dictionary, input: Dictionary, dt: float) -> void:
	var player: Dictionary = state["player"]
	var input_vector := Vector2(float(input.get("x", 0.0)), float(input.get("y", 0.0)))
	var magnitude: float = input_vector.length()
	var direction: Vector2 = input_vector / magnitude if magnitude > 0.0 else Vector2.ZERO
	var upgrades: Dictionary = state.get("upgrades", {})
	var evolved: Dictionary = state.get("evolved", {})
	var sprint_rank: int = int(upgrades.get("sprint", 0))
	var sprint_evolved: bool = bool(evolved.get("sprint", false))
	var speed: float = BASE_MOVE_SPEED + float(sprint_rank) * SPRINT_SPEED_GAIN + (EVOLVED_SPRINT_GAIN if sprint_evolved else 0.0)
	var target_velocity: Vector2 = direction * speed
	var response: float = 23.0 if magnitude > 0.0 else 30.0
	var blend: float = 1.0 - exp(-response * dt)
	var velocity := Vector2(float(player.get("vx", 0.0)), float(player.get("vy", 0.0))).lerp(target_velocity, blend)
	var next_position := Vector2(float(player["x"]), float(player["y"])) + velocity * dt
	next_position.x = clampf(next_position.x, PLAYER_WORLD_MARGIN, WORLD_WIDTH - PLAYER_WORLD_MARGIN)
	next_position.y = clampf(next_position.y, PLAYER_WORLD_MARGIN, WORLD_HEIGHT - PLAYER_WORLD_MARGIN)
	if next_position.x <= PLAYER_WORLD_MARGIN or next_position.x >= WORLD_WIDTH - PLAYER_WORLD_MARGIN:
		velocity.x = 0.0
	if next_position.y <= PLAYER_WORLD_MARGIN or next_position.y >= WORLD_HEIGHT - PLAYER_WORLD_MARGIN:
		velocity.y = 0.0
	if absf(velocity.x) > 8.0:
		player["facing_x"] = 1.0 if velocity.x > 0.0 else -1.0
	player["vx"] = velocity.x
	player["vy"] = velocity.y
	player["x"] = next_position.x
	player["y"] = next_position.y
	state["player"] = player

func next_xp_for_level(level: int) -> int:
	var base: float = 56.0 + float(level) * 14.0 + pow(float(level), 1.8) * 12.5
	var pacing: float = 1.12 if level == 1 else 1.48 + minf(0.36, float(level - 2) * 0.07)
	return int(floor(base * pacing))
