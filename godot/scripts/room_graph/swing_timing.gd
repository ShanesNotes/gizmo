class_name SwingTiming
extends RefCounted

## Single source of truth for melee swing choreography (playtest 2:
## animation-led combat). The resolver delays damage to `contact`, and the
## animation clips place their strike pose on the same second, so the contact
## frame IS the damage frame. `length` is the full clip; what follows contact
## is follow-through, cancellable by the kit's own recovery rules.
##
## Times are seconds from the attack input. Kept short: Hades-style melee
## reads as instant (~6-9 frames of windup at 60fps), it is never sluggish.

const MELEE_STEPS := {
	1: {"contact": 0.10, "length": 0.40},  # forehand sweep, right-to-left
	2: {"contact": 0.10, "length": 0.40},  # backhand return, left-to-right
	3: {"contact": 0.14, "length": 0.50},  # overhead finisher, heavier
}

const SPECIAL := {"contact": 0.22, "length": 0.60}

static func melee_contact_delay(step: int) -> float:
	var key := clampi(step, 1, MELEE_STEPS.size())
	return float(MELEE_STEPS[key]["contact"])

static func melee_clip_length(step: int) -> float:
	var key := clampi(step, 1, MELEE_STEPS.size())
	return float(MELEE_STEPS[key]["length"])

static func special_contact_delay() -> float:
	return float(SPECIAL["contact"])

static func special_clip_length() -> float:
	return float(SPECIAL["length"])

static func melee_clip_name(step: int) -> StringName:
	return StringName("attack_%d" % clampi(step, 1, MELEE_STEPS.size()))
