
vec4 GetColorRM(){
    return vec4(0.f);
}

float GetDepthRM(in vec2 screenSpaceCoord, in int sceneId) {
    return sampleLinear(depthtex0, screenSpaceCoord*0.5f+0.5f, sceneId)*2.f-1.f;
}

vec3 GetNormalRM(in vec2 screenSpaceCoord, in int sceneId) {
    return sampleNormal(screenSpaceCoord*0.5f+0.5f, sceneId);
}



// almost pixel-perfect screen space reflection 
vec4 EfficientRM(in vec3 cameraSpaceOrigin, in vec3 cameraSpaceDirection, in int sceneId, in bool filterDepth) {

    const vec2 txs = textureSize(depthtex0,0).xy;
#ifdef USE_SPLIT_SCREEN
    const vec2 mps = (splitArea[sceneId].zw - splitArea[sceneId].xy);
#else
    const vec2 mps = 1.f.xx;
#endif
    const vec2 hpx = 0.5f/(txs.xy*mps);
    const vec2 hpm = 0.5f/(txs.xy);

    

    if (sceneId == REFLECTION_SCENE) {
        {   // needs reflect the reflection ray
            vec4 WSR = gbufferModelViewInverse * vec4(cameraSpaceDirection, 0.f);
            WSR.y *= -1.f;
            cameraSpaceDirection = (gbufferModelView * WSR).xyz;
        };
        
        {   // needs to correct plane of those SSLR
            const float height = sampleLayer(colortex7, vec2(0.5f, 0.5f), WATER_SCENE).y;
            vec4 WSP = CameraSpaceToModelSpace(vec4(cameraSpaceOrigin, 1.f));
            
            WSP /= WSP.w;
            WSP.y += cameraPosition.y;
            WSP.y -= height;
            WSP.y *= -1.f;
            WSP.y += height;
            WSP.y -= cameraPosition.y;
            
            cameraSpaceOrigin = divW(ModelSpaceToCameraSpace(WSP));
        };
    };

    // 
    vec4 screenSpaceOrigin = CameraSpaceToScreenSpace(vec4(cameraSpaceOrigin,1.f));
    vec4 screenSpaceOriginNext = CameraSpaceToScreenSpace(vec4(cameraSpaceOrigin+cameraSpaceDirection,1.f));
    vec4 screenSpaceDirection = vec4(normalize(screenSpaceOriginNext.xyz-screenSpaceOrigin.xyz),0.f);
    screenSpaceDirection.xyz = normalize(screenSpaceDirection.xyz);

    // 
#ifndef USE_SPLIT_SCREEN
    const vec2 screenSpaceDirSize = abs(screenSpaceDirection.xy*vec2(viewWidth,viewHeight));
#else
    const vec2 screenSpaceDirSize = abs(screenSpaceDirection.xy*vec2(viewWidth,viewHeight)*(splitArea[sceneId].zw - splitArea[sceneId].xy));
#endif

    screenSpaceDirection.xyz /= max(screenSpaceDirSize.x,screenSpaceDirSize.y)*(1.f/16.f); // half of image size

    // 
    vec4 finalOrigin = vec4(/*screenSpaceOrigin.xyz*/0.f.xxx,0.f);
    screenSpaceOrigin.xyz += screenSpaceDirection.xyz*0.0625f;

    // PLANNED HI-Z SCREEN SPACE REFLECTIONS
    for (int i=0;i<256;i++) { // do precise as possible 

        // 
        if ((GetDepthRM(screenSpaceOrigin.xy, sceneId)-1e-8f)<=screenSpaceOrigin.z) {
            vec3 screenSpaceOrigin = screenSpaceOrigin.xyz-screenSpaceDirection.xyz;
            vec3 screenSpaceDirection = screenSpaceDirection.xyz * 0.5f;
            vec3 best = screenSpaceOrigin;

            // due normal auto re-correction, that may to be incorrect, needs to try refinement twice
            for (int R=0;R<2;R++) {

                // do refinements
                for (int j=0;j<8;j++) {
                    float ssdepth = GetDepthRM(screenSpaceOrigin.xy, sceneId)-1e-8f;
                    if (ssdepth<=screenSpaceOrigin.z) {
                        best = screenSpaceOrigin;
                        screenSpaceOrigin.xyz -= screenSpaceDirection.xyz, screenSpaceDirection.xyz *= 0.5f;
                    } else {
                        screenSpaceOrigin.xyz += screenSpaceDirection.xyz;
                    }

                    // if too small distance, then break
                    if (abs(screenSpaceOrigin.z - ssdepth) < 0.0001f) { break; };
                }
                
                //
                screenSpaceOrigin = best;
                
                // recalculate ray origin by normal 
                const vec3 cameraNormal = GetNormalRM(screenSpaceOrigin.xy, sceneId);
                const vec3 inPosition = ScreenSpaceToCameraSpace(vec4(screenSpaceOrigin.xy,GetDepthRM(screenSpaceOrigin.xy, sceneId),1.f)).xyz;
                const float dist = dot(inPosition.xyz-cameraSpaceOrigin,cameraNormal)/dot(cameraNormal,cameraSpaceDirection);
                screenSpaceOrigin.xyz = CameraSpaceToScreenSpace(vec4(cameraSpaceDirection*dist+cameraSpaceOrigin,1.f)).xyz;
            };
            
            // check ray deviation 
            vec3 cameraNormal = GetNormalRM(screenSpaceOrigin.xy, sceneId);
            float gdepth = GetDepthRM(screenSpaceOrigin.xy, sceneId);
            if (dot(cameraNormal,cameraSpaceDirection)<=0.f && abs(gdepth-screenSpaceOrigin.z)<(filterDepth ? 0.0002f : 0.001f) && (filterDepth?gdepth<=0.9999f:true) && 
            screenSpaceOrigin.x >= -1.f && screenSpaceOrigin.x < 1.f && screenSpaceOrigin.y >= -1.f && screenSpaceOrigin.y < 1.f) {
                finalOrigin.xyz = screenSpaceOrigin.xyz, finalOrigin.w = 1.f; break; // 
            }

            // use fast reflections
            break;
        }

        // check if origin gone from screen 
        if (any(lessThanEqual(screenSpaceOrigin.xyz,vec3(-1.f.xx,-0.1f))) || any(greaterThan(screenSpaceOrigin.xyz,vec3(1.f.xx,1.f.x)))) { break; };

        // 
        screenSpaceOrigin.xyz += screenSpaceDirection.xyz, screenSpaceDirection.xyz *= 1.f+(1.f/1024.f);
    }

    //
    return finalOrigin;
}
