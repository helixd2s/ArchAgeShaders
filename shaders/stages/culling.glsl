//these are our inputs from the vertex shader
layout (location = 0) in vec4 color[3];
layout (location = 1) in vec4 texcoord[3];
layout (location = 2) in vec4 lmcoord[3];
layout (location = 3) in vec3 normal[3];
layout (location = 4) in vec4 position[3];
layout (location = 5) flat in vec4 entity[3];
layout (location = 6) in vec4 tangent[3];
layout (location = 7) in vec4 planar[3];
//layout (location = 6) in vec4 vnormal[3];

layout (location = 0) out vec4 out_color;
layout (location = 1) out vec4 out_texcoord;
layout (location = 2) out vec4 out_lmcoord;
layout (location = 3) out vec3 out_normal;
layout (location = 4) out vec4 out_position;
layout (location = 5) flat out vec4 out_entity;
layout (location = 6) out vec4 out_tangent;
layout (location = 7) out vec4 out_planar;

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

/* Check whether P and Q lie on the same side of line AB */
float side(in vec2 p, in vec2 q, in vec2 a, in vec2 b)
{
    float z1 = (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
    float z2 = (b.x - a.x) * (q.y - a.y) - (q.x - a.x) * (b.y - a.y);
    return z1 * z2;
}

/* Check whether segment P0P1 intersects with triangle t0t1t2 */
bool triangleSegmentIntersection(in vec2 p0, in vec2 p1, in vec2 t0, in vec2 t1, in vec2 t2)
{
    float f1 = side(p0, t2, t0, t1), f2 = side(p1, t2, t0, t1);
    float f3 = side(p0, t0, t1, t2), f4 = side(p1, t0, t1, t2);
    float f5 = side(p0, t1, t2, t0), f6 = side(p1, t1, t2, t0);
    float f7 = side(t0, t1, p0, p1);
    float f8 = side(t1, t2, p0, p1);

    if ((f1 < 0 && f2 < 0) || (f3 < 0 && f4 < 0) || (f5 < 0 && f6 < 0) || (f7 > 0 && f8 > 0))
        return false;
        //return NOT_INTERSECTING;

    if ((f1 == 0 && f2 == 0) || (f3 == 0 && f4 == 0) || (f5 == 0 && f6 == 0))
        return true;
        //return OVERLAPPING;

    if ((f1 <= 0 && f2 <= 0) || (f3 <= 0 && f4 <= 0) || (f5 <= 0 && f6 <= 0) || (f7 >= 0 && f8 >= 0))
        return true;
        //return TOUCHING;

    if (f1 > 0 && f2 > 0 && f3 > 0 && f4 > 0 && f5 > 0 && f6 > 0)
        return false;
        //return NOT_INTERSECTING;

    //return INTERSECTING;
    return true;
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
    // 
    mat3x2 coord2d = mat3x2(
        position[0].xy * 0.5f + 0.5f,
        position[1].xy * 0.5f + 0.5f,
        position[2].xy * 0.5f + 0.5f
    );

    // culling into clip-space
    mat2x3 tcoord = transpose(coord2d);
    if (any(and(
        and(greaterThanEqual(tcoord[0], vec3(0.f.xxx)), lessThan(tcoord[0], vec3(1.f.xxx))), // X coordinate
        and(greaterThanEqual(tcoord[1], vec3(0.f.xxx)), lessThan(tcoord[1], vec3(1.f.xxx)))  // Y coordinate
    )) || 
        triangleSegmentIntersection(vec2(0.f, 0.f), vec2(1.f, 0.f), coord2d[0], coord2d[1], coord2d[2]) || 
        triangleSegmentIntersection(vec2(1.f, 0.f), vec2(1.f, 1.f), coord2d[0], coord2d[1], coord2d[2]) || 
        triangleSegmentIntersection(vec2(1.f, 1.f), vec2(0.f, 1.f), coord2d[0], coord2d[1], coord2d[2]) ||
        triangleSegmentIntersection(vec2(0.f, 1.f), vec2(0.f, 0.f), coord2d[0], coord2d[1], coord2d[2]) || 
        aabbSegmentIntersection(coord2d[0], coord2d[1], vec2(0.f.xx), vec2(1.f.xx)) || 
        aabbSegmentIntersection(coord2d[1], coord2d[2], vec2(0.f.xx), vec2(1.f.xx)) || 
        aabbSegmentIntersection(coord2d[2], coord2d[0], vec2(0.f.xx), vec2(1.f.xx))
    ) 
    {
        for (int i = 0; i < 3; i++) {
            out_color = color[i];
            out_texcoord = texcoord[i];
            out_lmcoord = lmcoord[i];
            out_normal = normal[i];
            out_position = position[i];
            out_entity = entity[i];
            out_tangent = tangent[i];
            out_planar = planar[i];

            gl_Position = gl_in[i].gl_Position; 
            EmitVertex();
        };
        
        EndPrimitive();
    };
}
