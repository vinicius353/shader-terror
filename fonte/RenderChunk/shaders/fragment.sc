#if defined(DEPTH_ONLY_OPAQUE_PASS)
#elif defined(DEPTH_ONLY_ALPHA_TEST_PASS)
$input v_texcoord0
#else
$input v_color0, v_fog, v_lightmapUV, v_texcoord0, v_ditheringAndMaskTinting, v_viewPos
#endif

#include <bgfx_shader.sh>

#include <horror.sh>

#if defined(DEPTH_ONLY_OPAQUE_PASS)

void main() {
    gl_FragColor = vec4_splat(0.0);
}

#elif defined(DEPTH_ONLY_ALPHA_TEST_PASS)

SAMPLER2D(s_MatTexture, s_MatTexture_REG);

void main() {
    vec4 d = texture2D(s_MatTexture, v_texcoord0);
    if (d.w < 0.5) {
        discard;
    }
    gl_FragColor = vec4_splat(0.0);
}

#else

SAMPLER2D(s_MatTexture, s_MatTexture_REG);
SAMPLER2D(s_LightMapTexture, s_LightMapTexture_REG);
#ifdef SEASONS__ON
SAMPLER2D(s_SeasonsTexture, s_SeasonsTexture_REG);
#endif

void main() {
    vec4 diffuse = texture2D(s_MatTexture, v_texcoord0);

#if defined(ALPHA_TEST_PASS)
    if (diffuse.w < 0.5) {
        discard;
    }
#endif

#ifdef SEASONS__ON
    vec3 seasonTint = mix(vec3_splat(1.0), texture2D(s_SeasonsTexture, v_color0.xy).xyz * 2.0, v_color0.z);
    diffuse = vec4(diffuse.xyz * seasonTint * v_color0.w, 1.0);
#else
#if defined(ALPHA_TEST_PASS)
    diffuse.xyz *= v_color0.xyz;
#else
    if (v_ditheringAndMaskTinting.y > 0.5) {
        diffuse.xyz = mix(diffuse.xyz, diffuse.xyz * v_color0.xyz, diffuse.w) * v_color0.w;
        diffuse.w = 1.0;
    } else {
        diffuse.xyz *= v_color0.xyz;
#if defined(OPAQUE_PASS)
        diffuse.w = v_color0.w;
#else
        diffuse.w *= v_color0.w;
#endif
    }
#endif
#endif

    // ---- visual original do jogo (usado de dia) ----
    vec3 lightmap = texture2D(s_LightMapTexture, v_lightmapUV).xyz;
    vec3 vanillaCol = mix(lightmap * diffuse.xyz, v_fog.xyz, v_fog.w);

    // ---- visual de terror: lanterna + escuridao ----
    float beam = horrorBeam(v_viewPos);
    float t = ViewPositionAndTime.w;
    float flicker = 1.0 - 0.06 * sin(t * 29.0) * sin(t * 7.3);
    vec3 light = lightmap * H_AMBIENT + vec3(1.0, 0.93, 0.78) * (beam * H_BEAM_POWER * flicker);
    vec3 lit = diffuse.xyz * light;
    float grey = dot(lit, vec3(0.299, 0.587, 0.114));
    lit = mix(vec3_splat(grey), lit, H_SATURATION);
    vec3 horrorCol = mix(lit, H_FOG_DARK, v_fog.w);

    // dia = jogo normal, noite = terror
    float night = horrorNight(v_fog.xyz);
    vec3 finalCol = mix(vanillaCol, horrorCol, night);
    gl_FragColor = vec4(vhsApply(finalCol, v_viewPos, ViewPositionAndTime.w, 1.0), diffuse.w);
}

#endif
