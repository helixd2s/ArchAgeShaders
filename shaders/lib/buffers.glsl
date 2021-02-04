/*
    const int colortex0Format = RGBA16F;
    const int colortex1Format = RGBA32F;
    const int colortex2Format = RGBA32F;
    const int colortex7Format = RGBA32F;

    const bool colortex7Clear = false;
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

mat2x3 sampleUnpack(in samplerTyped samplr, in vec2 texcoord, in int sceneId) {
#ifndef USE_SPLIT_SCREEN
    ivec2 tcoord = ivec2(floor(texcoord * vec2(viewWidth, viewHeight)));
    vec3 pckg = fetchLayer(samplr, tcoord, sceneId).xyz;
#else
    ivec2 tcoord = ivec2(floor(convertArea(texcoord, sceneId) * vec2(viewWidth, viewHeight)));
    vec3 pckg = texelFetch(samplr, tcoord, 0).xyz;
#endif
    return unpack2x3(pckg);
}

vec3 sampleNormal(in vec2 texcoord, in int sceneId) {
    return normalize(sampleUnpack(colortex1, texcoord, sceneId)[0] * 2.f - 1.f);
}

vec3 sampleTangent(in vec2 texcoord, in int sceneId) {
    return normalize(sampleUnpack(colortex1, texcoord, sceneId)[1] * 2.f - 1.f);
}
