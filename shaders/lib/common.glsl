const int DEFAULT_SCENE = 0;
const int REFLECTION_SCENE = 1;
const int TRANSLUCENT_SCENE = 3;
const int WATER_SCENE = 2;

#define USE_SPLIT_SCREEN

#ifndef USE_SPLIT_SCREEN
#define samplerTyped sampler2DArray
#define usamplerTyped usampler2DArray
#else
#define samplerTyped sampler2D
#define usamplerTyped usampler2D
#endif



// 
bool checkArea(in vec2 coord) {
    return coord.x >= 0.f && coord.y >= 0.f && coord.x < 1.f && coord.y < 1.f;
    //return true;
}

// FIXED!
uvec4 sampleLayer(in usampler2DArray smplr, in vec2 texcoord, in int layer) {
    vec3 size = textureSize(smplr, 0);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    return texture(smplr, vec3(texcoord, float(layer)), 0);
}

// FIXED!
uvec4 gatherLayer(in usampler2DArray smplr, in vec2 texcoord, in int layer, const int component) {
    vec3 size = textureSize(smplr, 0);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    if (component == 0) { return textureGather(smplr, vec3(texcoord, float(layer)), 0); };
    if (component == 1) { return textureGather(smplr, vec3(texcoord, float(layer)), 1); };
    if (component == 2) { return textureGather(smplr, vec3(texcoord, float(layer)), 2); };
    if (component == 3) { return textureGather(smplr, vec3(texcoord, float(layer)), 3); };
    return uvec4(0u);
}

// FIXED!
uvec4 fetchLayer(in usampler2DArray smplr, in ivec2 texcoord, in int layer) {
    return texelFetch(smplr, ivec3(texcoord, layer), 0);
}


// FIXED!
vec4 sampleLayer(in sampler2DArray smplr, in vec2 texcoord, in int layer) {
    vec3 size = textureSize(smplr, 0);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    return texture(smplr, vec3(texcoord, float(layer)), 0);
}

// FIXED!
vec4 gatherLayer(in sampler2DArray smplr, in vec2 texcoord, in int layer, const int component) {
    vec3 size = textureSize(smplr, 0);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    if (component == 0) { return textureGather(smplr, vec3(texcoord, float(layer)), 0); };
    if (component == 1) { return textureGather(smplr, vec3(texcoord, float(layer)), 1); };
    if (component == 2) { return textureGather(smplr, vec3(texcoord, float(layer)), 2); };
    if (component == 3) { return textureGather(smplr, vec3(texcoord, float(layer)), 3); };
    return vec4(0.f.xxxx);
}

// FIXED!
vec4 fetchLayer(in sampler2DArray smplr, in ivec2 texcoord, in int layer) {
    return texelFetch(smplr, ivec3(texcoord, layer), 0);
}


// 
#ifndef USE_SPLIT_SCREEN
// 
uvec4 sampleLayer(in usampler2D smplr, in vec2 texcoord, in int layer) {
    vec3 size = vec3(textureSize(smplr, 0), 1.f);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    return texture(smplr, texcoord, 0);
}

// 
uvec4 gatherLayer(in usampler2D smplr, in vec2 texcoord, in int layer, const int component) {
    vec3 size = vec3(textureSize(smplr, 0), 1.f);
    float zcoord = (float(layer) + 0.49999f) / size.z;
    if (component == 0) { return textureGather(smplr, texcoord, 0); };
    if (component == 1) { return textureGather(smplr, texcoord, 1); };
    if (component == 2) { return textureGather(smplr, texcoord, 2); };
    if (component == 3) { return textureGather(smplr, texcoord, 3); };
    return uvec4(0u);
}

// 
uvec4 fetchLayer(in usampler2D smplr, in ivec2 texcoord, in int layer) {
    ivec3 size = ivec3(textureSize(smplr, 0), 1);
    return texelFetch(smplr, texcoord, 0);
}


// 
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

// in format [-1, 1]
vec4 splitArea[4] = {
    vec4(0.f, 0.0f, 0.5f, 0.5f), vec4(0.5f, 0.0f, 1.0f, 0.5f),
    vec4(0.f, 0.5f, 0.5f, 1.0f), vec4(0.5f, 0.5f, 1.0f, 1.0f)
};

vec2 convertArea(in vec2 xy, in int area) {
    xy.xy *= (splitArea[area].zw - splitArea[area].xy);
    xy.xy += splitArea[area].xy;
    return xy;
}

vec4 convertAreaNDC(in vec4 coord, in int area) {
    vec3 xyz = coord.xyz/coord.w;
    xyz.xy = xyz.xy * 0.5f + 0.5f;
    xyz.xy = convertArea(xyz.xy, area);
    xyz.xy = xyz.xy * 2.f - 1.f;
    return vec4(xyz, 1.f)*coord.w;
}



// 
vec4 sampleLayer(in sampler2D smplr, in vec2 texcoord, in int layer) {
    vec3 size = vec3(textureSize(smplr, 0), 1.f);
    vec2 hpx = 0.5f/size.xy;
    return texture(smplr, convertArea(clamp(texcoord, hpx-0.0001f, 1.f-hpx+0.0001f), layer), 0);
}

// 
vec4 gatherLayer(in sampler2D smplr, in vec2 texcoord, in int layer, const int component) {
    vec3 size = vec3(textureSize(smplr, 0), 1.f);
    vec2 hpx = 0.5f/size.xy;
    if (component == 0) { return textureGather(smplr, convertArea(clamp(texcoord, hpx-0.0001f, 1.f-hpx+0.0001f), layer), 0); };
    if (component == 1) { return textureGather(smplr, convertArea(clamp(texcoord, hpx-0.0001f, 1.f-hpx+0.0001f), layer), 1); };
    if (component == 2) { return textureGather(smplr, convertArea(clamp(texcoord, hpx-0.0001f, 1.f-hpx+0.0001f), layer), 2); };
    if (component == 3) { return textureGather(smplr, convertArea(clamp(texcoord, hpx-0.0001f, 1.f-hpx+0.0001f), layer), 3); };
    return vec4(0.f.xxxx);
}

// 
vec4 fetchLayer(in sampler2D smplr, in ivec2 texcoord, in int layer) {
    ivec3 size = ivec3(textureSize(smplr, 0), 1);
    texcoord += ivec2(splitArea[layer].xy * vec2(size.xy));
    return texelFetch(smplr, texcoord, 0);
}
#endif

// 
#if defined(VERTEX_SHADER) || defined(GEOMETRY_SHADER)
void SetLayer(inout vec4 position, inout int toChange, in int layerId_) {
#ifndef USE_SPLIT_SCREEN
    toChange = layerId_;
#else
    toChange = 0;
    position = convertAreaNDC(position, layerId_);
#endif
}
#endif
