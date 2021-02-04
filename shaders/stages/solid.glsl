//these will be available in the fragment shader now, this can be more efficient for some calculations too because per-vertex is cheaper than per fragment/pixel
//stuff like sunlight color get's usually done here because of that
#ifdef VERTEX_SHADER
layout (location = 0) flat out vec4 entity;
layout (location = 1) out vec4 color;
layout (location = 2) out vec4 texcoord;
layout (location = 3) out vec4 lmcoord;
layout (location = 4) out vec3 normal;
layout (location = 5) out vec4 tangent;
#endif

//these are our inputs from the vertex shader
#ifdef FRAGMENT_SHADER
layout (location = 0) flat in vec4 entity;
layout (location = 1) in vec4 color;
layout (location = 2) in vec4 texcoord;
layout (location = 3) in vec4 lmcoord;
layout (location = 4) in vec3 normal;
layout (location = 5) in vec4 tangent;
#endif

#define layerId floatBitsToInt(entity.w)

//
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

// 
uniform int instanceId;
uniform int worldTime;

// 
const int GL_EXP2 = 2049;
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
uniform int frameCounter;

/*DRAWBUFFERS:0127*/

#ifdef EARLY_FRAG_TEST
// NOT SUPPORT SPLIT SCREEN (REQUIRED EXPLICIT CULLING)
//layout(early_fragment_tests) in;
#endif

// 
#include "../lib/common.glsl"
#include "../lib/convert.glsl"
#include "../lib/buffers.glsl"
#include "../lib/math.glsl"
#include "../lib/transforms.glsl"
#include "../lib/random.glsl"

uniform samplerTyped gaux4;


uniform int fogMode;
uniform float fogDensity;
uniform vec3 fogColor; 



void main() {
#ifdef VERTEX_SHADER
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    vec4 camera = gl_ModelViewMatrix * gl_Vertex;
    vec4 planar = CameraSpaceToModelSpace(camera);
    
    // planar reflected
    const float height = sampleLayer(gaux4, vec2(0.5f, 0.5f), WATER_SCENE).y;
    if (instanceId == 1) {
//#ifdef SKY // sun became larger when up-far
//        planar.y *= -1.f;
//#else // sun became higher when up-far
        planar.xyz += cameraPosition;
        planar.y -= height;
        planar.y *= -1.f;
        planar.y += height;
        planar.xyz -= cameraPosition;
//#endif
    };

    // 
	gl_Position = gl_ProjectionMatrix * ModelSpaceToCameraSpace(planar);
    gl_FogFragCoord = length(camera.xyz);
    
    //
#ifdef TRANSLUCENT
    int layerId_ = TRANSLUCENT_SCENE;
#else
    int layerId_ = DEFAULT_SCENE;
#endif

    if (instanceId == 0) {
#if defined(WEATHER) || defined(HAND) || (defined(BASIC) && !defined(SKY))
        layerId_ = TRANSLUCENT_SCENE;
#else
        if (mc_Entity.x == 3.f) { layerId_ = TRANSLUCENT_SCENE; };
        if (mc_Entity.x == 2.f) { layerId_ = WATER_SCENE; };
#endif
    };
    if (instanceId == 1) { layerId_ = REFLECTION_SCENE; };

    // 
    lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	color = gl_Color;

    // 
    vec4 vnormal = gbufferModelViewInverse * vec4(normalize(gl_NormalMatrix*gl_Normal), 0.f);
    if (instanceId == 1) {
        vnormal.y *= -1.f;
    };

    // 
	normal = (gbufferModelView * vnormal).xyz;
    entity = mc_Entity;
    entity.w = intBitsToFloat(layerId_);
    tangent = ( vec4(at_tangent.xyz, 0.f));

    // set where needs to draw
    SetLayer(gl_Position, gl_Layer, layerId);
#endif

#ifdef FRAGMENT_SHADER
	// sado guru algorithm
	vec2 coordf = gl_FragCoord.xy;// * gl_FragCoord.w;

#ifndef USE_SPLIT_SCREEN
	coordf.xy /= vec2(viewWidth, viewHeight);
#else
    coordf.xy /= vec2(viewWidth, viewHeight) * (splitArea[layerId].zw - splitArea[layerId].xy);
    coordf.xy -= splitArea[layerId].xy / (splitArea[layerId].zw - splitArea[layerId].xy);
#endif

    // 
    vec4 sslrpos = vec4(coordf * 2.f - 1.f, gl_FragCoord.z*2.f-1.f, 1.f);
    vec4 planar = CameraSpaceToModelSpace(ScreenSpaceToCameraSpace(sslrpos));
    planar.xyz += cameraPosition;

    // 
    vec4 viewpos = gbufferProjectionInverse * sslrpos; viewpos /= viewpos.w;
    vec3 worldview = normalize(viewpos.xyz);

    // 
    bool normalCorrect = true;
    #ifdef SOLID
        normalCorrect = dot(worldview.xyz, normal.xyz) <= 0.f;
    #endif

    // 
    const float height = sampleLayer(gaux4, vec2(0.5f, 0.5f), WATER_SCENE).y;

    // 
    vec4 f_color = vec4(0.f.xxxx);
    vec4 f_lightmap = vec4(0.f.xxxx);
    vec4 f_normal = vec4(0.f.xxxx);
    vec4 f_detector = vec4(0.f.xxxx);
    vec4 f_tangent = vec4(0.f.xxxx);
    vec4 f_planar = vec4(0.f.xxxx);
    vec2 f_lmcoord = vec2(0.f.xx);
    vec2 f_texcoord = vec2(0.f.xx);
    float f_depth = 2.f;

#ifndef SKY
	//if ((planar.y <= (height - 0.001f) && instanceId == 1 || instanceId == 0 && normalCorrect) && ((entity.x == 2.f || entity.x == 3.f) && instanceId == 0 ? sampleLayer(depthtex0, coordf, instanceId == 1 ? REFLECTION_SCENE : DEFAULT_SCENE).x >= sslrpos.z && instanceId == 0 : true)) 
    if (checkArea(coordf) && ((planar.y <= (height - 0.001f) && instanceId == 1 || instanceId == 0 && normalCorrect) && ((entity.x == 2.f || entity.x == 3.f) ? sampleLayer(depthtex0, coordf, instanceId == 1 ? REFLECTION_SCENE : DEFAULT_SCENE).x >= sslrpos.z && instanceId == 0 : true))) 
#else
    if (checkArea(coordf)) 
#endif
    {
        f_detector = vec4(0.f.xxx, 1.f);
        f_depth = sslrpos.z;

    #ifdef SOLID //
		f_color = texture(tex, texcoord.st) * color;
        f_color *= texture(lightmap, lmcoord.xy);
		f_normal = vec4(normal, 1.0);
        f_tangent = vec4(tangent.xyz, 1.f);
		f_lightmap = texture(lightmap, lmcoord.xy);
        f_texcoord = texcoord.st;
        f_lmcoord = lmcoord.xy;

        f_normal.xyz = dot(f_normal.xyz.xyz, worldview.xyz) >= 0.f ? -f_normal.xyz : f_normal.xyz;

        if (entity.x == 2.f) { f_color = color * vec4(0.f,0.f,0.f, 1.f), f_detector = vec4(1.f.xxx, 1.f); }
        if (entity.x == 2.f && dot(normalize((gbufferModelViewInverse * vec4(normal.xyz, 0.f)).xyz), vec3(0.f, 1.f, 0.f)) >= 0.99f) {
            f_planar = vec4(planar.xyz, 1.0f);
        }
    #endif

    #if defined(OTHER) || defined(SKY)
        #ifdef BASIC
            f_color = color;
        #else
            f_color = texture(tex, texcoord.st) * color;
        #endif
    #endif

    #ifdef SKY
        f_normal = vec4(vec3(0.f, 0.f, 1.f), 1.0);
        f_lightmap = vec4(vec3(0.f,0.f,1.f), 1.0);
        f_depth = 1.f;
    #endif

    #if defined(WEATHER) || defined(HAND)
        f_color = texture(tex, texcoord.st) * texture(lightmap, lmcoord.st) * color;
        f_color *= texture(lightmap, lmcoord.xy);
        f_normal = vec4(normal, 1.0);
        f_lightmap = vec4(lmcoord.xy, 0.0, 1.0);
        f_texcoord = texcoord.st;
        f_lmcoord = lmcoord.xy;
    #endif

    // DISABLE RAINS!
    #ifdef WEATHER
        f_color.w = 0.f;
    #endif

    #ifdef OTHER
        f_lightmap = vec4(vec3(gl_FragCoord.z), 1.0f);
    #endif

    #if defined(OTHER) || defined(SKY)
        float len = length(ScreenSpaceToCameraSpace(sslrpos).xyz);
        if (fogMode == GL_LINEAR) { f_color.rgb = mix(f_color.rgb, fogColor, clamp((len - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0)); } else
        if (fogMode == GL_EXP   ) { f_color.rgb = mix(f_color.rgb, fogColor, 1.0 - clamp(exp(-fogDensity * len), 0.0, 1.0)); } //else 
        //if (fogMode == GL_EXP2  ) { f_color.rgb = mix(f_color.rgb, fogColor, 1.0 - clamp(exp(-pow(fogDensity * len, 2.f)), 0.0, 1.0)); }
    #endif

	}
//#ifndef SKY
    else { f_color.a = 0.f; discard; };
//#endif

    // finalize results
    {   // 
        f_normal.xyz = f_normal.xyz * 0.5f + 0.5f;
        f_tangent.xyz = f_tangent.xyz * 0.5f + 0.5f;

#ifdef SOLID
#if defined(TRANSLUCENT) || defined(HAND)
#ifndef PARTICLES
        if (f_color.a <= 0.9999f) 
#endif
        { // fix entity issues
            f_color.rgb = pow(f_color.rgb, vec3(2.2f));
        }
#endif
#endif

        // 
        float enabled = 1.f;
#ifdef SOLID
        if (f_color.a <= random(vec4(sslrpos.xyz, float(frameCounter)))) { 
            f_detector = vec4(0.f.xxx, 0.f);
            f_color = vec4(0.f.xxx, 0.f);
            f_normal = vec4(0.f.xxx, 0.f);
            f_tangent = vec4(0.f.xxx, 0.f);
            f_lightmap = vec4(0.f.xxx, 0.f);
            f_planar = vec4(0.f.xxx, 0.f);
            enabled = 0.f;
            discard;
        } else {
            f_color.w = 1.f;
        }
#else
    #if defined(WEATHER) || defined(HAND) || (defined(BASIC) && !defined(SKY))
        if (instanceId == 1) {
            f_color.a = 0.f;
        }
    #endif

        if (f_color.a <= 0.f) {
            f_detector = vec4(0.f.xxx, 0.f);
            f_color = vec4(0.f.xxx, 0.f);
            f_normal = vec4(0.f.xxx, 0.f);
            f_tangent = vec4(0.f.xxx, 0.f);
            f_lightmap = vec4(0.f.xxx, 0.f);
            f_planar = vec4(0.f.xxx, 0.f);
            enabled = 0.f;
            discard;
        }
#endif

        // 
        gl_FragData[0] = f_color;
        gl_FragData[1] = vec4(pack2x3(mat2x3(f_normal.xyz, f_tangent.xyz)), enabled);
        gl_FragData[2] = vec4(pack3x2(mat3x2(f_texcoord.xy, f_lmcoord.xy, vec2(0.f.xx))), enabled);
        gl_FragData[3] = f_planar;
        gl_FragDepth = f_depth;
    };

#endif


}

