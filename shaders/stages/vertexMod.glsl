{
    float deferW = gl_Position.w;
    gl_Position /= deferW;
    
    // 
    gl_Position.xy = gl_Position.xy * 0.5f + 0.5f;

    // split screen 
    gl_Position.xy *= 0.5f;

    // filter instance (sado guru)
    if (instanceId == 1) {
        gl_Position.y += 0.5f;
    };

    // 
    gl_Position.xy = gl_Position.xy * 2.f - 1.f;
    gl_Position *= deferW;
}
