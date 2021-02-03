vec3 pack2x3(in mat2x3 vcm){
    const mat3x2 tps = transpose(vcm);
    return vec3(uintBitsToFloat(packHalf2x16(tps[0])),uintBitsToFloat(packHalf2x16(tps[1])),uintBitsToFloat(packHalf2x16(tps[2])));
}

vec3 pack3x2(in mat3x2 vcm){
    return vec3(uintBitsToFloat(packHalf2x16(vcm[0])),uintBitsToFloat(packHalf2x16(vcm[1])),uintBitsToFloat(packHalf2x16(vcm[2])));
}

mat2x3 unpack2x3(in vec3 pcm){
    return transpose(mat3x2(
        unpackHalf2x16(floatBitsToUint(pcm.x)),
        unpackHalf2x16(floatBitsToUint(pcm.y)),
        unpackHalf2x16(floatBitsToUint(pcm.z))
    ));
}

mat3x2 unpack3x2(in vec3 pcm){
    return mat3x2(
        unpackHalf2x16(floatBitsToUint(pcm.x)),
        unpackHalf2x16(floatBitsToUint(pcm.y)),
        unpackHalf2x16(floatBitsToUint(pcm.z))
    );
}
