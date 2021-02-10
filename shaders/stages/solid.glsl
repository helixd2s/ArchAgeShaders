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
uniform sampler2D normals;

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

uniform ivec2 atlasSize;

const vec2 texSize = vec2(128.f, 128.f);

vec4 sampleInbound(in sampler2D depthtex, in vec2 unit, in vec2 atlasOffset) {
    vec2 gridSize = vec2(atlasSize)/texSize;
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

    vec2 gridSize = vec2(atlasSize)/texSize;
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
#if defined(WEATHER) || defined(HAND) || (defined(BASIC) && !defined(SKY)) || defined(CLOUDS)
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
    vec4 vtangent = gbufferModelViewInverse * vec4(normalize(gl_NormalMatrix*at_tangent.xyz), 0.f);
    vec4 vnormal = gbufferModelViewInverse * vec4(normalize(gl_NormalMatrix*gl_Normal), 0.f);
    if (instanceId == 1) {
        vnormal.y *= -1.f;
        vtangent.y *= -1.f;
    };

    // 
	normal = (gbufferModelView * vnormal).xyz;
    tangent = (gbufferModelView * vtangent);
    entity = mc_Entity;
    entity.w = intBitsToFloat(layerId_);

    // set where needs to draw
    SetLayer(gl_Position, gl_Layer, layerId);
#endif

#ifdef FRAGMENT_SHADER
	// sado guru algorithm
	vec2 coordf = gl_FragCoord.xy;// * gl_FragCoord.w;

#ifndef USE_SPLIT_SCREEN
	coordf.xy /= vec2(viewWidth, viewHeight);
#else
    coordf.xy = convertUnit(coordf.xy / vec2(viewWidth, viewHeight), layerId);
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
    //if (checkArea(coordf))
    if (checkArea(coordf) && ((planar.y <= (height - 0.001f) && instanceId == 1 || instanceId == 0 && normalCorrect) && ((entity.x == 2.f || entity.x == 3.f) ? sampleLayer(depthtex0, coordf, instanceId == 1 ? REFLECTION_SCENE : DEFAULT_SCENE).x >= sslrpos.z && instanceId == 0 : true))) 
#else
    if (checkArea(coordf)) 
#endif
    {
        f_detector = vec4(0.f.xxx, 1.f);
        f_depth = sslrpos.z;

        bool debugIndicator = false;
    #ifdef SOLID //
        mat3x3 tbn = mat3x3(normalize(tangent.xyz), (instanceId == 1 ? -1.f : 1.f)*normalize(cross(tangent.xyz, normal.xyz)), normalize(normal.xyz));
        vec3 tview = normalize(worldview.xyz*tbn);
#ifdef BLOCKS
        
        vec2 modTx = searchIntersection(normals, texcoord.xy, tview, debugIndicator).xy;
        viewpos.xyz -= normal.xyz * (1.f-texture(normals, texcoord.xy).w) * depthHeight;
        sslrpos = gbufferProjection * viewpos; sslrpos /= sslrpos.w;
#else
        vec2 modTx = texcoord.xy;
#endif

        //vec3 mnormal = normalize(texture(normals, modTx).xyz*2.f-1.f);
        //mnormal = normalize(vec3(mnormal.xy, mnormal.z/normalDepth));

		f_color = texture(tex, modTx.st) * color;
        f_color *= texture(lightmap, lmcoord.xy);

        // debug some fragments
        //if (debugIndicator) { f_color = vec4(0.f, 1.f, 0.f, 1.f); };

        //f_color = vec4(mnormal*0.5f+0.5f, 1.f);
		f_normal = vec4(normal, 1.0);
        f_tangent = vec4(tangent.xyz, 1.f);
		f_lightmap = texture(lightmap, lmcoord.xy);
        f_texcoord = modTx.st;
        f_lmcoord = lmcoord.xy;
        f_depth = sslrpos.z;

        f_normal.xyz = dot(f_normal.xyz.xyz, worldview.xyz) >= 0.f ? -f_normal.xyz : f_normal.xyz;

        if (entity.x == 2.f) { f_color = color * vec4(0.f,0.f,0.f, 1.f), f_detector = vec4(1.f.xxx, 1.f); }
        if (entity.x == 2.f && dot(normalize((gbufferModelViewInverse * vec4(normal.xyz, 0.f)).xyz), vec3(0.f, 1.f, 0.f)) >= 0.999f) {
            f_planar = vec4(planar.xyz, 1.0f);
        }
    #endif

    // FIXED
    #ifdef CLOUDS
		f_color = texture(tex, texcoord.xy) * color;
        f_color *= texture(lightmap, lmcoord.xy);
        f_lightmap = texture(lightmap, lmcoord.xy);
		f_normal = vec4(normal, 1.0);
        f_tangent = vec4(tangent.xyz, 1.f);
        f_lightmap.xy = lmcoord.xy;
        f_texcoord.xy = texcoord.xy;

        // disabled clouds
        f_color.a = 0.f;
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
#if defined(SOLID) || defined(CLOUDS)
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
        gl_FragDepth = f_depth*0.5f+0.5f;
    };

#endif


}

