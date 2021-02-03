vec3 pack2x3(in mat2x3 vcm){
    const mat3x2 tps = transpose(vcm);
    return uintBitsToFloat(uvec3(packHalf2x16(tps[0]),packHalf2x16(tps[1]),packHalf2x16(tps[2])));
}

vec3 pack3x2(in mat3x2 vcm){
    return uintBitsToFloat(uvec3(packHalf2x16(vcm[0]),packHalf2x16(vcm[1]),packHalf2x16(vcm[2])));
}

mat2x3 unpack2x3(in uvec3 pcm){
    return transpose(mat3x2(
        unpackHalf2x16(pcm.x),
        unpackHalf2x16(pcm.y),
        unpackHalf2x16(pcm.z)
    ));
}

mat3x2 unpack3x2(in uvec3 pcm){
    return mat3x2(
        unpackHalf2x16(pcm.x),
        unpackHalf2x16(pcm.y),
        unpackHalf2x16(pcm.z)
    );
}

mat2x3 unpack2x3(in vec3 pcm){
    return unpack2x3(floatBitsToUint(pcm));
}

mat3x2 unpack3x2(in vec3 pcm){
    return unpack3x2(floatBitsToUint(pcm));
}