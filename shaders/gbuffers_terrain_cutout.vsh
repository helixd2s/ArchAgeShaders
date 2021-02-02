#version 460 compatibility
#extension GL_ARB_shader_viewport_layer_array : require

#define VERTEX_SHADER
#define TEXTURED 
#define SOLID 
#define CUTOUT

#include "stages/solid.glsl"
