#version 460 compatibility

layout (location = 0) out vec2 texcoord;
layout (location = 1) out vec3 lightVec;
layout (location = 2) out vec3 sunlightColor;
layout (location = 3) out vec3 skylightColor;
layout (location = 4) out vec3 torchlightColor;

uniform vec3 shadowLightPosition;

void main() {
	gl_Position = ftransform();

	// These can be made dynamic with variables to determine the current time of day
	sunlightColor = vec3(1.0, 1.0, 1.0);
	skylightColor = vec3(0.1, 0.1, 0.1);
	torchlightColor = vec3(1.0, 0.3, 0.0);
	
	texcoord 	= gl_MultiTexCoord0.xy;
	lightVec	= normalize(shadowLightPosition);
}
