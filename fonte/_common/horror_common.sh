// =====================================================
//  AJUSTES DA LANTERNA / TERROR (so noite)
// =====================================================
#define H_AMBIENT_DEFAULT 0.10   // luz geral fora da lanterna (0 = breu, 0.3 = penumbra)
#define H_BEAM_POWER      1.70   // forca da lanterna
#define H_BEAM_RANGE      26.0   // alcance da lanterna em blocos
#define H_CONE_INNER      0.16   // largura do centro do cone
#define H_CONE_OUTER      0.52   // borda suave do cone
#define H_SATURATION      0.55   // 1 = cores normais, 0 = preto e branco
#define H_FOG_DARK        vec3(0.008, 0.010, 0.014)   // cor da neblina escura
#define H_SKY_DARKEN      0.03   // quanto do ceu original aparece de noite
// Dia/noite: brilho da cor da neblina do jogo.
// Acima de H_DAY_LUM = dia normal (sem lanterna). Abaixo de H_NIGHT_LUM = noite total.
#define H_DAY_LUM         0.30
#define H_NIGHT_LUM       0.08
// =====================================================

#ifdef H_AMBIENT_OVERRIDE
#define H_AMBIENT H_AMBIENT_OVERRIDE
#else
#define H_AMBIENT H_AMBIENT_DEFAULT
#endif

// 0 = dia (sem efeito), 1 = noite (efeito total)
float horrorNight(vec3 fogRgb) {
    float lum = dot(fogRgb, vec3(0.299, 0.587, 0.114));
    return 1.0 - smoothstep(H_NIGHT_LUM, H_DAY_LUM, lum);
}

// 0..1: quanto a lanterna ilumina este ponto (viewPos = posicao no espaco da camera)
float horrorBeam(vec3 viewPos) {
    float dist = length(viewPos);
    float depthAlong = max(abs(viewPos.z), 0.0001);
    float tanAngle = length(viewPos.xy) / depthAlong;
    float cone = 1.0 - smoothstep(H_CONE_INNER, H_CONE_OUTER, tanAngle);
    float reach = clamp(1.0 - dist / H_BEAM_RANGE, 0.0, 1.0);
    return cone * reach * reach;
}
