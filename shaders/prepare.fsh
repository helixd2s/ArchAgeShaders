#version 460 compatibility

uniform sampler2D colortex7;

layout (location = 0) in vec2 vtexcoord;

/*DRAWBUFFERS:7*/

void main() {
	if (texture(colortex7, vtexcoord).y <= 0.f) {
        gl_FragData[0] = vec4(0.f, 63.f - 2.f/16.f, 0.f, 1.f);
    } else 
    {
        gl_FragData[0] = texture(colortex7, vtexcoord);
    }
}
