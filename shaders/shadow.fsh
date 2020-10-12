#version 460 compatibility

uniform sampler2D tex;

layout (location = 0) in vec2 texcoord;
layout (location = 1) in vec4 color;

void main() {
    gl_FragColor    = texture2D(tex, texcoord)*color;
}
