$input v_color0, v_texcoord0

#include <bgfx_shader.sh>
#define VHS_NO_TIME
#include <horror.sh>

void main() {
    float night = v_texcoord0.x;
    // ceu a noite: sem roxo, cinza frio e muito escuro
    float g = dot(v_color0.xyz, vec3(0.299, 0.587, 0.114));
    vec3 coldGrey = vec3_splat(g) * vec3(0.92, 1.0, 1.06);
    vec3 sky = mix(v_color0.xyz, coldGrey, night * 0.9);
    float darken = mix(1.0, H_SKY_DARKEN, night);
    // ceu: VHS sem ruido animado (este material nao tem relogio)
    vec3 c = vhsApply(sky * darken, vec3_splat(0.0), 0.0, 0.0);
    gl_FragColor = vec4(c, v_color0.w);
}
