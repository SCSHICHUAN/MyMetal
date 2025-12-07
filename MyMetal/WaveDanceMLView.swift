//
//  WaveDanceMLView.swift
//  MyMetal
//
//  Created by Stan on 2025/12/7.
//

import Metal
import MetalKit
import simd

class WaveDanceMLView: MTKView {
    
    // MARK: - Metal 核心组件
    private var metalCommandQueue: MTLCommandQueue!
    private var metalPipelineState: MTLRenderPipelineState!
    
    // MARK: - 顶点和 Uniform
    struct Vertex {
        var position: SIMD4<Float>
        var color: SIMD4<Float>
    }
    
    struct Uniforms {
        var mvp: float4x4
    }
    
    private let triangleVertices: [Vertex] = [
        Vertex(position: [0, 1, 0, 1], color: [1, 0, 0, 1]),
        Vertex(position: [-1, -1, 0, 1], color: [0, 1, 0, 1]),
        Vertex(position: [1, -1, 0, 1], color: [0, 0, 1, 1])
    ]
    
    private var rotation: Float = 0
    // 暴露相机供ViewController访问
    public let camera = Camera(position: [0, 0, 5])
    
    // MARK: - 指定初始化器
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        if device == nil {
            device = MTLCreateSystemDefaultDevice()
        }
        commonInit()
    }
    
    private func commonInit() {
        guard device != nil else {
            fatalError("当前设备不支持 Metal！")
        }
        
        // MTKView 配置
        colorPixelFormat = .bgra8Unorm
        framebufferOnly = false
        enableSetNeedsDisplay = true // 开启手动刷新
        isPaused = false
        delegate = self
        preferredFramesPerSecond = 60
        
        setupMetal()
        setupRenderPipeline()
    }
    
    // MARK: - Metal 初始化
    private func setupMetal() {
        guard let device = device else { return }
        metalCommandQueue = device.makeCommandQueue()
    }
    
    // MARK: - 渲染管线创建
    private func setupRenderPipeline() {
        guard let device = device else { return }
        guard let library = device.makeDefaultLibrary() else {
            fatalError("无法加载默认 Metal 库")
        }
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = library.makeFunction(name: "vertex_main")
        pipelineDesc.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineDesc.colorAttachments[0].pixelFormat = colorPixelFormat
        
        // 顶点描述符
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        pipelineDesc.vertexDescriptor = vertexDescriptor
        
        do {
            metalPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            fatalError("创建渲染管线失败: \(error)")
        }
    }
    
    // MARK: - 实时计算MVP并绘制（核心：每次绘制都用最新相机参数）
    private func drawTriangle(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(metalPipelineState)
        
        // 1. 传入顶点数据
        renderEncoder.setVertexBytes(triangleVertices,
                                     length: MemoryLayout<Vertex>.stride * triangleVertices.count,
                                     index: 0)
        
        // 2. 实时更新旋转角度
        rotation += 0.01
        
        // 3. 实时计算MVP（每次都用最新的相机参数）
        // Model：Y轴旋转
        var model = float4x4.identity()
        model = model * float4x4.rotate(angle: rotation, axis: SIMD3<Float>(0, 1, 0))
        // View：最新的相机视角
        let view = camera.getViewMatrix()
        // Projection：适配当前屏幕的透视矩阵
        let aspect = Float(drawableSize.width / drawableSize.height)
        let projection = float4x4.perspective(fovY: radians(camera.zoom), aspect: aspect, near: 0.1, far: 100)
        // 合并MVP（核心：每次绘制都重新算）
        let mvp = projection * view * model
        
        // 4. 传入最新的MVP
        var uniforms = Uniforms(mvp: mvp)
        renderEncoder.setVertexBytes(&uniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: 1)
        
        // 5. 绘制
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }
    
    // 供外部调用的刷新方法
    public func refreshRender() {
        setNeedsDisplay()
    }
}

// MARK: - MTKViewDelegate（确保每一帧都重新绘制）
extension WaveDanceMLView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = currentDrawable,
              let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderPassDescriptor = currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        // 清空背景（便于观察）
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        // 绘制（每次都用最新MVP）
        drawTriangle(renderEncoder: renderEncoder)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
