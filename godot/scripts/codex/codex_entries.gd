extends RefCounted

## Static Codex entry definitions. Runtime systems unlock these by event id;
## AppShell/audio wiring comes later through the reserved voice_line field.

const TABLE: Dictionary = {
	&"codex_first_blood": {
		"title": "The first felling",
		"unlock_event": &"first_enemy_felled",
		"body": "The first enemy fell, and the book kept the sound of it. Margin marks the moment as proof that the Spark can still answer the dark.",
		"voice_line": &"margin_codex_entry",
		"variant_index": 0,
	},
	&"codex_first_keepsake": {
		"title": "First keepsake",
		"unlock_event": &"first_keepsake_taken",
		"body": "A keepsake settled into Gizmo's keeping, small enough to carry and old enough to remember. Margin writes that memory is a tool when the road forgets its shape.",
		"voice_line": &"margin_codex_entry",
		"variant_index": 1,
	},
	&"codex_first_elite": {
		"title": "First elite",
		"unlock_event": &"first_elite_felled",
		"body": "The stronger machine broke, but not before it showed how the dark learns. Margin records the victory as a warning: every pattern that can sharpen will try.",
		"voice_line": &"margin_codex_entry",
		"variant_index": 2,
	},
	&"codex_first_death": {
		"title": "First death",
		"unlock_event": &"first_light_failed",
		"body": "The light failed, and the book did not close. Margin keeps this page for the hard mercy of return, where even defeat can be carried back to the fire.",
		"voice_line": &"margin_codex_entry",
		"variant_index": 3,
	},
	&"codex_first_victory": {
		"title": "First victory",
		"unlock_event": &"first_beacon_rekindled",
		"body": "A Beacon burned warm again, and the road answered. Margin writes the rekindling as ceremony, not conquest, because guarded light must still be tended.",
		"voice_line": &"margin_codex_entry",
		"variant_index": 4,
	},
	&"codex_the_pattern": {
		"title": "The pattern",
		"unlock_event": &"first_pattern_heard",
		"body": "Something beneath the noise repeated itself, almost like a hymn and almost like a threat. Margin names it the Pattern until the book learns whether it is memory, machine, or both.",
		"voice_line": &"margin_codex_entry",
		"variant_index": 5,
	},
}
