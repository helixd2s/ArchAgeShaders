//these are our inputs from the vertex shader
layout (location = 0) in vec4 color[3];
layout (location = 1) in vec4 texcoord[3];
layout (location = 2) in vec4 lmcoord[3];
layout (location = 3) in vec3 normal[3];
layout (location = 4) in vec4 position[3];
layout (location = 5) flat in vec4 entity[3];
layout (location = 6) in vec4 tangent[3];
//layout (location = 6) in vec4 vnormal[3];

layout (location = 0) out vec4 out_color;
layout (location = 1) out vec4 out_texcoord;
layout (location = 2) out vec4 out_lmcoord;
layout (location = 3) out vec3 out_normal;
layout (location = 4) out vec4 out_position;
layout (location = 5) flat out vec4 out_entity;
layout (location = 6) out vec4 out_tangent;

layout (triangles) in;
layout (triangle_strip, max_vertices = 3) out;

uniform int instanceId;
const int countInstances = 2;

bvec3 and(in bvec3 a, in bvec3 b) {
    return bvec3(a.x&&b.x,a.y&&b.y,a.z&&b.z);
}

bvec3 or(in bvec3 a, in bvec3 b) {
    return bvec3(a.x||b.x,a.y||b.y,a.z||b.z);
}

bool aabbSegmentIntersection(float x1, float y1, float x2, float y2, float minX, float minY, float maxX, float maxY) {  
    // Completely outside.
    if ((x1 <= minX && x2 <= minX) || (y1 <= minY && y2 <= minY) || (x1 >= maxX && x2 >= maxX) || (y1 >= maxY && y2 >= maxY)) return false;

    float m = (y2 - y1) / (x2 - x1);

    float y = m * (minX - x1) + y1;
    if (y > minY && y < maxY) return true;

    y = m * (maxX - x1) + y1;
    if (y > minY && y < maxY) return true;

    float x = (minY - y1) / m + x1;
    if (x > minX && x < maxX) return true;

    x = (maxY - y1) / m + x1;
    if (x > minX && x < maxX) return true;

    return false;
}

bool aabbSegmentIntersection(in vec2 p1, in vec2 p2, in vec2 mn, in vec2 mx) {
    return aabbSegmentIntersection(p1.x,p1.y,p2.x,p2.y,mn.x,mn.y,mx.x,mx.y);
}

void main() {
    mat3x2 coord2d = mat3x2(
        ((vec2(gl_in[0].gl_Position.xy / gl_in[0].gl_Position.w) + 1.f.xx) * 0.5f.xx)*vec2(2.f,2.f),
        ((vec2(gl_in[1].gl_Position.xy / gl_in[1].gl_Position.w) + 1.f.xx) * 0.5f.xx)*vec2(2.f,2.f),
        ((vec2(gl_in[2].gl_Position.xy / gl_in[2].gl_Position.w) + 1.f.xx) * 0.5f.xx)*vec2(2.f,2.f)
    );

    // clip space
    if (instanceId == 1) { for (int i=0;i<3;i++) { coord2d[i].y -= 1.f; }; };

    // culling into clip-space
    mat2x3 tcoord = transpose(coord2d);
    //if (any(and(
    //    and(greaterThanEqual(tcoord[0], vec3(0.f.xxx)), lessThan(tcoord[0], vec3(1.f.xxx))), // X coordinate
    //    and(greaterThanEqual(tcoord[1], vec3(0.f.xxx)), lessThan(tcoord[1], vec3(1.f.xxx)))  // Y coordinate
    //)) || 
    //    aabbSegmentIntersection(coord2d[0], coord2d[1], vec2(0.f.xx), vec2(1.f.xx)) || 
    //    aabbSegmentIntersection(coord2d[1], coord2d[2], vec2(0.f.xx), vec2(1.f.xx)) || 
    //    aabbSegmentIntersection(coord2d[2], coord2d[0], vec2(0.f.xx), vec2(1.f.xx))
    //) 
    {
        for (int i = 0; i < 3; i++) {
            out_color = color[i];
            out_texcoord = texcoord[i];
            out_lmcoord = lmcoord[i];
            out_normal = normal[i];
            out_position = position[i];
            out_entity = entity[i];
            out_tangent = tangent[i];

            gl_Position = gl_in[i].gl_Position; 
            EmitVertex();
        };
        
        EndPrimitive();
    };
}
