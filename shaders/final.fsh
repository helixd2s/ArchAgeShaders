#version 460 compatibility

#include "/lib/common.glsl"

uniform samplerTyped colortex0;
uniform samplerTyped colortex1;

layout (location = 0) in vec2 vtexcoord;

void main() {
	vec3 sceneColor = sampleLayer(colortex0, vtexcoord, DEFAULT_SCENE).rgb;
	//vec3 sceneColor = sampleLayer(colortex0, vtexcoord, REFLECTION_SCENE).rgb;
	
	//sceneColor.xyz = pow(sceneColor.xyz, vec3(1.0f/2.2f));
	gl_FragColor = vec4(sceneColor, 1.0);
}
