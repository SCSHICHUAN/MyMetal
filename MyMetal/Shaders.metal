//Model（模型）、View（视图）、Projection（投影）
#include <metal_stdlib>
using namespace metal;

// 输入 shader 和 fragment in/out 共用保证数据机构一致
struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

// 输出
struct VertexOut {
    float4 position [[position]]; //[position]] 语义标注 vertex
    float4 color;
};

// MPV
struct Uniforms {
    float4x4 mvp;
};


vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    //MVP矩阵变换顶点 3D - 2D 输出
    out.position = uniforms.mvp * in.position;
    // 颜色直接传递
    out.color = in.color;
    return out;
}


fragment half4 fragment_main(VertexOut in [[stage_in]]) {
    // Float转Half，适配Metal颜色格式
    return half4(half(in.color.r), half(in.color.g), half(in.color.b), half(in.color.a));
}
