#version 460 compatibility

uniform sampler2D colortex0;

layout (location = 0) in vec2 vtexcoord;

uniform sampler2D colortex7;
uniform sampler2D colortex3;

/*DRAWBUFFERS:01234567*/

/*
    const int colortex0Format = RGBA32F;
    const int colortex1Format = RGBA32F;
    const int colortex2Format = RGBA32F;
    const int colortex3Format = RGBA32F;
    const int colortex4Format = RGBA32F;
    const int colortex5Format = RGBA32F;
    const int colortex6Format = RGBA32F;
    const int colortex7Format = RGBA32F;

    const bool colortex7Clear = false;
*/

void main() {
	vec2 texcoord = vtexcoord * 0.5f;
	vec2 rtexcoord = vtexcoord * 0.5f;
	rtexcoord.y += 0.5f;

	vec3 sceneColor = texture(colortex0, texcoord, 0).rgb;
		 sceneColor = pow(sceneColor, vec3(1.0/2.2));	//convert color back to display gamma

    float filterRefl = texture(colortex3, texcoord, 0).r;

	vec3 reflColor 	= texture(colortex0, rtexcoord, 0).rgb;
		 reflColor 	= pow(reflColor, vec3(1.0/2.2));	//convert color back to display gamma

	gl_FragData[0] = vec4(mix(sceneColor, reflColor, filterRefl > 0.999f ? vec3(0.5f.xxx) : vec3(0.f.xxx)), 1.0);
    gl_FragData[7] = texture(colortex7, vtexcoord);
    //gl_FragData[0] = vec4(texture(colortex7, vtexcoord).yyy * 0.1f, 1.0);
}
