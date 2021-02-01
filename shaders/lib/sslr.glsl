
vec4 GetColorSSR(){
    return vec4(0.f);
}

float GetDepthSSR(in vec2 screenSpaceCoord) {
    const vec2 txy = (screenSpaceCoord*0.5f+0.5f); // normalize screen space coordinates
    const vec4 txl = gatherLayer(depthtex0,txy,REFLECTION_SCENE,0);
    const vec2 ttf = fract(txy*textureSize(depthtex0,0).xy-0.5f);
    const vec2 px = vec2(1.f-ttf.x,ttf.x), py = vec2(1.f-ttf.y,ttf.y);
    const mat2x2 i2 = outerProduct(px,py);
    return dot(txl,vec4(i2[0],i2[1]).zwyx); // interpolate
}

vec3 GetNormalSSR(in vec2 screenSpaceCoord) {
    const vec2 txy = (screenSpaceCoord*0.5f+0.5f);
    const vec3 colp = fetchLayer(colortex1, ivec2(txy.xy*textureSize(colortex1,0).xy), REFLECTION_SCENE).xyz;
    return normalize(colp*2.f-1.f);
}

// almost pixel-perfect screen space reflection 
vec4 EfficientSSR(in vec3 cameraSpaceOrigin, in vec3 cameraSpaceDirection){
    vec4 WSR = gbufferModelViewInverse * vec4(cameraSpaceDirection, 0.f);
    WSR.y *= -1.f;
    cameraSpaceDirection = (gbufferModelView * WSR).xyz;
    
    // 
    vec4 screenSpaceOrigin = CameraSpaceToScreenSpace(vec4(cameraSpaceOrigin,1.f));
    vec4 screenSpaceOriginNext = CameraSpaceToScreenSpace(vec4(cameraSpaceOrigin+cameraSpaceDirection,1.f));
    vec4 screenSpaceDirection = vec4(normalize(screenSpaceOriginNext.xyz-screenSpaceOrigin.xyz),0.f);
    screenSpaceDirection.xyz = normalize(screenSpaceDirection.xyz);

    // 
    const vec2 screenSpaceDirSize = abs(screenSpaceDirection.xy*vec2(viewWidth,viewHeight));
    screenSpaceDirection.xyz /= max(screenSpaceDirSize.x,screenSpaceDirSize.y)*(1.f/16.f); // half of image size

    // 
    vec4 finalOrigin = vec4(screenSpaceOrigin.xyz,0.f);
    screenSpaceOrigin.xyz += screenSpaceDirection.xyz*0.0625f;
    for (int i=0;i<256;i++) { // do precise as possible 
        
        // check if origin gone from screen 
        if (any(lessThanEqual(screenSpaceOrigin.xyz,vec3(-1.f.xx,-0.1f))) || any(greaterThan(screenSpaceOrigin.xyz,vec3(1.f.xx,1.1f.x)))) { break; };

        // 
        if ((GetDepthSSR(screenSpaceOrigin.xy)-1e-8f)<=screenSpaceOrigin.z) {
            vec3 screenSpaceOrigin = screenSpaceOrigin.xyz-screenSpaceDirection.xyz, screenSpaceDirection = screenSpaceDirection.xyz * 0.5f;

            // ray origin refinement
            for (int j=0;j<16;j++) {
                if ((GetDepthSSR(screenSpaceOrigin.xy)-1e-8f)<=screenSpaceOrigin.z) {
                    screenSpaceOrigin -= screenSpaceDirection, screenSpaceDirection *= 0.5f;
                } else {
                    screenSpaceOrigin += screenSpaceDirection;
                }
            }

            const vec3 cameraNormal = GetNormalSSR(screenSpaceOrigin.xy);
            
            // recalculate ray origin by normal 
            const vec3 inPosition = ScreenSpaceToCameraSpace(vec4(screenSpaceOrigin.xy,GetDepthSSR(screenSpaceOrigin.xy),1.f)).xyz;
            const float dist = dot(inPosition.xyz-cameraSpaceOrigin,cameraNormal)/dot(cameraNormal,cameraSpaceDirection);
            screenSpaceOrigin = CameraSpaceToScreenSpace(vec4(cameraSpaceDirection*dist+cameraSpaceOrigin,1.f)).xyz;
            
            // check ray deviation 
            if (dot(cameraNormal,cameraSpaceDirection)<=0.f && dot(GetNormalSSR(screenSpaceOrigin.xy),cameraNormal)>=0.5f /*&& abs(GetDepthSSR(screenSpaceOrigin.xy)-screenSpaceOrigin.z)<0.0001f*/) {
                finalOrigin.xyz = screenSpaceOrigin, finalOrigin.w = 1.f; //break; 
            };
            break; // 
        }

        // 
        screenSpaceOrigin.xyz += screenSpaceDirection.xyz, screenSpaceDirection.xyz *= 1.f+(1.f/1024.f);
    }

    //
    return finalOrigin;
}