// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash( in uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

// Compound versions of the hashing algorithm I whipped together.
uint hash( in uvec2 v ) { return hash( v.x ^ hash(v.y)                         ); }
uint hash( in uvec3 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z)             ); }
uint hash( in uvec4 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }

// Construct a float with half-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
float floatConstruct( in uint m ) {
    return fract(uintBitsToFloat((m&0x007FFFFFu)|0x3F800000u)-1.0f);
}

highp vec2 halfConstruct ( in uint m ) { return fract(unpackHalf2x16((m & 0x03FF03FFu) | (0x3C003C00u))-1.f); };

// Pseudo-random value in half-open range [0:1].
float random( in float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random( in vec2  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( in vec3  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( in vec4  v ) { return floatConstruct(hash(floatBitsToUint(v))); }


highp vec2 randomH2( in float x ) { return halfConstruct(hash(floatBitsToUint(x))); }
highp vec2 randomH2( in vec2  v ) { return halfConstruct(hash(floatBitsToUint(v))); }
highp vec2 randomH2( in vec3  v ) { return halfConstruct(hash(floatBitsToUint(v))); }
highp vec2 randomH2( in vec4  v ) { return halfConstruct(hash(floatBitsToUint(v))); }



#ifdef EXPERIMENTAL_UNORM16_DIRECTION
#define dirtype_t float
#define dirtype_t_decode(f) unpackUnorm2x16(floatBitsToUint(f)).yx
#define dirtype_t_encode(f) uintBitsToFloat(packUnorm2x16(f.yx))
#else
#define dirtype_t uvec2
#define dirtype_t_decode(f) uintBitsToFloat(f)
#define dirtype_t_encode(f) floatBitsToUint(f)
#endif


const float INV_TWO_PI = 1.f/3.141592f;
const float TWO_PI = 2.f * 3.141592f;
const float PI = 3.141592f;
const float INV_PI = 1.f/3.141592f;

dirtype_t lcts(in vec3 direct) { return dirtype_t_encode(vec2(fma(atan(direct.z,direct.x),INV_TWO_PI,0.5f),acos(-direct.y)*INV_PI)); };
     vec3 dcts(in vec2 hr) { hr = fma(hr,vec2(TWO_PI,PI),vec2(-PI,0.f)); const float up=-cos(hr.y),over=sqrt(fma(up,-up,1.f)); return vec3(cos(hr.x)*over,up,sin(hr.x)*over); };
     vec3 dcts(in dirtype_t hr) { return dcts(dirtype_t_decode(hr)); };

vec3 randomHemisphereCosine(in vec3 seeds) {
    const vec2 hmsm = vec2(halfConstruct(hash(floatBitsToUint(seeds))));
    const float phi = hmsm.x * TWO_PI, up = sqrt(1.0f - hmsm.y), over = sqrt(fma(up,-up,1.f));
    return vec3(cos(phi)*over, up, sin(phi)*over);
}

vec3 randomSphere(in vec3 seeds) { return dcts(halfConstruct(hash(floatBitsToUint(seeds)))); };
