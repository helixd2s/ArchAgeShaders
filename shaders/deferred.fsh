#version 460 compatibility
#extension GL_NV_gpu_shader5 : enable

#include "/lib/common.glsl"

uniform samplerTyped depthtex0;
uniform samplerTyped colortex0;
uniform samplerTyped colortex1;
uniform samplerTyped colortex2;
uniform samplerTyped colortex3;
uniform samplerTyped colortex4;
uniform samplerTyped colortex5;
uniform samplerTyped colortex6;
uniform samplerTyped colortex7;

layout (location = 0) in vec2 vtexcoord;
layout (location = 1) in flat int layerId;

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

// FLIP PROBLEM RESOLVE
// REQUIRED HACK PROGRAM

void main() {
    //discard;
    gl_FragData[0] = fetchLayer(colortex0, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[1] = fetchLayer(colortex1, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[2] = fetchLayer(colortex2, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[3] = fetchLayer(colortex3, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[4] = fetchLayer(colortex4, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[5] = fetchLayer(colortex5, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[6] = fetchLayer(colortex6, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[7] = fetchLayer(colortex7, ivec2(gl_FragCoord.xy), layerId);

    // use linear colors
    gl_FragData[0].rgb = pow(gl_FragData[0].rgb, 2.2f.xxx);
}
