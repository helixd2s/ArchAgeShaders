#version 460 compatibility

uniform sampler2D colortex0;

layout (location = 0) in vec2 vtexcoord;

void main() {
	vec2 texcoord = vtexcoord;

	vec3 sceneColor 	= texture(colortex0, texcoord, 0).rgb;

	gl_FragColor		= vec4(sceneColor, 1.0);
}
