const int DEFAULT_SCENE = 0;
const int REFLECTION_SCENE = 1;
const int TRANSLUCENT_SCENE = 1;
const int WATER_SCENE = 0;

#define samplerTyped sampler2DArray

// 
vec4 sampleLayer(in sampler2DArray smplr, in vec2 texcoord, in int layer) {
    vec3 size = textureSize(smplr, 0);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    return texture(smplr, vec3(texcoord, zcoord), 0);
}

// 
vec4 gatherLayer(in sampler2DArray smplr, in vec2 texcoord, in int layer, const int component) {
    vec3 size = textureSize(smplr, 0);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    if (component == 0) { return textureGather(smplr, vec3(texcoord, zcoord), 0); };
    if (component == 1) { return textureGather(smplr, vec3(texcoord, zcoord), 1); };
    if (component == 2) { return textureGather(smplr, vec3(texcoord, zcoord), 2); };
    if (component == 3) { return textureGather(smplr, vec3(texcoord, zcoord), 3); };
    return vec4(0.f.xxxx);
}

// 
vec4 fetchLayer(in sampler2DArray smplr, in ivec2 texcoord, in int layer) {
    return texelFetch(smplr, ivec3(texcoord, layer), 0);
}


// 
#ifndef USE_SPLIT_SCREEN
vec4 sampleLayer(in sampler2D smplr, in vec2 texcoord, in int layer) {
    vec3 size = vec3(textureSize(smplr, 0), 1.f);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    return texture(smplr, texcoord, 0);
}

// 
vec4 gatherLayer(in sampler2D smplr, in vec2 texcoord, in int layer, const int component) {
    vec3 size = vec3(textureSize(smplr, 0), 1.f);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    if (component == 0) { return textureGather(smplr, texcoord, 0); };
    if (component == 1) { return textureGather(smplr, texcoord, 1); };
    if (component == 2) { return textureGather(smplr, texcoord, 2); };
    if (component == 3) { return textureGather(smplr, texcoord, 3); };
    return vec4(0.f.xxxx);
}

// 
vec4 fetchLayer(in sampler2D smplr, in ivec2 texcoord, in int layer) {
    ivec3 size = ivec3(textureSize(smplr, 0), 1);
    return texelFetch(smplr, texcoord, 0);
}
#else

#endif