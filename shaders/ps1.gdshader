shader_type spatial;
// Look PS1: vertici agganciati a una griglia in spazio schermo (vertex jitter)
// e texture mapping affine (niente correzione prospettica).
// Illuminazione per-vertice, niente speculare: come su hardware PS1.
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

// Parametri globali del look, uguali per tutti i materiali.
// Si regolano in Progetto > Impostazioni progetto > Shader Globals.
global uniform vec2 ps1_snap_resolution;
global uniform float ps1_snap_strength;
global uniform float ps1_affine_strength;

// Texture e ripetizione: proprie di ogni materiale.
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_nearest;
uniform vec2 uv_scale = vec2(1.0, 1.0);

// Proprie del singolo oggetto: si cambiano sul MeshInstance3D senza duplicare il materiale.
instance uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float emission_amount = 0.0;

varying vec2 v_uv;
varying float v_w;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	if (clip.w > 0.0) {
		vec3 ndc = clip.xyz / clip.w;
		vec2 snapped = round(ndc.xy * ps1_snap_resolution) / ps1_snap_resolution;
		ndc.xy = mix(ndc.xy, snapped, ps1_snap_strength);
		clip = vec4(ndc * clip.w, clip.w);
		VERTEX = (INV_PROJECTION_MATRIX * clip).xyz;
	}
	// La GPU interpola i varying in prospettiva (dividendo per w): passando UV*w
	// e ridividendo nel fragment si ottiene un'interpolazione lineare, cioè affine.
	v_w = mix(1.0, max(clip.w, 0.0001), ps1_affine_strength);
	v_uv = UV * uv_scale * v_w;
}

void fragment() {
	vec3 color = texture(albedo_texture, v_uv / v_w).rgb * albedo_color.rgb;
	ALBEDO = color;
	EMISSION = color * emission_amount;
}
