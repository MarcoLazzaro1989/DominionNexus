shader_type canvas_item;

/* 0.0–1.0 */
uniform float fill_amount : hint_range(0.0, 1.0) = 0.75;
/* colore dell’anello */
uniform vec4 ring_color    : source_color = vec4(0.4, 1.0, 0.4, 1.0);
/* colore di sfondo (parte vuota) */
uniform vec4 bg_color      : source_color = vec4(0.1, 0.1, 0.1, 1.0);
/* spessore dell’anello (0 = sottile, 0.5 = metà raggio) */
uniform float thickness    : hint_range(0.01, 0.49) = 0.1;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float angle = atan(uv.y, uv.x);
    float r     = length(uv);
    float normA = (angle + PI) / (2.0 * PI);

    // fuori dall’anello
    if (r > 0.5 || r < (0.5 - thickness)) {
        discard;
    }

    // riempe o lascia vuoto
    COLOR = (normA <= fill_amount) ? ring_color : bg_color;
}