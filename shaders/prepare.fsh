#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/convert.glsl"
#include "/lib/buffers.glsl"

layout (location = 0) in vec2 vtexcoord;
layout (location = 1) in flat int layerId;

/*DRAWBUFFERS:0127*/

uniform vec3 skyColor;

void main() {
    gl_FragDepth = 1.f;
    gl_FragData[1] = vec4(0.f.xxxx);
    gl_FragData[2] = vec4(0.f.xxxx);

    // 
    if (layerId == TRANSLUCENT_SCENE) { gl_FragData[0] = vec4(0.f.xxx, 0.f); };
    if (layerId == WATER_SCENE) { gl_FragData[0] = vec4(0.f.xxx, 0.f); };
    if (layerId == DEFAULT_SCENE) { gl_FragData[0] = vec4(skyColor, 1.f); };
    if (layerId == REFLECTION_SCENE) { gl_FragData[0] = vec4(skyColor, 1.f); };

    // 
    vec4 planeLevel = sampleLayer(colortex7, vtexcoord, layerId);
	if (planeLevel.y <= 0.f) {
        gl_FragData[3] = vec4(0.f, 63.f - 2.f/16.f, 0.f, 1.f);
    } else 
    {
        gl_FragData[3] = planeLevel;
    }
}
