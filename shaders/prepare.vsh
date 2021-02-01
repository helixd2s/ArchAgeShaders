#version 460 compatibility

layout (location = 0) out vec2 texcoord;
layout (location = 1) out flat int layerId;

void main() {
	gl_Position = ftransform();
	
	layerId = 0;
	texcoord = gl_MultiTexCoord0.xy;
}
