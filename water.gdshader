shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec4 deep_color : source_color = vec4(0.015,0.16,0.28,1.0);
uniform vec4 shallow_color : source_color = vec4(0.04,0.42,0.56,1.0);
uniform float wave_speed = 0.7;
uniform float wave_scale = 0.12;
void vertex() {
    float t = TIME * wave_speed;
    VERTEX.y += sin(VERTEX.x * 0.42 + t) * wave_scale;
    VERTEX.y += cos(VERTEX.z * 0.31 + t * 1.3) * wave_scale * 0.65;
}
void fragment() {
    float wave = 0.5 + 0.5 * sin(UV.x * 42.0 + TIME * 1.2) * cos(UV.y * 36.0 - TIME);
    ALBEDO = mix(deep_color.rgb, shallow_color.rgb, wave * 0.25);
    ROUGHNESS = 0.18;
    METALLIC = 0.12;
}
