#version 460 compatibility
#extension GL_NV_gpu_shader5 : enable

#include "/lib/common.glsl"
#include "/lib/convert.glsl"
#include "/lib/buffers.glsl"

layout (location = 0) in vec2 vtexcoord;
layout (location = 1) in flat int layerId;

/*DRAWBUFFERS:0127*/



// FLIP PROBLEM RESOLVE
// REQUIRED HACK PROGRAM

void main() {
    //discard;
    gl_FragData[0] = fetchLayer(colortex0, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[1] = fetchLayer(colortex1, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[2] = fetchLayer(colortex2, ivec2(gl_FragCoord.xy), layerId);
    gl_FragData[3] = fetchLayer(colortex7, ivec2(gl_FragCoord.xy), layerId);
}
