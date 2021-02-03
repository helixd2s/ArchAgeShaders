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

bvec3 and(in bvec3 a, in bvec3 b) {
    return bvec3(a.x&&b.x, a.y&&b.y, a.z&&b.z);
}

// THIS IS WATER SHADER
void main() {

    if (layerId == DEFAULT_SCENE) {
        // 
        float groundDepth = sampleLayer(depthtex0, vtexcoord, DEFAULT_SCENE).x;
        float sceneDepth = sampleLayer(depthtex0, vtexcoord, WATER_SCENE).x;
        float translucentDepth = sampleLayer(depthtex0, vtexcoord, TRANSLUCENT_SCENE).x;
        vec3 screenpos 	= getScreenpos(sceneDepth.x, vtexcoord);

        // 
        vec3 normal     = sampleNormal(vtexcoord, WATER_SCENE);
        vec3 tangent    = sampleTangent(vtexcoord, WATER_SCENE);
        vec3 bitangent  = normalize(cross(tangent, normal));
        float reflcoef  = 1.f - abs(dot(normalize(screenpos), normal));
        
        // 
        vec3 sceneColor = sampleLayer(colortex0, vtexcoord, DEFAULT_SCENE).rgb;
        vec3 waterColor = sampleLayer(colortex0, vtexcoord, WATER_SCENE).rgb;
        vec3 transpColor = sampleLayer(colortex0, vtexcoord, TRANSLUCENT_SCENE).rgb;
        float filterRefl = sampleLayer(colortex0, vtexcoord, WATER_SCENE).w;

        // 
        if (groundDepth.x >= translucentDepth.x && sceneDepth.x < translucentDepth.x) {
            sceneColor = mix(sceneColor, transpColor, sampleLayer(colortex0, vtexcoord, TRANSLUCENT_SCENE).w);
        }

        // mix with ground 
        if (groundDepth.x >= sceneDepth.x) {
            sceneColor = mix(sceneColor, waterColor, filterRefl);
        }

        //
        if (groundDepth.x >= translucentDepth.x && sceneDepth.x >= translucentDepth.x) {
            sceneColor = mix(sceneColor, transpColor, sampleLayer(colortex0, vtexcoord, TRANSLUCENT_SCENE).w);
        }

        //sceneColor = sampleLayer(colortex7, vtexcoord, WATER_SCENE).xyz * 0.01f;

        gl_FragData[0] = vec4(sceneColor, 1.f);
    } else {
        discard;
    }

    
}
