//these will be available in the fragment shader now, this can be more efficient for some calculations too because per-vertex is cheaper than per fragment/pixel
//stuff like sunlight color get's usually done here because of that
#ifdef VERTEX_SHADER
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 texcoord;
layout (location = 2) out vec4 lmcoord;
layout (location = 3) out vec3 normal;
layout (location = 4) out vec4 position;
layout (location = 5) flat out vec4 entity;
layout (location = 6) out vec4 tangent;
//layout (location = 6) out vec4 vnormal;
#endif

//these are our inputs from the vertex shader
#ifdef FRAGMENT_SHADER
layout (location = 0) in vec4 color;
layout (location = 1) in vec4 texcoord;
layout (location = 2) in vec4 lmcoord;
layout (location = 3) in vec3 normal;
layout (location = 4) in vec4 position;
layout (location = 5) flat in vec4 entity;
layout (location = 6) in vec4 tangent;
//layout (location = 6) in vec4 vnormal;
#endif

//
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

// 
uniform int instanceId;
uniform float viewWidth;
uniform float viewHeight;
uniform vec4 fogColor;
uniform int worldTime;
uniform int fogMode;

// 
const int GL_LINEAR = 9729;
const int GL_EXP = 2048;
const int countInstances = 2;

// 
#ifdef VERTEX_SHADER
attribute vec4 mc_Entity;
attribute vec4 at_tangent;
#endif

//we use this for all solid objects because they get rendered the same way anyways
//redundant code can be handled like this as an include to make your life easier
uniform sampler2D tex; 		//this is our albedo texture. optifine's "default" name for this is "texture" but that collides with the texture() function of newer OpenGL versions. We use "tex" or "gcolor" instead, although it is just falling back onto the same sampler as an undefined behavior
uniform sampler2D lightmap;	//the vanilla lightmap texture, basically useless with shaders

uniform sampler2D gaux4;

/*
    const int colortex0Format = RGBA32F;
    const int colortex1Format = RGBA32F;
    const int colortex2Format = RGBA32F;
    const int colortex3Format = RGBA32F;
    const int colortex4Format = RGBA32F;
    const int colortex5Format = RGBA32F;
    const int colortex6Format = RGBA32F;
    const int colortex7Format = RGBA32F;

    const vec4 colortex0ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex1ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex2ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex3ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex4ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex5ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex6ClearColor = vec4(0.f,0.f,0.f,0.f);
    const vec4 colortex7ClearColor = vec4(0.f,0.f,0.f,0.f);

    const bool colortex7Clear = false;
*/

/*DRAWBUFFERS:01234567*/

void main() {
#ifdef VERTEX_SHADER
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	
	position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    position.xyz += cameraPosition;

    // planar reflected
    const float height = texture(gaux4, vec2(0.25f, 0.25f)).y;
    if (instanceId == 1) {
        position.y -= height;
        position.y *= -1.f;
        position.y += height;
    };

	gl_Position = gl_ProjectionMatrix * (gbufferModelView * (position - vec4(cameraPosition, 0.f)));
	
	color = gl_Color;
	
	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	
	gl_FogFragCoord = gl_Position.z;

    vec4 vnormal = gbufferModelViewInverse * vec4(normalize(gl_NormalMatrix*gl_Normal), 0.f);
    if (instanceId == 1) {
        vnormal.y *= -1.f;
    };
	normal = (gbufferModelView * vnormal).xyz;
    tangent = ( vec4(at_tangent.xyz, 0.f));

    entity = mc_Entity;

	#include "./vertexMod.glsl"
#endif

#ifdef FRAGMENT_SHADER
	// sado guru algorithm
	vec2 coordf = gl_FragCoord.xy * 2.f;// * gl_FragCoord.w;
	coordf.xy /= vec2(viewWidth, viewHeight);
	if (instanceId == 1) { coordf.y -= 1.f; };

    // 
    vec4 viewpos = gbufferProjectionInverse * vec4(coordf * 2.f - 1.f, gl_FragCoord.z, 1.f); viewpos /= viewpos.w;
    vec3 worldview = normalize(viewpos.xyz);
    //vec4 worldpos = gbufferModelViewInverse * viewpos;
    //vec3 worldview = normalize(worldpos.xyz - cameraPosition);

    // 
    #ifdef SOLID
    bool normalCorrect = dot(worldview.xyz, normal.xyz) <= 0.f;
    #else
    bool normalCorrect = true;
    #endif
    
    gl_FragData[0] = vec4(0.f.xxxx);
    gl_FragData[1] = vec4(0.f.xxxx);
    gl_FragData[2] = vec4(0.f.xxxx);
    gl_FragData[3] = vec4(0.f.xxxx);
    gl_FragData[4] = vec4(0.f.xxxx);
    gl_FragData[5] = vec4(0.f.xxxx);
    gl_FragData[6] = vec4(0.f.xxxx);
    gl_FragData[7] = vec4(0.f.xxxx);
    gl_FragDepth = 2.f;

    const float height = texture(gaux4, vec2(0.25f, 0.25f)).y;
	if (coordf.x >= 0.f && coordf.y >= 0.f && coordf.x < 1.f && coordf.y < 1.f && (instanceId == 0 || position.y < height - 0.001f) && normalCorrect) {
        gl_FragDepth = gl_FragCoord.z;

    #ifdef SOLID
		//this is the scene color
		gl_FragData[0] = texture(tex, texcoord.st) * color;

        if (entity.x == 2.f) {
            gl_FragData[0] = color * vec4(0.0f.xxx, 0.1f);
        }

        gl_FragData[0] *= texture(lightmap, lmcoord.xy);

		//write normals to a buffer to be reused later, doing *0.5+0.5 to them because they are in -1 to 1 range but buffers cant store negative values
		gl_FragData[1] = vec4(normal*0.5+0.5, 1.0);

		//write lightmaps to a buffer because we wanna use them later
		gl_FragData[2] = vec4(lmcoord.xy, 0.0, 1.0);
		gl_FragDepth = gl_FragCoord.z;

        gl_FragData[3] = vec4(0.f.xxx, 1.f);
        gl_FragData[4] = vec4(tangent.xyz * 0.5f + 0.5f, 1.f);
        if (entity.x == 2.f && dot(normalize((gbufferModelViewInverse * vec4(normal.xyz, 0.f)).xyz), vec3(0.f, 1.f, 0.f)) >= 0.999f) {
            gl_FragData[7] = vec4(position.xyz, 1.0f);
            gl_FragData[3] = vec4(1.f.xxx, 1.f);
        }
    #endif

    #ifdef SKY
        #ifdef BASIC
            gl_FragData[0] = color;
        #else
            gl_FragData[0] = texture(tex, texcoord.st) * color;
        #endif

        gl_FragData[1] = vec4(vec3(0.f,0.f,1.f), 1.0);
        gl_FragDepth = 1.f;

        if (fogMode == GL_EXP) {
            gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, 1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0));
        } else if (fogMode == GL_LINEAR) {
            gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
        }
    #endif

    #ifdef WEATHER
        gl_FragData[0] = texture(tex, texcoord.st) * texture(lightmap, lmcoord.st) * color;
        gl_FragData[0] *= texture(lightmap, lmcoord.xy);
        gl_FragData[1] = vec4(normal*0.5+0.5, 1.0);
        gl_FragData[2] = vec4(lmcoord.xy, 0.0, 1.0);
        gl_FragDepth = gl_FragCoord.z;
    #endif

    #ifdef HAND
        gl_FragData[0] = texture(tex, texcoord.st) * texture(lightmap, lmcoord.st) * color;
        gl_FragData[0] *= texture(lightmap, lmcoord.xy);
        gl_FragData[1] = vec4(normal*0.5+0.5, 1.0);
        gl_FragData[2] = vec4(lmcoord.xy, 0.0, 1.0);
        gl_FragDepth = gl_FragCoord.z;
    #endif

    #ifdef OTHER
        #ifdef BASIC
            gl_FragData[0] = color;
        #else
            gl_FragData[0] = texture(tex, texcoord.st) * color;
        #endif

        // 
        gl_FragData[1] = vec4(vec3(gl_FragCoord.z), 1.0f);
        gl_FragDepth = gl_FragCoord.z;

        if (fogMode == GL_EXP) {
            gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, 1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0));
        } else if (fogMode == GL_LINEAR) {
            gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
        };
    #endif
	} else {
        discard;
        gl_FragData[0] = vec4(0.f.xxxx);
        gl_FragData[1] = vec4(0.f.xxxx);
        gl_FragData[2] = vec4(0.f.xxxx);
        gl_FragData[3] = vec4(0.f.xxxx);
        gl_FragData[4] = vec4(0.f.xxxx);
        gl_FragData[5] = vec4(0.f.xxxx);
        gl_FragData[6] = vec4(0.f.xxxx);
        gl_FragData[7] = vec4(0.f.xxxx);
		gl_FragDepth = 2.f;
	};

    // 
    gl_FragData[0].rgb = pow(gl_FragData[0].rgb, 2.2f.xxx);
#endif


}

