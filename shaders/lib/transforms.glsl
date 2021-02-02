
#ifdef VERTEX_SHADER
const float scaleCoef = 1.0f;
#else
const float scaleCoef = 1.0f;
#endif

uniform float near;
uniform float far;

float linearize_depth(float d)
{
    return 2.f*far*near / (far + near - (far - near)*d);//near * far / (far + d * (near - far));
}


//screen-/viewspace position
vec3 getScreenpos(float depth, vec2 coord) {
    //vec4 posNDC = vec4(coord.x*2.0-1.0, coord.y*2.0-1.0, 2.0*depth-1.0, 1.0);
    vec4 posNDC = vec4(coord.x*2.0-1.0, coord.y*2.0-1.0, (depth), 1.0);
         posNDC = gbufferProjectionInverse*posNDC;
    return posNDC.xyz/posNDC.w;
}

//worldspace position
vec3 getWorldpos(float depth, vec2 coord) {
    vec3 posCamSpace    = getScreenpos(depth, coord).xyz;
    vec3 posWorldSpace  = viewMAD(gbufferModelViewInverse, posCamSpace);
    posWorldSpace.xyz  += cameraPosition.xyz;
    return posWorldSpace;
}

//convert screenspace to worldspace
vec3 toWorldpos(vec3 screenPos) {
    vec3 posCamSpace    = screenPos;
    vec3 posWorldSpace  = viewMAD(gbufferModelViewInverse, posCamSpace);
    posWorldSpace.xyz  += cameraPosition.xyz;
    return posWorldSpace;
}

//convert worldspace to screenspace
vec3 toScreenpos(vec3 worldpos) {
    vec3 posWorldSpace  = worldpos;
    posWorldSpace.xyz  -= cameraPosition.xyz;
    vec3 posCamSpace    = viewMAD(gbufferModelView, posWorldSpace);
    return posCamSpace;
}




vec4 ScreenSpaceToCameraSpace(in vec4 screenSpace){
    const vec4 cameraSpaceProj = gbufferProjectionInverse * screenSpace;
    return cameraSpaceProj/cameraSpaceProj.w;
}

vec4 CameraSpaceToScreenSpace(in vec4 cameraSpace){
    const vec4 screenSpaceProj = gbufferProjection * (cameraSpace);
    return screenSpaceProj/screenSpaceProj.w;
}

vec4 CameraSpaceToModelSpace(in vec4 cameraSpace){
    vec4 modelSpaceProj = gbufferModelViewInverse*cameraSpace;
    modelSpaceProj /= modelSpaceProj.w, modelSpaceProj.xyz /= scaleCoef;
    return modelSpaceProj/modelSpaceProj.w;
}

vec4 ModelSpaceToCameraSpace(in vec4 modelSpace){
    vec4 cameraSpaceProj = gbufferModelView*vec4(modelSpace.xyz,modelSpace.w);
    return cameraSpaceProj/cameraSpaceProj.w*scaleCoef;
}
