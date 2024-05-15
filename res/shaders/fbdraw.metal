#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position;
    float2 uvs;
};

struct UniformIn {
    float4x4 mvp;
};

struct VertexOut {
    float4 position [[position]];
    float2 uvs;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]], constant VertexIn* vertexData, constant UniformIn& uniform [[buffer(1)]]) {
    VertexOut out;
    out.position = uniform.mvp * float4(
        vertexData[vertexID].position.x,
        vertexData[vertexID].position.y,
        5.0f,
        1.0f
    );

    out.uvs = vertexData[vertexID].uvs;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    const float4 colorSample = tex.sample(textureSampler, float2(in.uvs.x, in.uvs.y));
    return float4(colorSample.rgb, 1);
}

fragment float4 fragment_main_argb(VertexOut in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    const float4 colorSample = tex.sample(textureSampler, float2(in.uvs.x, in.uvs.y));
    return colorSample.argb;
}
