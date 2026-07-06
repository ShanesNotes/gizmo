class_name PlayerVitals
extends Node

signal vitals_changed(hp: int, max_hp: int, guard: int, max_guard: int)
signal guard_changed(guard: int, max_guard: int)
signal player_died()

@export_range(1, 99) var max_hp: int = 3
@export_range(0, 99) var max_guard: int = 4

var hp: int = max_hp
var guard: int = max_guard
var _dead := false

func _ready() -> void:
	reset()

func reset() -> void:
	hp = maxi(max_hp, 1)
	guard = maxi(max_guard, 0)
	_dead = false
	_emit_vitals_changed()

func apply_damage(amount: int) -> Dictionary:
	var incoming := maxi(amount, 0)
	var absorbed := 0
	var hp_damage := 0
	if incoming <= 0 or _dead:
		return _damage_result(absorbed, hp_damage)

	if guard > 0:
		absorbed = mini(guard, incoming)
		guard -= absorbed
		incoming -= absorbed

	if incoming > 0:
		hp_damage = mini(hp, incoming)
		hp -= hp_damage

	_emit_vitals_changed()
	if hp <= 0 and not _dead:
		_dead = true
		player_died.emit()
	return _damage_result(absorbed, hp_damage)

func is_dead() -> bool:
	return _dead

func _damage_result(absorbed: int, hp_damage: int) -> Dictionary:
	return {
		"absorbed": absorbed,
		"hp_damage": hp_damage,
		"hp": hp,
		"guard": guard,
		"dead": _dead,
	}

func _emit_vitals_changed() -> void:
	vitals_changed.emit(hp, max_hp, guard, max_guard)
	guard_changed.emit(guard, max_guard)
