// Shaders.metal 完整代码（一步到位，适配MVP验证）
#include <metal_stdlib>
using namespace metal;

// 1. 顶点输入（和Swift端Vertex结构体一一对应）
struct VertexIn {
    float4 position [[attribute(0)]]; // 对应Swift的position
    float4 color [[attribute(1)]];    // 对应Swift的color
};

// 2. Uniforms
struct Uniforms {
    float4x4 mvp; // 合并后的MVP矩阵，对应Swift端的uniforms
};

// 3. 顶点输出
struct VertexOut {
    float4 position [[position]]; // 最终屏幕坐标
    float4 color;                 // 传递给片元的颜色
};

// 4. 顶点Shader（核心：仅MVP变换）
vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    // 核心：MVP矩阵变换顶点（顺序不能改）
    out.position = uniforms.mvp * in.position;
    // 颜色直接传递
    out.color = in.color;
    return out;
}

// 5. 片元Shader（显示颜色）
fragment half4 fragment_main(VertexOut in [[stage_in]]) {
    // Float转Half，适配Metal颜色格式
    return half4(half(in.color.r), half(in.color.g), half(in.color.b), half(in.color.a));
}
