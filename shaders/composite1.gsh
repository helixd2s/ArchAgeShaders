#version 460 compatibility

layout (location = 0) in vec2 texcoordIn[];

layout (location = 0) out vec2 texcoord;
layout (location = 1) out flat int layerId;

// 
layout (triangles) in;
layout (triangle_strip, max_vertices = 6) out;

void main() {
	for (int l=0;l<2;l++) {
		for (int i=0;i<3;i++) {
			gl_Position = gl_in[i].gl_Position;
			gl_Layer = layerId = l;
			texcoord = texcoordIn[i];
			EmitVertex();
		};
		EndPrimitive();
	};
}
