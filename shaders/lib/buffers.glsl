/*
    const int colortex0Format = RGBA16F;
    const int colortex1Format = RGBA32F;
    const int colortex2Format = RGBA32F;
    const int colortex7Format = RGBA32F;

    const bool colortex7Clear = false;

    const int colortex8Format = RGBA8;
    const int colortex9Format = RGBA8;
    const int colortexAFormat = RGBA8;
    const int colortexBFormat = RGBA8;
*/

uniform float viewWidth;
uniform float viewHeight;

uniform samplerTyped depthtex0;
uniform samplerTyped colortex0;
uniform samplerTyped colortex1;
uniform samplerTyped colortex2;
uniform samplerTyped colortex3;
uniform samplerTyped colortex4;
uniform samplerTyped colortex5;
uniform samplerTyped colortex6;
uniform samplerTyped colortex7;

// lightmap
//uniform samplerTyped colortex8;

vec3 sampleRaw(in samplerTyped samplr, in vec2 texcoord, in int sceneId) {
    #ifndef USE_SPLIT_SCREEN
    ivec2 tcoord = ivec2(floor(texcoord * vec2(viewWidth, viewHeight)));
    return fetchLayer(samplr, tcoord, sceneId).xyz;
#else
    vec3 size = vec3(textureSize(samplr, 0), 1.f);
    vec2 mps = (splitArea[sceneId].zw - splitArea[sceneId].xy);
    vec2 hpx = 0.5f/(size.xy*mps);
    vec2 hpm = 0.5f/(size.xy);

    // de-centralize texcoords
    texcoord = clamp(texcoord, hpx-0.0001f, 1.f-hpx+0.0001f);
    texcoord = convertArea(texcoord-hpx, sceneId)+hpm;

    ivec2 tcoord = ivec2(floor(texcoord * vec2(viewWidth, viewHeight)));
    return texelFetch(samplr, tcoord, 0).xyz;
#endif
}

vec3 sampleNormal(in vec2 texcoord, in int sceneId) {
    return normalize(unpack2x3(sampleRaw(colortex1, texcoord, sceneId))[0] * 2.f - 1.f);
}

vec3 sampleTangent(in vec2 texcoord, in int sceneId) {
    return normalize(unpack2x3(sampleRaw(colortex1, texcoord, sceneId))[1] * 2.f - 1.f);
}

vec2 sampleTexcoord(in vec2 texcoord, in int sceneId) {
    return unpack3x2(sampleRaw(colortex2, texcoord, sceneId))[0];
}

vec2 sampleLmcoord(in vec2 texcoord, in int sceneId) {
    return unpack3x2(sampleRaw(colortex2, texcoord, sceneId))[1];
}

vec2 sampleIndicator(in vec2 texcoord, in int sceneId) {
    return unpack3x2(sampleRaw(colortex2, texcoord, sceneId))[2];
}
