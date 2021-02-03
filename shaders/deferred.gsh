#version 460 compatibility
layout (location = 0) in vec2 texcoordIn[];

layout (location = 0) out vec2 texcoord;
layout (location = 1) out flat int layerId;

// 
layout (triangles) in;
layout (triangle_strip, max_vertices = 24) out;

#include "../lib/common.glsl"

uniform samplerTyped colortex0;

void main() {
	int layerCount = int(textureSize(colortex0,0).z);
	for (int l=0;l<0;l++) {
		for (int i=0;i<3;i++) {
			gl_Position = gl_in[i].gl_Position;
			gl_Layer = l;
			layerId = l;
			texcoord = texcoordIn[i];
			EmitVertex();
		};
		EndPrimitive();
	};
}
