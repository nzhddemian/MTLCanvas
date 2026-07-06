//
//  MetalEffect.metal
//  MetalBase
//
//  Created by Demian Nezhdanov on 21/06/2025.
//


#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 textureCoorinates [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoorinates;
};

struct Uniforms {
    float u_time;
    float size;
    float2 u_mouse;
    float2 u_pmouse;
    float touchDistance;
    float2 dir;
    float2 resolution;
};

constexpr sampler sam(filter::linear, address::clamp_to_zero);
#define clp(x) clamp(x, 0.0, 1.0)

float3 palett(float v) {
    return float3(0.26) + tan(1.09) * sin(1.09) * 0.26 * cos(3.28318 * (v + float3(0.0, 0.333, 0.667)));
}

vertex float4 bg_vertex(constant VertexIn* vertexArray [[buffer(0)]],
                        uint vid [[vertex_id]]) {
    VertexIn vertexData = vertexArray[vid];
    return float4(vertexData.position, 1.0);
}

float spot(float2 uv, float ratio, float2 pos, float scale) {
    pos.x *= ratio;
    uv.x *= ratio;
    float d = length(uv - pos);
    d = smoothstep(scale, 0., d);
    return d;
}

float hash21(float2 p) {
    p = 50.0 * fract(p * 0.3183099 + float2(0.71, 0.113));
    return float2(-1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y))).x;
}

float noise11(float x) {
    float fractX = fract(x);
    float intX = floor(x);
    float r0 = fract(sin(intX) * 43758.5453);
    float r1 = fract(sin(intX + 1.0) * 43758.5453);
    return mix(r0, r1, fractX);
}

float noise21(float2 p, float u_time) {
    float2 ip = floor(p + (u_time / 21.));
    float2 u = fract(p + (u_time / 21.));
    u = u * u * (3.0 - 2.0 * u);
    
    float res = mix(
        mix(hash21(ip), hash21(ip + float2(1.0, 0.0)), u.x),
        mix(hash21(ip + float2(0.0, 1.0)), hash21(ip + float2(1.0, 1.0)), u.x), u.y);
    return res * res;
}


fragment half4 bg_second_fragment(float4 fragCoord [[position]],
                                   
                                   constant Uniforms &uniforms [[buffer(0)]]) {
   
    half2 uv = half2(fragCoord.xy / uniforms.resolution);
    half ratio = half(uniforms.resolution.x / uniforms.resolution.y);
    half2 m = half2(uniforms.u_mouse);
    half u_time = half(uniforms.u_time);
    float d = length(uv-m);
    d = smoothstep(0.1, 0.5, d);
    half4 final = half4(d);
//    final.r = 0.0;
    final.b = 0.0;
    return half4(final);
}
