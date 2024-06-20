shader_type canvas_item;

uniform float angle : hint_range(0.0, 6.28318);

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;
    uv -= vec2(0.5);
    float s = sin(angle);
    float c = cos(angle);
    mat2 rotation = mat2(vec2(c, s), vec2(-s, c));
    uv = rotation * uv;
    uv += vec2(0.5);
    COLOR = texture(TEXTURE, uv);
}
