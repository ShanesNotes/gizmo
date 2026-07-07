class_name RoomTemplate
extends Resource

## Authored definition of a room shape, shared across runs (a run instantiates
## RoomNode entries that point at these, never mutates them). One .tres per
## hand-built room layout.

enum RoomType { COMBAT, ELITE, BOSS, REWARD, SHOP, REST }

@export var template_id: String = ""
@export var biome_id: String = ""
@export var room_type: RoomType = RoomType.COMBAT
@export var scene: PackedScene

## How many outgoing connections this room can offer (Hades rooms are almost
## always 1, occasionally 2 at a branch point; BOSS/REST are terminal or single-exit).
@export_range(0, 3) var min_exits: int = 1
@export_range(0, 3) var max_exits: int = 1

## Matching tags let the generator avoid repeats/pick biome-appropriate flavor
## (e.g. "narrow", "arena", "vertical") without hardcoding scene names.
@export var tags: Array[String] = []
