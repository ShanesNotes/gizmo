class_name EndScreen
extends CanvasLayer

## Hub-return summary for a finished run.

## Death/victory presentation beat: the summary eases in from ink-dark over
## this long instead of popping (the panel is visible immediately; only its
## modulate alpha is animated, so overlay/visibility contracts are untouched).
const INK_FADE_SECONDS := 0.8
const FELLED_ARCHETYPES: Array[String] = ["chaff", "bruiser", "elite", "boss"]
const INK_PANEL := Color(0.1020, 0.0824, 0.0706, 0.92)
const DEATH_WASH := Color(0.1098, 0.0902, 0.0980, 0.78)
const VICTORY_WASH := Color(0.0706, 0.0549, 0.0941, 0.48)
const PARCHMENT := Color(0.9804, 0.8980, 0.8000, 1.0)
const INK_TEXT := Color(0.2078, 0.1725, 0.1686, 1.0)
const BRASS := Color(0.6902, 0.5529, 0.3412, 1.0)
const BRASS_LIT := Color(0.8784, 0.7569, 0.4784, 1.0)
const CRIMSON_DULL := Color(0.4941, 0.1059, 0.0863, 1.0)
const PARCHMENT_LIGHT := Color(0.9922, 0.9373, 0.8706, 1.0)
const PARCHMENT_DIM := Color(0.7569, 0.6667, 0.5686, 1.0)

var _fade_tween: Tween = null
var _meta_tween: Tween = null

@onready var _root: Control = %Root
@onready var _dim: ColorRect = get_node("Root/Dim") as ColorRect
@onready var _panel: PanelContainer = get_node("Root/Center/Panel") as PanelContainer
@onready var _title: Label = %TitleLabel
@onready var _flavor: Label = %FlavorLabel
@onready var _result_value: Label = %ResultValue
@onready var _rooms_value: Label = %RoomsValue
@onready var _boons_value: Label = %BoonsValue
@onready var _scrap_value: Label = %ScrapValue
@onready var _survived_value: Label = %SurvivedValue
@onready var _enemies_felled_value: Label = %EnemiesFelledValue
@onready var _sparks_rescued_value: Label = %SparksRescuedValue
@onready var _deepest_region_value: Label = %DeepestRegionValue
@onready var _meta_progress: Control = %MetaProgress
@onready var _meta_progress_label: Label = %MetaProgressLabel
@onready var _meta_progress_bar: ProgressBar = %MetaProgressBar
@onready var _meta_progress_value: Label = %MetaProgressValue
@onready var _retry_button: Button = %RetryButton

func _ready() -> void:
	_root.visible = false
	_meta_progress.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)

static func title_for(victory: bool) -> String:
	return "VIGIL KEPT" if victory else "THE LIGHT FAILED"

static func result_for(victory: bool) -> String:
	return "KEPT" if victory else "FAILED"

func show_run_summary(stats: Dictionary) -> void:
	var victory := bool(stats.get("victory", false))
	_apply_outcome_theme(victory)
	_title.text = title_for(victory)
	_flavor.text = "Margin enters it in the Codex." if victory else "Return to the hearth. The vigil remembers."
	_result_value.text = result_for(victory)
	_rooms_value.text = str(maxi(0, int(stats.get("rooms_cleared", 0))))
	_boons_value.text = str(maxi(0, int(stats.get("boons_taken", 0))))
	_scrap_value.text = str(maxi(0, int(stats.get("scrap_banked", 0))))
	_survived_value.text = Hud.format_clock(maxf(0.0, float(stats.get("survived_seconds", 0.0))))
	_enemies_felled_value.text = _format_enemies_felled(stats.get("enemies_felled", {}))
	_sparks_rescued_value.text = str(maxi(0, int(stats.get("sparks_rescued", stats.get("sparks_banked", 0)))))
	_deepest_region_value.text = String(stats.get("deepest_region", "Unknown"))
	_update_meta_progress(stats, victory)
	_play_ink_fade()
	_root.visible = true
	_retry_button.grab_focus()

func _format_enemies_felled(value: Variant) -> String:
	var counts: Dictionary = value if value is Dictionary else {}
	var parts: Array[String] = []
	for archetype in FELLED_ARCHETYPES:
		parts.append("%d %s" % [maxi(0, int(counts.get(archetype, 0))), archetype])
	return " / ".join(parts)

func _play_ink_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if not is_inside_tree():
		_root.modulate.a = 1.0
		return
	_root.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_root, "modulate:a", 1.0, INK_FADE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func show_outcome(sim: Simulation) -> void:
	var victory := sim != null and sim.phase == Simulation.PHASE_COMPLETE
	var survived_seconds := sim.elapsed if sim != null else 0.0
	show_run_summary({
		"rooms_cleared": 0,
		"boons_taken": 0,
		"scrap_banked": 0,
		"survived_seconds": survived_seconds,
		"victory": victory,
	})
	# Compatibility for the pre-pivot controller path. Hades-flow callers should
	# use show_run_summary(stats).
	_title.text = "BEACON REKINDLED" if victory else "GIZMO'S LIGHT FAILED"

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _apply_outcome_theme(victory: bool) -> void:
	if _dim != null:
		_dim.color = VICTORY_WASH if victory else DEATH_WASH
	if _panel != null:
		_panel.add_theme_stylebox_override(&"panel", _panel_style(victory))

	_title.add_theme_color_override(&"font_color", BRASS_LIT if victory else CRIMSON_DULL)
	_flavor.add_theme_color_override(&"font_color", INK_TEXT if victory else PARCHMENT_DIM)

	var labels: Array[Label] = [
		_result_value,
		_rooms_value,
		_boons_value,
		_scrap_value,
		_survived_value,
		_enemies_felled_value,
		_sparks_rescued_value,
		_deepest_region_value,
	]
	for label in labels:
		label.add_theme_color_override(&"font_color", INK_TEXT if victory else PARCHMENT_LIGHT)

	var stats := get_node_or_null("Root/Center/Panel/Margin/VBox/Stats")
	if stats != null:
		for child in stats.get_children():
			var label := child as Label
			if label != null and not labels.has(label):
				label.add_theme_color_override(&"font_color", BRASS if victory else PARCHMENT_DIM)
				label.add_theme_font_size_override(&"font_size", 15)

	_apply_storybook_button(_retry_button, victory)

func _panel_style(victory: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT if victory else INK_PANEL
	style.border_color = BRASS_LIT if victory else CRIMSON_DULL
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = 12
	return style

func _apply_storybook_button(button: Button, victory: bool) -> void:
	if button == null:
		return
	var bg := PARCHMENT if victory else INK_PANEL
	var text := INK_TEXT if victory else PARCHMENT_LIGHT
	var hover_text := CRIMSON_DULL if not victory else BRASS
	var border := BRASS_LIT if victory else CRIMSON_DULL
	button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 190.0), 48.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override(&"font_size", 20)
	button.add_theme_color_override(&"font_color", text)
	button.add_theme_color_override(&"font_hover_color", hover_text)
	button.add_theme_color_override(&"font_focus_color", hover_text)
	button.add_theme_color_override(&"font_pressed_color", text)
	button.add_theme_stylebox_override(&"normal", _button_style(bg, border, 2, 10))
	button.add_theme_stylebox_override(&"hover", _button_style(bg.lightened(0.08), BRASS_LIT, 2, 10))
	button.add_theme_stylebox_override(&"pressed", _button_style(bg.darkened(0.08), border, 2, 10))
	button.add_theme_stylebox_override(&"focus", _button_style(Color(0.8784, 0.7569, 0.4784, 0.24), BRASS_LIT, 3, 10))

func _button_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 22.0
	style.content_margin_top = 10.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 10.0
	return style

func _update_meta_progress(stats: Dictionary, victory: bool) -> void:
	if _meta_tween != null and _meta_tween.is_valid():
		_meta_tween.kill()
	if not victory:
		_meta_progress.visible = false
		return

	var rank_current: Variant = _first_number(stats, [
		"keeper_rank_new",
		"new_keeper_rank",
		"keeper_rank",
	])
	if rank_current != null:
		var rank_previous: Variant = _first_number(stats, [
			"keeper_rank_previous",
			"previous_keeper_rank",
		])
		_show_meta_progress(
			float(rank_previous) if rank_previous != null else 0.0,
			float(rank_current),
			"KEEPER RANK",
			false
		)
		return

	var progress_current: Variant = _first_number(stats, [
		"keeper_progress_new",
		"new_keeper_progress",
		"keeper_progress",
		"meta_progress_new",
		"new_meta_progress",
		"meta_progress",
	])
	if progress_current == null:
		_meta_progress.visible = false
		return
	var progress_previous: Variant = _first_number(stats, [
		"keeper_progress_previous",
		"previous_keeper_progress",
		"meta_progress_previous",
		"previous_meta_progress",
	])
	_show_meta_progress(
		float(progress_previous) if progress_previous != null else 0.0,
		float(progress_current),
		"KEEPER PROGRESS",
		true
	)

func _first_number(stats: Dictionary, keys: Array[String]) -> Variant:
	for key in keys:
		var raw: Variant = stats.get(key, null)
		if raw is int or raw is float:
			return raw
		if raw is String and raw.is_valid_float():
			return raw.to_float()
	return null

func _show_meta_progress(previous_value: float, current_value: float, label_text: String, normalized: bool) -> void:
	_meta_progress.visible = true
	_meta_progress_label.text = label_text
	_meta_progress_label.add_theme_color_override(&"font_color", BRASS)
	_meta_progress_value.add_theme_color_override(&"font_color", INK_TEXT)
	_meta_progress_bar.min_value = 0.0
	_meta_progress_bar.max_value = 1.0 if normalized else maxf(1.0, maxf(previous_value, current_value))
	_meta_progress_bar.add_theme_stylebox_override(&"background", _button_style(PARCHMENT.darkened(0.16), BRASS, 1, 8))
	_meta_progress_bar.add_theme_stylebox_override(&"fill", _button_style(BRASS_LIT, BRASS_LIT, 0, 8))
	_set_meta_progress_display(previous_value, normalized)
	if not is_inside_tree():
		_set_meta_progress_display(current_value, normalized)
		return
	_meta_tween = create_tween()
	_meta_tween.tween_method(
		Callable(self, "_set_meta_progress_display").bind(normalized),
		previous_value,
		current_value,
		0.9
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_meta_progress_display(value: float, normalized: bool) -> void:
	_meta_progress_bar.value = clampf(value, _meta_progress_bar.min_value, _meta_progress_bar.max_value)
	if normalized:
		_meta_progress_value.text = "%d%%" % int(roundf(clampf(value, 0.0, 1.0) * 100.0))
	else:
		_meta_progress_value.text = "Rank %d" % int(roundf(maxf(0.0, value)))
