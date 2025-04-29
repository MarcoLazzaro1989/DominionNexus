shader_type canvas_item;

uniform float fill_amount = 0.75; // range da 0 a 1
uniform vec4 ring_color : source_color = vec4(0.4, 1.0, 0.4, 1.0);
uniform vec4 bg_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float thickness = 0.1; // spessore dell'anello

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    float normalized_angle = (angle + PI) / (2.0 * PI);

    if (radius > 0.5 || radius < (0.5 - thickness)) {
        discard;
    }

    if (normalized_angle <= fill_amount) {
        COLOR = ring_color;
    } else {
        COLOR = bg_color;
    }
}