#version 460 compatibility

uniform sampler2DArray depthtex0;
uniform sampler2DArray colortex0;
uniform sampler2DArray colortex1;
uniform sampler2DArray colortex2;
uniform sampler2DArray colortex3;
uniform sampler2DArray colortex4;
uniform sampler2DArray colortex5;
uniform sampler2DArray colortex6;
uniform sampler2DArray colortex7;

layout (location = 0) in vec2 vtexcoord;
layout (location = 1) in flat int layerId;

#include "/lib/common.glsl"

/*DRAWBUFFERS:01234567*/

void main() {
    gl_FragDepth = 1.f;
    gl_FragData[0] = sampleLayer(colortex0, vtexcoord, layerId);
    gl_FragData[1] = sampleLayer(colortex1, vtexcoord, layerId);
    gl_FragData[2] = sampleLayer(colortex2, vtexcoord, layerId);
    gl_FragData[3] = sampleLayer(colortex3, vtexcoord, layerId);
    gl_FragData[4] = sampleLayer(colortex4, vtexcoord, layerId);
    gl_FragData[5] = sampleLayer(colortex5, vtexcoord, layerId);
    gl_FragData[6] = sampleLayer(colortex6, vtexcoord, layerId);
    gl_FragData[7] = sampleLayer(colortex7, vtexcoord, layerId);

	if (texture(colortex7, vec3(vtexcoord,0.f)).y <= 0.f) {
        gl_FragData[7] = vec4(0.f, 63.f - 2.f/16.f, 0.f, 1.f);
    } else 
    {
        gl_FragData[7] = texture(colortex7, vec3(vtexcoord,0.f));
    }
}
