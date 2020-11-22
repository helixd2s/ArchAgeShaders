#version 460 compatibility
#extension GL_NV_gpu_shader5 : enable

uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;

layout (location = 0) in vec2 vtexcoord;

uniform sampler2D colortex7;
uniform sampler2D colortex3;

uniform float viewWidth;
uniform float viewHeight;

uniform vec3 cameraPosition;

//uniforms (projection matrices)
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;

#include "/lib/math.glsl"
#include "/lib/transforms.glsl"
#include "/lib/shadowmap.glsl"
#include "/lib/sslr.glsl"
#include "/lib/water.glsl"

/*DRAWBUFFERS:01234567*/

/*
    const int colortex0Format = RGBA32F;
    const int colortex1Format = RGBA32F;
    const int colortex2Format = RGBA32F;
    const int colortex3Format = RGBA32F;
    const int colortex4Format = RGBA32F;
    const int colortex5Format = RGBA32F;
    const int colortex6Format = RGBA32F;
    const int colortex7Format = RGBA32F;

    const bool colortex7Clear = false;
*/

void main() {
    //vec2 shifting = 0.5f*vec2(1.f/viewWidth, 1.f/viewHeight); // avoid linear interpolation
	//vec2 texcoord = (vtexcoord - shifting) * 0.5f + shifting;
	//vec2 rtexcoord = (vtexcoord - shifting) * 0.5f + shifting;
	//rtexcoord.y += 0.5f;
    ivec2  texcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight)) / 2;
    ivec2 rtexcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight)) / 2 + ivec2(0, viewHeight) / 2;

    vec3 sceneDepth = texelFetch(depthtex0, texcoord, 0).xxx;
    vec3 screenpos 	= getScreenpos(sceneDepth.x, vtexcoord*0.5f);
    vec3 worldpos   = toWorldpos(screenpos);

    vec3 normal     = normalize(texelFetch(colortex1, texcoord, 0).rgb * 2.f - 1.f);
    vec3 tangent    = normalize(texelFetch(colortex4, texcoord, 0).rgb * 2.f - 1.f);
    vec3 bitangent  = normalize(cross(tangent, normal));

    vec3 world_bitangent = mat3(gbufferModelViewInverse) * bitangent;
    vec3 world_tangent = mat3(gbufferModelViewInverse) * tangent;
    vec3 world_normal = mat3(gbufferModelViewInverse) * normal;

    float reflcoef  = 1.f - abs(dot(normalize(screenpos), normal));

	vec3 sceneColor = texelFetch(colortex0, texcoord, 0).rgb;
		 sceneColor = pow(sceneColor, vec3(1.0/2.2));	//convert color back to display gamma

    float filterRefl = texelFetch(colortex3, texcoord, 0).r;
    if (filterRefl > 0.999f) {
        vec3 ntexture = normalize(mix(get_water_normal(worldpos, 1.f, world_normal, world_tangent, world_bitangent).xzy, vec3(0.f,0.f,1.f), 0.96f));
        normal = mat3(tangent, bitangent, normal) * ntexture;
    }

    vec4 sslrpos = EfficientSSR(screenpos.xyz, normalize(reflect(normalize(screenpos.xyz), normal)));
    //sslrpos = CameraSpaceToScreenSpace(sslrpos);

    sslrpos.xy = (sslrpos.xy * 0.5f + 0.5f) * 0.5f + vec2(0.f, 0.5f);
    //get_water_normal

    rtexcoord = ivec2(sslrpos.xy * vec2(viewWidth, viewHeight));
	vec3 reflColor 	= texelFetch(colortex0, rtexcoord.xy, 0).rgb;
		 reflColor 	= pow(reflColor, vec3(1.0/2.2));	//convert color back to display gamma

    if (any(lessThan(sslrpos.xy,vec2(0.f.x,0.5f))) || any(greaterThanEqual(sslrpos.xy, vec2(0.5f, 1.f)))) {
        reflColor = vec3(0.f);
    }

	gl_FragData[0] = vec4(mix(sceneColor, reflColor, filterRefl > 0.999f ? (0.1f + reflcoef*vec3(0.4f.xxx)) : vec3(0.f.xxx)), 1.0);
    //gl_FragData[0] = vec4(normal * 0.5f + 0.5f, 1.f);
    gl_FragData[7] = texture(colortex7, vtexcoord, 0);
    //gl_FragData[0] = vec4(texture(colortex7, vtexcoord).yyy * 0.1f, 1.0);
}
