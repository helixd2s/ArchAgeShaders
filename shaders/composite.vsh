#version 460 compatibility

layout (location = 0) out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0.xy;
}
