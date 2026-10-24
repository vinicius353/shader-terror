// So para shaders de FRAGMENTO (usa gl_FragCoord).
#include <horror_common.sh>

// =====================================================
//  AJUSTES DO EFEITO VHS (sempre ligado, dia e noite)
// =====================================================
#define VHS_FPS          24.0   // quantas vezes por segundo o ruido muda
#define VHS_GRAIN        0.055  // grao de luminancia
#define VHS_GRAIN_CELL   2.0    // tamanho do grao em pixels
#define VHS_CHROMA       0.78   // 1 = cor normal, menor = cor mais fraca (YIQ)
#define VHS_CHROMA_NOISE 0.07   // ruido de cor
#define VHS_CHROMA_CELL  5.0    // tamanho dos blocos de ruido de cor (pixels)
#define VHS_Y_LEVELS     40.0   // niveis de brilho (menor = mais posterizado)
#define VHS_IQ_LEVELS    18.0   // niveis de cor
#define VHS_LINE_H       2.0    // altura das linhas de varredura (pixels)
#define VHS_SCAN         0.10   // forca das linhas escuras alternadas
#define VHS_FRINGE       0.6    // franja de cor nas bordas (vermelho/azul)
#define VHS_TINT         0.35   // tom roxo/azul nas sombras
#define VHS_VIGNETTE     0.35   // escurecer dos cantos
#define VHS_TRACKING     0.30   // faixa de chiado que sobe pela tela
// =====================================================

// Materiais que nao tem o uniform de tempo (ex.: Weather) ficam com ruido parado.
#if defined(NO_OCCLUSION__ON) || defined(NO_OCCLUSION__OFF)
#define VHS_NO_TIME
#endif
#ifndef VHS_NO_TIME
uniform vec4 ViewPositionAndTime;
#endif

float vhsHash(vec2 p) {
    vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// col = cor final; viewPos = posicao na camera; t = tempo em segundos;
// noiseAmt = 1 liga ruido animado e faixa de chiado, 0 desliga (ex.: ceu)
vec3 vhsApply(vec3 col, vec3 viewPos, float t, float noiseAmt) {
    vec2 fc = gl_FragCoord.xy;
    float tick = floor(t * VHS_FPS);

    float y0 = dot(col, vec3(0.299, 0.587, 0.114));
    float dY = dFdx(y0);   // gradiente horizontal de brilho (para as franjas)

    // RGB -> YIQ
    float Y = y0;
    float I = dot(col, vec3(0.596, -0.274, -0.322));
    float Q = dot(col, vec3(0.211, -0.523, 0.312));

    // faixa de chiado subindo pela tela (posicao de tela aproximada)
    float sy = clamp(viewPos.y / max(abs(viewPos.z), 0.0001) * 0.7, -1.0, 1.0) * 0.5 + 0.5;
    float band = smoothstep(0.05, 0.0, abs(sy - fract(t * 0.11))) * VHS_TRACKING * step(0.5, noiseAmt);

    // cor de baixa banda: mais fraca e com ruido em blocos
    vec2 cell = floor(fc / VHS_CHROMA_CELL);
    float nI = vhsHash(cell + vec2(tick * 17.0, 3.0)) - 0.5;
    float nQ = vhsHash(cell * 1.7 + vec2(tick * 31.0, 7.0)) - 0.5;
    float cn = VHS_CHROMA_NOISE * noiseAmt * (1.0 + band * 4.0);
    I = I * VHS_CHROMA + nI * cn;
    Q = Q * VHS_CHROMA + nQ * cn;

    // grao de luminancia (nao aparece no preto total)
    float g = vhsHash(floor(fc / VHS_GRAIN_CELL) + vec2(tick * 13.0, 11.0)) - 0.5;
    Y += g * (VHS_GRAIN * noiseAmt * (1.0 + band * 5.0)) * smoothstep(0.0, 0.2, Y + band);

    // posterizacao
    Y = floor(Y * VHS_Y_LEVELS + 0.5) / VHS_Y_LEVELS;
    I = floor(I * VHS_IQ_LEVELS + 0.5) / VHS_IQ_LEVELS;
    Q = floor(Q * VHS_IQ_LEVELS + 0.5) / VHS_IQ_LEVELS;

    // entrelacamento: linhas de um campo ficam mais escuras, e o campo troca a cada quadro
    float line = mod(floor(fc.y / VHS_LINE_H), 2.0);
    float field = mod(tick, 2.0);
    Y *= 1.0 - VHS_SCAN * abs(line - field);

    // YIQ -> RGB
    vec3 o = vec3(Y + 0.956 * I + 0.621 * Q,
                  Y - 0.272 * I - 0.647 * Q,
                  Y - 1.106 * I + 1.703 * Q);

    // franja de cor: vermelho de um lado e azul do outro nas bordas de brilho
    o.r += dY * VHS_FRINGE;
    o.b -= dY * VHS_FRINGE;

    // tom roxo/azul nas sombras
    o = mix(o, o * vec3(0.90, 0.88, 1.10), (1.0 - clamp(Y, 0.0, 1.0)) * VHS_TINT);

    // cantos escuros
    float tanA = length(viewPos.xy) / max(abs(viewPos.z), 0.0001);
    o *= 1.0 - VHS_VIGNETTE * smoothstep(0.55, 1.25, tanA);

    return max(o, vec3_splat(0.0));
}

// Usado por mobs, mao, particulas e clima: lanterna (so noite) + VHS (sempre)
vec3 horrorApply(vec3 col, vec3 fogRgb, vec3 viewPos, vec3 light) {
    float night = horrorNight(fogRgb);
    float beam = horrorBeam(viewPos);
    vec3 albedo = col / max(light, vec3_splat(0.04));
    vec3 dark = col * H_AMBIENT + albedo * vec3(1.0, 0.93, 0.78) * (beam * H_BEAM_POWER);
    float grey = dot(dark, vec3(0.299, 0.587, 0.114));
    dark = mix(vec3_splat(grey), dark, H_SATURATION);
    vec3 result = mix(col, dark, night);
#ifdef VHS_NO_TIME
    return vhsApply(result, viewPos, 0.0, 0.0);
#else
    return vhsApply(result, viewPos, ViewPositionAndTime.w, 1.0);
#endif
}
