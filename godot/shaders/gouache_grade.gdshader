shader_type canvas_item;

// Gouache grade — soft warm diffusion + ink vignette, applied to the 3D frame
// only (CanvasLayer -1: below all UI so HUD/menus are never double-styled).
// derived from canon package; do not edit as source (gate G10)
//
// Palette provenance (gate G1, gizmo-design-system/tokens/tokens.json):
//   ink.warm            #352c2b -> INK_WARM (vignette / shadow tone)
//   ground.parchment_warm #fae5cc -> PARCHMENT_WARM (highlight warmth)
// This is a color GRADE, not the Layer-3 painterly post: SHADER-ARCH-01 stays
// open and no brush/smear (look.brush_*) slot is claimed here (gate G12).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float diffusion_strength : hint_range(0.0, 1.0) = 0.16;
uniform float warmth : hint_range(0.0, 1.0) = 0.12;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.26;
uniform float vignette_extent : hint_range(0.5, 2.0) = 1.15;

const vec3 INK_WARM = vec3(0.208, 0.173, 0.169);
const vec3 PARCHMENT_WARM = vec3(0.980, 0.898, 0.800);

void fragment() {
	vec3 base = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	vec3 soft = textureLod(screen_tex, SCREEN_UV, 3.0).rgb;
	// Gentle diffusion: screen-blend a blurred copy back in so light bleeds
	// softly, the way gouache pools at an edge.
	vec3 bloomed = 1.0 - (1.0 - base) * (1.0 - soft * diffusion_strength);
	float luma = dot(bloomed, vec3(0.299, 0.587, 0.114));
	// Split-tone: highlights lean parchment-warm, shadows lean warm ink.
	float hi = smoothstep(0.30, 0.85, luma);
	vec3 toned = bloomed * mix(vec3(1.0), PARCHMENT_WARM * 1.10, warmth * hi);
	toned = mix(toned, INK_WARM * (luma * 1.8 + 0.05), warmth * 0.45 * (1.0 - hi));
	// Ink vignette: corners settle into warm ink, never neutral black.
	vec2 offset = SCREEN_UV - vec2(0.5);
	float edge = smoothstep(0.4, 1.0, length(offset) * vignette_extent);
	vec3 graded = toned * mix(vec3(1.0), INK_WARM * 1.6, edge * vignette_strength);
	COLOR = vec4(graded, 1.0);
}
