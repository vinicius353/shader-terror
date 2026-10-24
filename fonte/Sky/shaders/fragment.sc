$input v_color0, v_texcoord0

#include <bgfx_shader.sh>
#define VHS_NO_TIME
#include <horror.sh>

void main() {
    float darken = mix(1.0, H_SKY_DARKEN, v_texcoord0.x);
    // ceu: VHS sem ruido animado (este material nao tem relogio)
    vec3 c = vhsApply(v_color0.xyz * darken, vec3_splat(0.0), 0.0, 0.0);
    gl_FragColor = vec4(c, v_color0.w);
}
