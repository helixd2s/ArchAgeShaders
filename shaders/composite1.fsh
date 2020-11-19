#version 460 compatibility


uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;

layout (location = 0) in vec2 vtexcoord;

uniform sampler2D colortex7;
uniform sampler2D colortex3;

uniform float viewWidth;
uniform float viewHeight;

uniform vec3 cameraPosition;

//uniforms (projection matrices)
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;

#include "/lib/math.glsl"
#include "/lib/transforms.glsl"
#include "/lib/shadowmap.glsl"


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
    ivec2 texcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight)) / 2;
    ivec2 rtexcoord = ivec2(vtexcoord * vec2(viewWidth, viewHeight)) / 2 + ivec2(0, viewHeight) / 2;

    vec3 sceneDepth = texelFetch(depthtex0, texcoord, 0).xxx;
    vec3 screenpos 	= getScreenpos(sceneDepth.x, vtexcoord*0.5f);
    vec3 normal     = normalize(texelFetch(colortex1, texcoord, 0).rgb * 2.f - 1.f);
    float reflcoef  = 1.f - abs(dot(normalize(screenpos), normal));

	vec3 sceneColor = texelFetch(colortex0, texcoord, 0).rgb;
		 sceneColor = pow(sceneColor, vec3(1.0/2.2));	//convert color back to display gamma

    float filterRefl = texelFetch(colortex3, texcoord, 0).r;

	vec3 reflColor 	= texelFetch(colortex0, rtexcoord, 0).rgb;
		 reflColor 	= pow(reflColor, vec3(1.0/2.2));	//convert color back to display gamma

	gl_FragData[0] = vec4(mix(sceneColor, reflColor, filterRefl > 0.999f ? (0.1f + reflcoef*vec3(0.4f.xxx)) : vec3(0.f.xxx)), 1.0);
    gl_FragData[7] = texture(colortex7, vtexcoord, 0);
    //gl_FragData[0] = vec4(texture(colortex7, vtexcoord).yyy * 0.1f, 1.0);
}
