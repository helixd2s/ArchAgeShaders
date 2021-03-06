#version 460 compatibility
#extension GL_NV_gpu_shader5 : enable

layout (location = 0) in vec2 vtexcoord;
layout (location = 1) in flat int layerId;

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
#include "/lib/convert.glsl"
#include "/lib/buffers.glsl"
#include "/lib/math.glsl"
#include "/lib/transforms.glsl"
#include "/lib/shadowmap.glsl"
#include "/lib/sslr.glsl"
#include "/lib/water.glsl"

/*DRAWBUFFERS:0*/

uniform sampler2D colortex8; // lightmap

// NEEDS VOXEL RAY TRACING!!!
vec4 makeScreenSpaceEffect(in vec3 screenpos, in vec3 direction, inout vec4 sslrpos, inout bool usedplanar) {
    // nested SSLR from main scene (fallback)
    sslrpos = EfficientRM(screenpos.xyz, direction.xyz, CUTOUT_SCENE, false);
    vec3 reflColor = sampleLayer(colortex0, sslrpos.xy*0.5f+0.5f, CUTOUT_SCENE).rgb; float hasResult = 1.f;
    if (sampleLayer(colortex0, sslrpos.xy*0.5f+0.5f, CUTOUT_SCENE).w < 0.0001f || dot(reflColor, 1.f.xxx) < 0.0001f || sslrpos.w <= 0.0001f) {
    //    sslrpos = EfficientRM(screenpos.xyz, direction.xyz, REFLECTION_SCENE, false);
    //    reflColor = sampleLayer(colortex0, sslrpos.xy*0.5f+0.5f, REFLECTION_SCENE).rgb;
    //    usedplanar = true;
    //    if (sampleLayer(colortex0, sslrpos.xy*0.5f+0.5f, REFLECTION_SCENE).w < 0.0001f || dot(reflColor, 1.f.xxx) < 0.0001f || sslrpos.w <= 0.0001f) { 
            //reflColor = skyColor;
            hasResult = 0.f;
    //    }
    }
    return vec4(reflColor, hasResult);
}

// THIS IS WATER SHADER
void main() {

    if (layerId == WATER_SCENE) {
        //ivec2  texcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight));
        //ivec2 rtexcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight));

        // 
        vec3 groundDepth = sampleLayer(depthtex0, vtexcoord, DEFAULT_SCENE).xxx;
        vec3 sceneDepth = sampleLayer(depthtex0, vtexcoord, WATER_SCENE).xxx;
        vec3 screenpos 	= getScreenpos(sceneDepth.x, vtexcoord);
        vec3 worldpos   = toWorldpos(screenpos);

        // 
        vec3 normal     = sampleNormal(vtexcoord, WATER_SCENE);
        vec3 tangent    = sampleTangent(vtexcoord, WATER_SCENE);
        vec2 lmcoord    = sampleLmcoord(vtexcoord, WATER_SCENE);
        vec3 bitangent  = normalize(cross(tangent, normal));

        // 
        vec3 world_bitangent = mat3(gbufferModelViewInverse) * bitangent;
        vec3 world_tangent = mat3(gbufferModelViewInverse) * tangent;
        vec3 world_normal = mat3(gbufferModelViewInverse) * normal;
        float reflcoef  = 1.f - abs(dot(normalize(screenpos), normal));

        // 
        vec3 sceneColor = vec3(0.f.xxx);//sampleLayer(colortex0, vtexcoord, DEFAULT_SCENE).rgb;
        vec3 waterColor = sampleLayer(colortex0, vtexcoord, WATER_SCENE).rgb;
        float filterRefl = sampleLayer(colortex0, vtexcoord, WATER_SCENE).w > 0.f ? 1.f : 0.f;
        if ( sceneDepth.x > 0.9999f ) { filterRefl = 0.f; };

        // 
        if (filterRefl > 0.999f) {
            vec3 ntexture = normalize(mix(get_water_normal(worldpos, 1.f, world_normal, world_tangent, world_bitangent).xzy, vec3(0.f,0.f,1.f), 0.96f));
            normal = mat3(tangent, bitangent, normal) * ntexture;
        }

        // make reflection as water color
        if (filterRefl > 0.999f) {
            bool usedplanar = false;
            vec4 sslrpos = vec4(0.f.xxxx);
            vec4 effect = makeScreenSpaceEffect(screenpos, normalize(reflect(normalize(screenpos.xyz), normal)), sslrpos, usedplanar);
            sceneColor = mix(pow(texture(colortex8, vec2(0.f,lmcoord.y), 0).xyz, 2.2f.xxx)*pow(skyColor, 2.2f.xxx), effect.xyz, effect.w);
            // for skyColor required lightmap
        }

        gl_FragData[0] = vec4(sceneColor, filterRefl > 0.999f ? (0.2f + reflcoef*0.4f) : 0.f);
    } else {
        gl_FragData[0] = sampleLayer(colortex0, vtexcoord, layerId);

        //discard;
    }


}
