shader_type canvas_item;

// Gouache grade + painterly pass — applied to the 3D frame only
// (CanvasLayer -1: below all UI so HUD/menus are never double-styled).
// derived from canon package; do not edit as source (gate G10)
//
// G12 — gouache render target (SHADER-ARCH-01 ruled 2026-07-07, design lane):
// whole-frame painterly pass implemented as a canvas_item accent BELOW the UI
// layer (mask-by-construction), per the shader-matrix recommendation that the
// post is a SUBTLE finishing accent, never the foundation. A small-radius
// isotropic Kuwahara supplies the gouache "brush pool"; the split-tone grade
// and ink vignette remain the base. Toggle: gizmo/look/gouache_paint_enabled
// (driven by scripts/ui/look_grade.gd — revert is one flag).
//
// Palette provenance (gate G1, gizmo-design-system/tokens/tokens.json):
//   ink.warm              #352c2b -> INK_WARM (vignette / shadow tone)
//   ground.parchment_warm #fae5cc -> PARCHMENT_WARM (highlight warmth)
// World-state tint (HZ-108B) consumes tokens.state.* by way of the driver
// script; the shader carries only neutral uniforms (no symbolic prose here).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float diffusion_strength : hint_range(0.0, 1.0) = 0.16;
uniform float warmth : hint_range(0.0, 1.0) = 0.12;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.26;
uniform float vignette_extent : hint_range(0.5, 2.0) = 1.15;

// G12 painterly accent (Layer 3 accent per shader-matrix; subtle by doctrine).
// Kuwahara pools brush regions; edge ink darkens where value changes (paint
// settling at a boundary); paper grain carries the gouache tooth on the flat
// greybox surfaces the Kuwahara alone cannot restyle. All three ride the
// gouache_paint_enabled flag (driver zeroes them when disabled).
uniform float paint_strength : hint_range(0.0, 1.0) = 0.45;
uniform int paint_radius : hint_range(1, 4) = 3;
uniform float edge_ink_strength : hint_range(0.0, 1.0) = 0.35;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.10;

// HZ-108B world-state tint (hub warm / combat ember-tense / cleared relief).
// Driver tweens these on state edges; tint is pre-normalized to ~unit luma.
uniform vec3 state_tint : source_color = vec3(1.0);
uniform float state_tint_strength : hint_range(0.0, 1.0) = 0.0;

const vec3 INK_WARM = vec3(0.208, 0.173, 0.169);
const vec3 PARCHMENT_WARM = vec3(0.980, 0.898, 0.800);

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

// Soft value noise — the paper tooth. Two octaves, screen-locked.
float paper(vec2 uv_px) {
	vec2 i = floor(uv_px);
	vec2 f = fract(uv_px);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Isotropic Kuwahara: pick the lowest-variance quadrant mean — flat pools of
// paint with preserved edges. Radius stays small (<=4) so the smear never
// erodes the silhouettes the fixed camera reads (gate G7).
vec3 kuwahara(vec2 uv, vec2 pixel, int radius) {
	vec3 best_mean = vec3(0.0);
	float best_var = 1e9;
	for (int q = 0; q < 4; q++) {
		vec2 sign_q = vec2(q == 0 || q == 3 ? 1.0 : -1.0, q < 2 ? 1.0 : -1.0);
		vec3 sum = vec3(0.0);
		vec3 sq = vec3(0.0);
		float n = 0.0;
		for (int x = 0; x <= radius; x++) {
			for (int y = 0; y <= radius; y++) {
				vec3 c = textureLod(screen_tex, uv + pixel * sign_q * vec2(float(x), float(y)), 0.0).rgb;
				sum += c;
				sq += c * c;
				n += 1.0;
			}
		}
		vec3 mean = sum / n;
		float variance = dot(sq / n - mean * mean, vec3(1.0));
		if (variance < best_var) {
			best_var = variance;
			best_mean = mean;
		}
	}
	return best_mean;
}

void fragment() {
	vec3 base = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	vec2 pixel = 1.0 / vec2(textureSize(screen_tex, 0));
	if (paint_strength > 0.001) {
		base = mix(base, kuwahara(SCREEN_UV, pixel, paint_radius), paint_strength);
	}
	if (edge_ink_strength > 0.001) {
		// Ink pooling: darken where the softened frame changes value fast —
		// paint settling against a boundary, the woodcut line for free.
		float l0 = dot(textureLod(screen_tex, SCREEN_UV, 1.0).rgb, vec3(0.299, 0.587, 0.114));
		float lx = dot(textureLod(screen_tex, SCREEN_UV + vec2(pixel.x * 2.0, 0.0), 1.0).rgb, vec3(0.299, 0.587, 0.114));
		float ly = dot(textureLod(screen_tex, SCREEN_UV + vec2(0.0, pixel.y * 2.0), 1.0).rgb, vec3(0.299, 0.587, 0.114));
		float grad = clamp(length(vec2(lx - l0, ly - l0)) * 6.0, 0.0, 1.0);
		base = mix(base, INK_WARM * (l0 * 0.9 + 0.10), grad * edge_ink_strength);
	}
	if (grain_strength > 0.001) {
		// Paper tooth: fine two-scale value noise, multiplied around 1.0.
		vec2 px = SCREEN_UV / pixel;
		float g = paper(px * 0.45) * 0.65 + paper(px * 0.12) * 0.35;
		base *= 1.0 + (g - 0.5) * 2.0 * grain_strength;
	}
	vec3 soft = textureLod(screen_tex, SCREEN_UV, 3.0).rgb;
	// Gentle diffusion: screen-blend a blurred copy back in so light bleeds
	// softly, the way gouache pools at an edge.
	vec3 bloomed = 1.0 - (1.0 - base) * (1.0 - soft * diffusion_strength);
	float luma = dot(bloomed, vec3(0.299, 0.587, 0.114));
	// Split-tone: highlights lean parchment-warm, shadows lean warm ink.
	float hi = smoothstep(0.30, 0.85, luma);
	vec3 toned = bloomed * mix(vec3(1.0), PARCHMENT_WARM * 1.10, warmth * hi);
	toned = mix(toned, INK_WARM * (luma * 1.8 + 0.05), warmth * 0.45 * (1.0 - hi));
	// World-state tint: multiplicative hue shift at ~unit luma, so the wash
	// changes temperature without crushing value structure.
	toned = mix(toned, toned * state_tint, state_tint_strength);
	// Ink vignette: corners settle into warm ink, never neutral black.
	vec2 offset = SCREEN_UV - vec2(0.5);
	float edge = smoothstep(0.4, 1.0, length(offset) * vignette_extent);
	vec3 graded = toned * mix(vec3(1.0), INK_WARM * 1.6, edge * vignette_strength);
	COLOR = vec4(graded, 1.0);
}
