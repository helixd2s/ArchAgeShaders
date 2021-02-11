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

// THIS IS WATER SHADER
void main() {

    if (layerId == DEFAULT_SCENE) {

        // 
        vec3 sceneColor = sampleLayer(colortex0, vtexcoord, DEFAULT_SCENE).rgb;
        float sceneDepth = sampleLayer(depthtex0, vtexcoord, DEFAULT_SCENE).x;

        // 
        vec3 transpColor = sampleLayer(colortex0, vtexcoord, TRANSLUCENT_SCENE).rgb;
        float translucentDepth = sampleLayer(depthtex0, vtexcoord, TRANSLUCENT_SCENE).x;

        // 
        vec3 cutoutColor = sampleLayer(colortex0, vtexcoord, CUTOUT_SCENE).rgb;
        float cutoutDepth = sampleLayer(depthtex0, vtexcoord, CUTOUT_SCENE).x;

        // 
        float waterDepth = sampleLayer(depthtex0, vtexcoord, WATER_SCENE).x;
        vec3 waterColor = sampleLayer(colortex0, vtexcoord, WATER_SCENE).rgb;
        float filterRefl = sampleLayer(colortex0, vtexcoord, WATER_SCENE).w;

        // sum with cutout
        if (cutoutDepth.x <= sceneDepth.x && cutoutDepth.x <= 0.9999f) {
            sceneColor = mix(sceneColor, cutoutColor, sampleLayer(colortex0, vtexcoord, CUTOUT_SCENE).w);
            sceneDepth = min(sceneDepth, cutoutDepth);
        }

        // sum with pseudo-translucent
        if (translucentDepth.x <= sceneDepth.x && translucentDepth.x <= 0.9999f) {
            sceneColor = mix(sceneColor, transpColor, sampleLayer(colortex0, vtexcoord, TRANSLUCENT_SCENE).w);
            sceneDepth = min(sceneDepth, translucentDepth);
        }

        // mix with water shader (not works trough transparency, sorry)
        if (waterDepth.x <= sceneDepth.x && waterDepth.x <= 0.9999f) {
            sceneColor = mix(sceneColor, waterColor, filterRefl);
        }

        gl_FragData[0] = vec4(sceneColor, 1.f);
    } else {
        discard;
    }

}
