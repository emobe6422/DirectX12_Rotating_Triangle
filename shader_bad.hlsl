// shader.hlsl
// One shader, several deliberately "bad" variants, picked at compile time by a #define.
// main.cpp passes exactly one VARIANT_* macro based on the command-line argument.
//
//   BASELINE      cheap reference point
//   ALU_HEAVY     long math loop                         -> SM (compute) bound
//   DIVERGENT     per-pixel checkerboard branch          -> every warp runs BOTH paths
//   COHERENT      same work, branch on 64x64 tiles       -> each warp runs ONE path (compare to DIVERGENT)
//   REG_PRESSURE  many live float4s                      -> high registers/thread, low occupancy
//   OVERDRAW      cheap shader, 32 blended full-screen layers (C++ side) -> output/bandwidth bound

cbuffer RootConstants : register(b0)
{
    uint angle; // the root constant set by SetGraphicsRoot32BitConstant (vertex-visible only)
};

struct VSOut
{
    float4 pos : SV_Position;
    float2 uv  : TEXCOORD0;
    float  t   : TEXCOORD1; // time-like value passed to the pixel shader so the compiler can't constant-fold the math
};

// Full-screen triangle generated from the vertex ID (no vertex buffer needed).
// ids 0,1,2 -> one oversized triangle that covers the whole screen, so the pixel
// shader runs once for every pixel. That makes pixel work dominate the frame.
VSOut VSMain(uint id : SV_VertexID)
{
    VSOut o;
    float2 uv = float2((id << 1) & 2, id & 2);                       // (0,0) (2,0) (0,2)
    o.pos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    o.uv  = uv;
    o.t   = angle * 0.01;
    return o;
}

// Two genuinely different heavy functions, so the compiler can't merge the branches.
float heavy_a(float2 p, float t, int iters)
{
    float acc = 0.0;
    [loop] // keep it a real loop (no unrolling) so the cost stays obvious
    for (int i = 0; i < iters; i++)
    {
        p = float2(sin(p.x * 1.7 + t), cos(p.y * 1.3 - t));
        acc += pow(abs(p.x * p.y) + 0.01, 1.5);
    }
    return acc;
}

float heavy_b(float2 p, float t, int iters)
{
    float acc = 0.0;
    [loop]
    for (int i = 0; i < iters; i++)
    {
        p = float2(exp2(frac(p.y * 0.9 + t)), log2(abs(p.x) + 1.1));
        acc += sqrt(abs(p.x - p.y) + 0.02);
    }
    return acc;
}

float4 PSMain(VSOut i) : SV_Target
{
    float2 p = i.uv;
    float  t = i.t;

#if defined(VARIANT_ALU_HEAVY)
    float v = heavy_a(p, t, 256);
    return float4(frac(v), p, 1.0);

#elif defined(VARIANT_DIVERGENT)
    // Neighboring pixels alternate paths, so every warp/wave contains both
    // -> the hardware executes heavy_a AND heavy_b for every warp (masked).
    uint2 px = (uint2)i.pos.xy;
    float v;
    if (((px.x ^ px.y) & 1) != 0) v = heavy_a(p, t, 128);
    else                          v = heavy_b(p, t, 128);
    return float4(frac(v), p, 1.0);

#elif defined(VARIANT_COHERENT)
    // Same work per pixel as DIVERGENT, but the branch flips only every 64x64 pixels
    // -> nearly every warp agrees, so it runs only ONE path. Expect ~half DIVERGENT's time.
    uint2 tile = (uint2)i.pos.xy / 64;
    float v;
    if (((tile.x ^ tile.y) & 1) != 0) v = heavy_a(p, t, 128);
    else                              v = heavy_b(p, t, 128);
    return float4(frac(v), p, 1.0);

#elif defined(VARIANT_REG_PRESSURE)
    // 24 float4s (96 floats) all alive across the loop -> lots of registers per thread
    // -> fewer warps fit on each SM -> lower occupancy.
    float4 v[24];
    [unroll]
    for (int k = 0; k < 24; k++)
        v[k] = float4(p * (k + 1), t + k, 1.0 / (k + 1));

    [loop]
    for (int it = 0; it < 32; it++)
    {
        [unroll]
        for (int k = 0; k < 24; k++)
            v[k] = v[k] * v[(k + 7) % 24].wzyx * 0.5 + v[(k + 3) % 24];
    }

    float4 s = 0;
    [unroll]
    for (int k = 0; k < 24; k++)
        s += v[k];
    return float4(frac(s.xyz), 1.0);

#elif defined(VARIANT_OVERDRAW)
    // Cheap shader; the cost comes from C++ drawing 32 blended layers.
    // Low alpha so every layer must read-modify-write the render target.
    return float4(p, 0.5, 0.05);

#else // VARIANT_BASELINE
    return float4(p, 0.5 + 0.5 * sin(t), 1.0);
#endif
}
