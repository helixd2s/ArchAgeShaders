layout (location = 0) out vec2 texcoord;
layout (location = 1) out flat int layerId;

void main() {
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0.xy;
    layerId = 0;
}
