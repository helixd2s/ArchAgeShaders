// sea
#define SEA_HEIGHT 0.3 // [0.1 0.2 0.3 0.4 0.5]

#define WATER_ITERATIONS 6

#define WATER_PARALLAX



uniform sampler2D noisetex;

float hash(float n) { return fract(sin(n) * 43758.5453123); }

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.2031);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 x) {
	const vec2 step = vec2(110, 241);

	vec2 i = floor(x);
	vec2 f = fract(x);
 
	// For performance, compute the base input to a 1D hash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix( hash(n + dot(step, vec2(0, 0))), hash(n + dot(step, vec2(1, 0))), u.x),
               mix( hash(n + dot(step, vec2(0, 1))), hash(n + dot(step, vec2(1, 1))), u.x), u.y) * 2.0 - 1.0;
}

#ifdef USE_HALF
float16_t hash16(f16vec2 n) { 
	return fract(sin(dot(n, f16vec2(12.9898, 4.1414))) * float16_t(43758.5453));
}

float16_t noise16(f16vec2 p){
	f16vec2 ip = floor(p);
	f16vec2 u = fract(p);
	u = u * u * (float16_t(3.0) - float16_t(2.0) * u);
	
	float16_t res = mix(
		mix(hash16(ip                    ), hash16(ip + f16vec2(1.0, 0.0)), u.x),
		mix(hash16(ip + f16vec2(0.0, 1.0)), hash16(ip + f16vec2(1.0, 1.0)), u.x), u.y);
	return res * res;
}
#else
#define hash16 hash
#define noise16 noise
#endif

float noise(vec3 x) {
	const vec3 step = vec3(110, 241, 171);

	vec3 i = floor(x);
	vec3 f = fract(x);
 
	// For performance, compute the base input to a 1D hash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

float Halton(int b, int i) {
    float r = 0.0;
    float f = 1.0;
    while (i > 0) {
        f = f / float(b);
        r = r + f * float(i % b);
        i = int(floor(float(i) / float(b)));
    }
    return r;
}

float noise_tex(in vec2 p) {
	return fma(texture2D(noisetex, fract(p * 0.0050173)).r, 2.0, -1.0);
}

float bayer2(vec2 a){
    a = floor(a);
    return fract( dot(a, vec2(.5f, a.y * .75f)) );
}

#define bayer4(a)   (bayer2( .5f*(a))*.25f+bayer2(a))
#define bayer8(a)   (bayer4( .5f*(a))*.25f+bayer2(a))
#define bayer16(a)  (bayer8( .5f*(a))*.25f+bayer2(a))
#define bayer32(a)  (bayer16(.5f*(a))*.25f+bayer2(a))
#define bayer64(a)  (bayer32(.5f*(a))*.25f+bayer2(a))

float bayer_4x4(in vec2 pos, in vec2 view) {
	return bayer4(pos * view);
}

float bayer_8x8(in vec2 pos, in vec2 view) {
	return bayer8(pos * view);
}

float bayer_16x16(in vec2 pos, in vec2 view) {
	return bayer16(pos * view);
}

float bayer_32x32(in vec2 pos, in vec2 view) {
	return bayer32(pos * view);
}

float bayer_64x64(in vec2 pos, in vec2 view) {
	return bayer64(pos * view);
}

const vec2 poisson_12[12] = vec2 [] (
	vec2(-0.326212, -0.40581),
	vec2(-0.840144, -0.07358),
	vec2(-0.695914,  0.457137),
	vec2(-0.203345,  0.620716),
	vec2(0.96234,   -0.194983),
	vec2(0.473434,  -0.480026),
	vec2(0.519456,   0.767022),
	vec2(0.185461,  -0.893124),
	vec2(0.507431,   0.064425),
	vec2(0.89642,    0.412458),
	vec2(-0.32194,  -0.932615),
	vec2(-0.791559, -0.59771)
);

const vec2 poisson_4[4] = vec2 [] (
	vec2(-0.94201624, -0.39906216 ),
	vec2( 0.94558609, -0.76890725 ),
	vec2(-0.09418410, -0.92938870 ),
	vec2( 0.34495938,  0.29387760 )
);

float sea_octave_micro(vec2 fuv, float choppy) {
	fuv += noise(fuv);
	vec2 wv = 1.0-abs(sin(fuv));
	vec2 swv = abs(cos(fuv));
	wv = mix(wv,swv,wv);
	return pow(1.0-pow(wv.x * wv.y,0.75),choppy);
}

const float SEA_CHOPPY = 5.5;
const float SEA_SPEED = 5.3;
const float SEA_FREQ = 0.08;
const mat2 octave_m = mat2(1.4,1.1,-1.2,1.4);

const float height_mul[6] = float[6] (
	0.6, 0.4, 0.3, 0.2, 0.1, 0.1
);

uniform float frameTimeCounter;

float getwave(vec3 p, in float lod, int iterations) {
	float freq = SEA_FREQ;
	float amp = 1.0;
	float choppy = SEA_CHOPPY;
	vec2 fuv = p.xz * 2.0 - p.y * 2.0 - frameTimeCounter * vec2(0.1, 0.5); fuv.x *= 0.75;

	float wave_speed = frameTimeCounter * SEA_SPEED;
    float total_height = 1.0;

	float d, h = 0.0;
	for(int i = 0; i < iterations * lod; i++) {
		d = sea_octave_micro((fuv+wave_speed * vec2(0.1, 0.9))*freq,choppy);

        if (i + 1 >= iterations * lod)
        {
            amp *= fract(iterations * lod);
        }

		h += d * amp;
		fuv *= octave_m; freq *= 1.8; amp *= height_mul[i]; //wave_speed *= 0.5;
		choppy = mix(choppy,1.0,0.2);

        total_height += amp;
	}

	return (h / total_height * SEA_HEIGHT - SEA_HEIGHT);
}

float getpeaks(vec3 p, in float lod, int min_iter, int iterations) {
	float freq = SEA_FREQ;
	float16_t amp = 1.0;
	float choppy = SEA_CHOPPY;
	vec2 fuv = p.xz * 2.0 - p.y * 2.0 - frameTimeCounter * vec2(0.1, 0.5); fuv.x *= 0.75;

	float wave_speed = frameTimeCounter * SEA_SPEED;
    float16_t total_height = 1.0;

	float16_t h = float16_t(0.0);
	for(int i = 0; i < iterations * lod; i++) {
		float16_t d = float16_t(sea_octave_micro((fuv+wave_speed * vec2(0.1, 0.9))*freq,choppy));

        if (i + 1 >= iterations * lod)
        {
            amp *= fract(float16_t(iterations * lod));
        }

        if (i >= min_iter)
        {
    		h += smoothstep(float16_t(0.95), float16_t(1.0), d) * amp;
        }
	
    	fuv *= octave_m; freq *= 1.9; amp *= float16_t(height_mul[i]); //wave_speed *= 0.5;
		choppy = mix(choppy,1.0,0.2);

        total_height += amp;
	}

	return float(h / total_height);
}

vec3 get_water_normal(in vec3 wwpos, in float lod, in vec3 N, in vec3 T, in vec3 B) {
	vec3 w1 = 0.002 * T + getwave(wwpos + 0.002 * T, lod, WATER_ITERATIONS) * N;
	vec3 w2 = 0.002 * B + getwave(wwpos + 0.002 * B, lod, WATER_ITERATIONS) * N;
	vec3 w0 = getwave(wwpos, lod, WATER_ITERATIONS) * N;
	return normalize(cross(w2 - w0, w1 - w0));
}