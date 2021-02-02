#version 460 compatibility

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

uniform vec3 skyColor;

void main() {
    gl_FragDepth = 1.f;
    gl_FragData[0] = vec4(skyColor, 1.f);
    gl_FragData[1] = vec4(0.f.xxxx);
    gl_FragData[2] = vec4(0.f.xxxx);
    gl_FragData[3] = vec4(0.f.xxxx);
    gl_FragData[4] = vec4(0.f.xxxx);
    gl_FragData[5] = vec4(0.f.xxxx);
    gl_FragData[6] = vec4(0.f.xxxx);

	if (sampleLayer(colortex7, vtexcoord, layerId).y <= 0.f) {
        gl_FragData[7] = vec4(0.f, 63.f - 2.f/16.f, 0.f, 1.f);
    } else 
    {
        gl_FragData[7] = sampleLayer(colortex7, vtexcoord, layerId);
    }
}
