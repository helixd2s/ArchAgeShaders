#version 460 compatibility
#extension GL_NV_gpu_shader5 : enable

layout (location = 0) in vec2 vtexcoord;
layout (location = 1) in flat int layerId;

uniform vec3 cameraPosition;
uniform vec3 skyColor;

//uniforms (projection matrices)
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;

#include "/lib/common.glsl"
#include "/lib/convert.glsl"
#include "/lib/buffers.glsl"
#include "/lib/math.glsl"
#include "/lib/transforms.glsl"
#include "/lib/shadowmap.glsl"
#include "/lib/sslr.glsl"
#include "/lib/water.glsl"

/*DRAWBUFFERS:0*/

uniform sampler2D colortex8; // lightmap
uniform sampler2D colortex9; // diffuse
uniform sampler2D colortexA; // normals
uniform sampler2D colortexB; // specular

uniform ivec2 atlasSize;

const vec2 texSize = vec2(128.f, 128.f);

vec4 sampleInbound(in sampler2D depthtex, in vec2 unit, in vec2 atlasOffset) {
    vec2 gridSize = textureSize(depthtex, 0).xy/texSize;
    vec2 spaces = fract(unit)/gridSize + atlasOffset;
    return texture(depthtex, spaces);
}

float depthHeight = 0.25f;
float normalDepth = 0.25f;
const int linearSteps = 24;
const int binarySteps = 8;

// TODO: DEFERRED MAPPING!
// Needs layered framebuffers support and early fragment testing! (up to 100% can be faster)
vec3 searchIntersection(in sampler2D depthtex, in vec2 texcoord, in vec3 view, inout bool debugIndicator) {
    vec3 dir = vec3(-view.xy/view.z, -1.f);

    vec2 gridSize = textureSize(depthtex, 0).xy/texSize;
    vec2 altasOffset = floor(texcoord*gridSize)/gridSize;
    vec2 unit = fract(texcoord*gridSize);

    float stepSize = 1.f/float(linearSteps)*depthHeight;
    vec3 coord = vec3(unit, 0.f);
    
    vec3 bcoord = coord;
    vec3 pcoord = coord;
    float t = 0.f;
    
    float bestHeight = 0.f;

    for (int I=0;I<2;I++) {
        const int steps = I == 0 ? linearSteps : binarySteps;

        // try to search needed height
        vec3 best = coord;
        for (int r=0;r<steps;r++) 
        {
            float height = -(1.f-sampleInbound(depthtex, coord.xy, altasOffset).w)*depthHeight;
            if (coord.z <= height) {
                best = coord, bestHeight = height;
                if (abs(height - coord.z) < 0.001f) { break; };
                coord -= dir*stepSize;
                stepSize *= 0.5f;
            }
            coord += dir*stepSize;
        }
        coord = best;

        t = 0.f;
        {   // normal based planar intersection correction (but needs to check depth correct)
            // getting correct normal and height
            float amplifier = depthHeight/normalDepth;
            float height = -(1.f-sampleInbound(depthtex, coord.xy, altasOffset).w)*depthHeight;
            vec3 normal = normalize(sampleInbound(depthtex, coord.xy, altasOffset).xyz*2.f-1.f);
            normal = normalize(vec3(normal.xy*amplifier, normal.z));

            //float d = 0.f;
            float det = dot(vec3(dir.xy, dir.z), normal);
            t = dot(vec3(coord.xy, height) - coord, normal) / det;
            vec3 pre = coord + dir * t;
            
            float preHeight = -(1.f-sampleInbound(depthtex, pre.xy, altasOffset).w)*depthHeight;
            if (pre.z >= -depthHeight && abs(det) >= 0.0001f && abs(preHeight-pre.z) < 0.001f) { bestHeight = preHeight; } else { t = 0.f; };
        }
        coord += dir*t;

        // already got best result
        bcoord = coord;
        if ( abs(bestHeight-coord.z) < 0.001f ) { break; };
    }

    return vec3(altasOffset+fract(bcoord.xy)/gridSize, bcoord.z);
}



// THIS IS WATER SHADER
void main() {

    if (layerId == DEFAULT_SCENE) {
        //ivec2  texcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight));
        //ivec2 rtexcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight));

        // 
        vec3 sceneColor  = sampleLayer(colortex0, vtexcoord, DEFAULT_SCENE).rgb;
        float sceneDepth = sampleLayer(depthtex0, vtexcoord, DEFAULT_SCENE).x;
        vec4 viewpos     = vec4(getScreenpos(sceneDepth.x, vtexcoord), 1.f);
        vec3 worldpos    = toWorldpos(viewpos.xyz);
        vec3 worldview   = normalize(viewpos.xyz);

        // 
        vec3 normal     = sampleNormal(vtexcoord, DEFAULT_SCENE);
        vec3 tangent    = sampleTangent(vtexcoord, DEFAULT_SCENE);
        vec2 lmcoord    = sampleLmcoord(vtexcoord, DEFAULT_SCENE);
        vec2 texcoord   = sampleTexcoord(vtexcoord, DEFAULT_SCENE);
        vec2 indicator  = sampleIndicator(vtexcoord, DEFAULT_SCENE);
        vec3 bitangent  = normalize(cross(tangent, normal));

        // 
        mat3x3 tbn = mat3x3(normalize(tangent.xyz), normalize(cross(tangent.xyz, normal.xyz)), normalize(normal.xyz));
        vec3 tview = normalize(worldview.xyz*tbn);

        // 
        vec3 world_bitangent = mat3(gbufferModelViewInverse) * bitangent;
        vec3 world_tangent = mat3(gbufferModelViewInverse) * tangent;
        vec3 world_normal = mat3(gbufferModelViewInverse) * normal;
        float reflcoef  = 1.f - abs(dot(worldview, normal));

        // 
        if (indicator.x == 1.f) {
            bool debugIndicator = false;
            vec2 modTx = texcoord;//searchIntersection(colortexA, texcoord.xy, tview, debugIndicator).xy;
            viewpos.xyz -= normal.xyz * (1.f-texture(colortexA, texcoord.xy).w) * depthHeight;

            // 
            //sceneColor *= pow(texture(colortex9, modTx, 0).rgb, 2.2f.xxx);
            sceneColor *= pow(texture(colortex8, lmcoord, 0).rgb, 2.2f.xxx);
        };

        //sceneColor = texture(colortex9, vtexcoord, 0).rgb;

        gl_FragData[0] = vec4(sceneColor, sampleLayer(colortex0, vtexcoord, DEFAULT_SCENE).w);
    } else {
        gl_FragData[0] = sampleLayer(colortex0, vtexcoord, layerId);

        //discard;
    }


}
