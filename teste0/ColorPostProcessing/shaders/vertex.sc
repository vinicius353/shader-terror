$input a_position, a_texcoord0
$output v_texcoord0

#include <bgfx_shader.sh>

uniform vec4 ViewportScale;

void main() {
    vec2 s = a_texcoord0 * ViewportScale.xy;
    v_texcoord0 = vec4(s.x, s.y, a_texcoord0.x, a_texcoord0.y);
    gl_Position = vec4((a_position.xy * 2.0) - vec2_splat(1.0), 0.0, 1.0);
}
