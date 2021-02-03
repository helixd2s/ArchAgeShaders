#version 460 compatibility
#extension GL_NV_gpu_shader5 : enable



layout (location = 0) in vec2 vtexcoord;
layout (location = 1) in flat int layerId;

uniform float viewWidth;
uniform float viewHeight;

uniform vec3 cameraPosition;
uniform vec3 skyColor;

//uniforms (projection matrices)
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;

#include "/lib/common.glsl"

uniform samplerTyped depthtex0;
//uniform samplerTyped depthtex1;
uniform samplerTyped colortex0;
uniform samplerTyped colortex1;
uniform samplerTyped colortex2;
uniform samplerTyped colortex4;
uniform samplerTyped colortex7;
uniform samplerTyped colortex3;


#include "/lib/math.glsl"
#include "/lib/transforms.glsl"
#include "/lib/shadowmap.glsl"
#include "/lib/sslr.glsl"
#include "/lib/water.glsl"

/*DRAWBUFFERS:01234567*/

/*
    const int colortex0Format = RGBA32F;
    const int colortex1Format = RGBA32F;
    const int colortex2Format = RGBA32F;
    const int colortex3Format = RGBA32F;
    const int colortex4Format = RGBA32F;
    const int colortex5Format = RGBA32F;
    const int colortex6Format = RGBA32F;
    const int colortex7Format = RGBA32F;
    const int colortex8Format = RGBA32F;

    const vec4 colortex0ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex1ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex2ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex3ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex4ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex5ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex6ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex7ClearColor = vec4(0.f,0.f,0.f,0.f);

    const bool colortex7Clear = false;
*/

bvec3 and(in bvec3 a, in bvec3 b) {
    return bvec3(a.x&&b.x, a.y&&b.y, a.z&&b.z);
}

// THIS IS WATER SHADER
void main() {
    if (layerId == DEFAULT_SCENE) {
        ivec2  texcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight));
        ivec2 rtexcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight));

        vec3 groundDepth = fetchLayer(depthtex0, texcoord, DEFAULT_SCENE).xxx;
        vec3 sceneDepth = fetchLayer(depthtex0, texcoord, WATER_SCENE).xxx;
        vec3 screenpos 	= getScreenpos(sceneDepth.x, vtexcoord);
        vec3 worldpos   = toWorldpos(screenpos);

        vec3 normal     = normalize(fetchLayer(colortex1, texcoord, WATER_SCENE).rgb * 2.f - 1.f);
        vec3 tangent    = normalize(fetchLayer(colortex4, texcoord, WATER_SCENE).rgb * 2.f - 1.f);
        vec3 bitangent  = normalize(cross(tangent, normal));

        vec3 world_bitangent = mat3(gbufferModelViewInverse) * bitangent;
        vec3 world_tangent = mat3(gbufferModelViewInverse) * tangent;
        vec3 world_normal = mat3(gbufferModelViewInverse) * normal;

        float reflcoef  = 1.f - abs(dot(normalize(screenpos), normal));

        vec3 sceneColor = fetchLayer(colortex0, texcoord, DEFAULT_SCENE).rgb;
        vec3 lightmapColor = fetchLayer(colortex2, texcoord, WATER_SCENE).rgb;

        vec3 waterColor = fetchLayer(colortex0, texcoord, WATER_SCENE).rgb;
        float filterRefl = fetchLayer(colortex3, texcoord, WATER_SCENE).r;
        
        if (filterRefl > 0.999f) {
            vec3 ntexture = normalize(mix(get_water_normal(worldpos, 1.f, world_normal, world_tangent, world_bitangent).xzy, vec3(0.f,0.f,1.f), 0.96f));
            normal = mat3(tangent, bitangent, normal) * ntexture;
        }

        /* // need another method
        if (filterRefl > 0.999f) {
            vec4 sslrpos = EfficientSSR(screenpos.xyz, normalize(refract(normalize(screenpos.xyz), normal, 1.f/1.333f)), DEFAULT_SCENE, false);
            if (sslrpos.w > 0.f) {
                sceneColor = fetchLayer(colortex0, ivec2((sslrpos.xy * 0.5f + 0.5f) * vec2(viewWidth, viewHeight)), DEFAULT_SCENE).rgb;
            }
        }
        */

        
        if (filterRefl > 0.999f && groundDepth.x > sceneDepth.x) {
            vec4 sslrpos = EfficientSSR(screenpos.xyz, normalize(reflect(normalize(screenpos.xyz), normal)), REFLECTION_SCENE, false);
            rtexcoord = ivec2((sslrpos.xy * 0.5f + 0.5f) * vec2(viewWidth, viewHeight));
            vec3 reflColor = fetchLayer(colortex0, rtexcoord.xy, REFLECTION_SCENE).rgb;
            if (fetchLayer(colortex0, rtexcoord.xy, REFLECTION_SCENE).w < 0.0001f || dot(reflColor, 1.f.xxx) < 0.0001f || sslrpos.w <= 0.0001f) { reflColor = skyColor*lightmapColor; };

            // mix with ground 
            sceneColor = mix(sceneColor, reflColor, filterRefl > 0.999f ? (0.2f + reflcoef*vec3(0.4f.xxx)) : vec3(0.f.xxx));
        }

        

        gl_FragData[0] = vec4(sceneColor, 1.f);
        
        //gl_FragData[0] = vec4(fetchLayer(colortex0, texcoord, REFLECTION_SCENE).rgb, 1.f);
    }

    gl_FragData[7] = sampleLayer(colortex7, vtexcoord, layerId);
}
