shader_type sky;

// Gizmo cosmos sky — procedural fallback for the gouache backdrop.
// derived from design canon; do not edit as source (gizmo-design-system).
//
// Palette provenance (gate G1, gizmo-design-system/tokens/tokens.json):
//   cool.void          #1c1f23 -> zenith_color
//   cool.night_blue    #2a4468 -> mid_color
//   accent.enchant_plum #574073 -> horizon_color
//   ink.deep           #1c1719 -> under_color (below horizon)
//   exposure.ember     #e0461e -> ember_color (M8 warm horizon; the far hearth)
//   metal.gold_lit     #e0c17a -> star_color (gilt manuscript asterisks, M6)
// No teal anywhere (gate G6): the First Ember's light never leaks into the sky.

uniform vec3 zenith_color : source_color = vec3(0.110, 0.122, 0.137);
uniform vec3 mid_color : source_color = vec3(0.165, 0.267, 0.408);
uniform vec3 horizon_color : source_color = vec3(0.341, 0.251, 0.451);
uniform vec3 under_color : source_color = vec3(0.110, 0.090, 0.098);
uniform vec3 ember_color : source_color = vec3(0.878, 0.275, 0.118);
uniform vec3 star_color : source_color = vec3(0.878, 0.757, 0.478);

// Azimuth (radians) the warm ember horizon faces; aim it at the run's
// Beacon end so warmth reads as the destination (X-S3 composition).
uniform float ember_azimuth : hint_range(-3.1416, 3.1416) = 0.0;
uniform float ember_strength : hint_range(0.0, 1.0) = 0.65;
uniform float ember_focus : hint_range(1.0, 16.0) = 5.0;
uniform float star_density : hint_range(4.0, 64.0) = 22.0;
uniform float star_amount : hint_range(0.0, 1.0) = 0.10;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void sky() {
	float h = EYEDIR.y;

	// Painted gradient: plum horizon -> night blue -> void zenith.
	vec3 col = mix(horizon_color, mid_color, smoothstep(0.02, 0.38, h));
	col = mix(col, zenith_color, smoothstep(0.30, 0.85, h));
	col = mix(under_color, col, smoothstep(-0.12, 0.02, h));

	// Warm ember band low on the horizon, windowed to one azimuth sector.
	float az = atan(EYEDIR.x, -EYEDIR.z);
	float toward = pow(cos(az - ember_azimuth) * 0.5 + 0.5, ember_focus);
	float band = smoothstep(0.30, 0.0, abs(h - 0.02));
	float glow = band * toward * ember_strength;
	col = mix(col, ember_color, glow);

	// Gilt star asterisks: hashed cells over spherical coords, above the
	// horizon only, thinned where the ember glow warms the field.
	vec2 sph = vec2(az, asin(clamp(h, -1.0, 1.0))) * star_density;
	vec2 cell = floor(sph);
	float rnd = hash21(cell);
	if (rnd < star_amount) {
		vec2 star_pos = vec2(hash21(cell + 17.0), hash21(cell + 43.0)) * 0.6 + 0.2;
		float d = length(fract(sph) - star_pos);
		float star = smoothstep(0.10, 0.02, d);
		star *= smoothstep(0.04, 0.15, h) * (1.0 - glow);
		col = mix(col, star_color, star);
	}

	COLOR = col;
}
