shader_type canvas_item;
render_mode world_vertex_coords;

uniform float surface_y = 0.0;
uniform float depth_range = 800.0;
uniform float min_brightness : hint_range(0.5, 1.0) = 0.72;
uniform float cool_tint : hint_range(0.0, 1.0) = 0.5;

varying float v_depth;


void vertex() {
	v_depth = clamp((VERTEX.y - surface_y) / max(depth_range, 1.0), 0.0, 1.0);
}


void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float depth = v_depth;

	float shade = mix(1.0, min_brightness, depth);
	vec3 lit = col.rgb * shade;

	// Hue shift per pixel so brown dirt picks up a cool underground cast.
	float tint_amount = clamp(depth * cool_tint, 0.0, 1.0);
	vec3 cool = lit;
	cool.r *= 0.72;
	cool.g *= 0.86;
	cool.b = clamp(cool.b * 1.28 + 0.05, 0.0, 1.0);

	col.rgb = mix(lit, cool, tint_amount);
	COLOR = col;
}
