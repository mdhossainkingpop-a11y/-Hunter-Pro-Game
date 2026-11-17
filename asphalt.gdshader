shader_type spatial;
uniform vec4 asphalt_color : source_color = vec4(0.075,0.085,0.095,1.0);
uniform float grain_scale = 95.0;
void fragment() {
    float n = fract(sin(dot(floor(UV * grain_scale), vec2(12.9898,78.233))) * 43758.5453);
    float grain = 0.88 + n * 0.18;
    ALBEDO = asphalt_color.rgb * grain;
    ROUGHNESS = 0.94;
}
