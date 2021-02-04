layout (location = 0) in vec2 texcoordIn[];

layout (location = 0) out vec2 texcoord;
layout (location = 1) out flat int layerId;

// 
layout (triangles) in;
layout (triangle_strip, max_vertices = 24) out;

#include "../lib/common.glsl"

uniform samplerTyped colortex0;

void main() {
#ifndef USE_SPLIT_SCREEN
	int layerCount = int(textureSize(colortex0,0).z);
#else
	int layerCount = 4;
#endif
	for (int l=0;l<layerCount;l++) {
		for (int i=0;i<3;i++) {
			gl_Position = gl_in[i].gl_Position;
			layerId = l;
			texcoord = texcoordIn[i];

			SetLayer(gl_Position, gl_Layer, l);
			EmitVertex();
		};
		EndPrimitive();
	};
}
