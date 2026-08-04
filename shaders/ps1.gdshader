shader_type spatial;
// Look PS1: vertici agganciati a una griglia in spazio schermo (vertex jitter)
// e texture mapping affine (niente correzione prospettica).
// Illuminazione per-vertice, niente speculare: come su hardware PS1.
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

// Griglia di snapping, in "vertici per schermo". Valori bassi = jitter marcato.
uniform vec2 snap_resolution = vec2(160.0, 120.0);
// 0 = nessuno snapping, 1 = snapping pieno.
uniform float snap_strength : hint_range(0.0, 1.0) = 1.0;
// 0 = UV corrette in prospettiva, 1 = warp affine come su PS1.
uniform float affine_strength : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D albedo_texture : source_color, hint_default_white, filter_nearest;
// Colore per-istanza: si imposta sul singolo MeshInstance3D, senza duplicare il materiale.
instance uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec2 v_uv;
varying float v_w;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	if (clip.w > 0.0) {
		vec3 ndc = clip.xyz / clip.w;
		vec2 snapped = round(ndc.xy * snap_resolution) / snap_resolution;
		ndc.xy = mix(ndc.xy, snapped, snap_strength);
		clip = vec4(ndc * clip.w, clip.w);
		VERTEX = (INV_PROJECTION_MATRIX * clip).xyz;
	}
	// La GPU interpola i varying in prospettiva (dividendo per w): passando UV*w
	// e ridividendo nel fragment si ottiene un'interpolazione lineare, cioè affine.
	v_w = mix(1.0, max(clip.w, 0.0001), affine_strength);
	v_uv = UV * v_w;
}

void fragment() {
	vec4 tex = texture(albedo_texture, v_uv / v_w);
	ALBEDO = tex.rgb * albedo_color.rgb;
}
