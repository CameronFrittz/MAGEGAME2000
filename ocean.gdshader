shader_type canvas_item;
#define pi 3.14159
#define dir(a) vec2(cos(a),sin(a))
#define normal(v) vec2(-v.y, v.x)
#define iTime TIME
uniform float zoom : hint_range(0.0, 5.0, 0.1) = 1.0;
uniform float size : hint_range(0.0, 5.0, 0.1) = 0.4;
uniform float speed1 : hint_range(0.0, 5.0, 0.1) = 1.;
uniform float speed2 : hint_range(0.0, 5.0, 0.1) = 1.;
uniform float blend_factor : hint_range(0.0, 1.0, 0.1) = 0.5;

void fragment()
{
    vec2 u = UV * zoom; 
    
    // Space between parallel lines
    float k = size;
    
    // Line coefficients: L1 = a1 + t * b1, 
    //                    L2 = a2 + s * b2
    // (b1, b2 are unit vectors)
    vec2 a1 = vec2(0), b1 = dir(.6*cos(iTime * speed1)), 
         a2 = vec2(0), b2 = dir(.1 * iTime * speed2);

    vec2 n1 = normal(b1),
         n2 = normal(b2);

    float d1 = dot(n1, u - a1),
          d2 = dot(n2, u - a2);

    a1 += (floor(d1 / k)+.5) * k * n1;
    a2 += (floor(d2 / k)+.5) * k * n2;
    vec2 centre = a1 + dot(a2-a1,n2) / dot(b1,n2) * b1;
    
    float d = length(u - centre);
    vec4 shader_color = vec4(cos(160.*d) * exp(-8.*d*d));
    vec4 original_color = texture(TEXTURE, UV);
    
    COLOR = mix(original_color, shader_color, blend_factor);
}
