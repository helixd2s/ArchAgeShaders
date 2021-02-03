#version 460 compatibility
#extension GL_NV_viewport_array2 : require

#define VERTEX_SHADER
#define TEXTURED 
#define SOLID 
#define EARLY_FRAG_TEST

#include "stages/solid.glsl"
