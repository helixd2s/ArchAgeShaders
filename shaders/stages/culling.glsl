//these are our inputs from the vertex shader
layout (location = 0) in vec4 color[3];
layout (location = 1) in vec4 texcoord[3];
layout (location = 2) in vec4 lmcoord[3];
layout (location = 3) in vec3 normal[3];
layout (location = 4) in vec4 tangent[3];
layout (location = 5) in vec4 planar[3];
layout (location = 6) flat in vec4 entity[3];

// 
layout (location = 0) out vec4 out_color;
layout (location = 1) out vec4 out_texcoord;
layout (location = 2) out vec4 out_lmcoord;
layout (location = 3) out vec3 out_normal;
layout (location = 4) out vec4 out_tangent;
layout (location = 5) out vec4 out_planar;
layout (location = 6) flat out vec4 out_entity;

// 
layout (triangles) in;
layout (triangle_strip, max_vertices = 3) out;

// 
uniform int instanceId;

// 
void main() {
    int layerId = 0;
    if (instanceId == 1) { layerId = 1; };

    for (int i = 0; i < 3; i++) {
        out_color = color[i];
        out_texcoord = texcoord[i];
        out_lmcoord = lmcoord[i];
        out_normal = normal[i];
        out_entity = entity[i];
        out_tangent = tangent[i];
        out_planar = planar[i];

        gl_Position = gl_in[i].gl_Position; 
        gl_Layer = layerId;
        EmitVertex();
    }
    
    EndPrimitive();
}
