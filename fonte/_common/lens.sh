// Olho de peixe (so shaders de VERTICE). Deforma a posicao final na tela.
// LENS_STRENGTH: 0 = desligado, 0.10 = leve, 0.20 = forte, 0.30 = muito forte
#define LENS_STRENGTH 0.16

vec4 lensWarp(vec4 c) {
    if (LENS_STRENGTH <= 0.0 || c.w <= 0.0001) {
        return c;
    }
    float asp = u_proj[1][1] / u_proj[0][0];          // largura / altura da tela
    vec2 p = (c.xy / c.w) * vec2(asp, 1.0);
    float r2 = min(dot(p, p) / (asp * asp + 1.0), 1.6); // 0 = centro, 1 = canto
    float s = (1.0 - LENS_STRENGTH * r2) / (1.0 - LENS_STRENGTH);
    c.xy *= s;
    return c;
}
