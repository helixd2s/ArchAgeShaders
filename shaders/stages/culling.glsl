//these are our inputs from the vertex shader
layout (location = 0) flat in vec4 entity[3];
layout (location = 1) in vec4 color[3];
layout (location = 2) in vec4 texcoord[3];
layout (location = 3) in vec4 lmcoord[3];
layout (location = 4) in vec3 normal[3];
layout (location = 5) in vec4 tangent[3];

// 
layout (location = 0) flat out vec4 out_entity;
layout (location = 1) out vec4 out_color;
layout (location = 2) out vec4 out_texcoord;
layout (location = 3) out vec4 out_lmcoord;
layout (location = 4) out vec3 out_normal;
layout (location = 5) out vec4 out_tangent;


// 
layout (triangles) in;
layout (triangle_strip, max_vertices = 3) out;

// 
uniform int instanceId;

const ivec3 order[2] = {
    ivec3(0,1,2),
    ivec3(2,1,0)
};

#include "../lib/common.glsl"

// 
void main() {
    // reorder vertices
    for (int i = 0; i < 3; i++) {
        int oi = order[instanceId][i];

        int layerId = DEFAULT_SCENE;
        if (instanceId == 0) {
            if (entity[oi].x == 2.f) { layerId = WATER_SCENE; };
        }
        if (instanceId == 1) { layerId = REFLECTION_SCENE; };
        
        gl_Layer = layerId;

        out_color = color[oi];
        out_texcoord = texcoord[oi];
        out_lmcoord = lmcoord[oi];
        out_normal = normal[oi];
        out_entity = entity[oi];
        out_tangent = tangent[oi];
        gl_Position = gl_in[oi].gl_Position; 
        //gl_Layer = layerId;
        EmitVertex();
    }
    
    EndPrimitive();
}
