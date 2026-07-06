//
//  MetalRenderer.swift
//  MTLCanvas
//
//  Created by Demian on 20/10/2025.
//

import MetalKit
import MetalPerformanceShaders


public class MetalRenderer: NSObject, MTKViewDelegate {
    // MARK: - Textures
    var lowPPlane:PrimitiveData?
    
    // MARK: - Effects
    var effect = MetalEffect()
    
    public var mtlView: MTKView = {
        let view = MTKView()
        view.device = MetalDevice.shared.device
        view.backgroundColor = .clear
        view.framebufferOnly = false
        view.frame = UIScreen.main.bounds
        view.isOpaque = false
        view.colorPixelFormat = .rgba8Unorm
        return view
    }()
    
    // MARK: - Initialization
    public override init() {
        super.init()
        
        lowPPlane = MetalDevice.shared.makeLowPPlane()
        mtlView.delegate = self
        mtlView.colorPixelFormat = .bgra8Unorm
    }
    
    // MARK: - MTKViewDelegate
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
  
    public func updateLayerTouch(current: SIMD2<Float>, previous: SIMD2<Float>) {
        effect.updateTouch(current: current, previous: previous)
    }

    // MARK: - Compute Draw Calls
    public func draw(in view: MTKView) {
        view.drawableSize = LayoutProp.screenSize
        guard let drawable = view.currentDrawable else { return }
        
        let commandBuffer = MetalDevice.shared.newCommandBuffer()
        let w = drawable.texture.width
        let h = drawable.texture.height
        
        effect.uniforms.resolution = SIMD2<Float>(Float(w), Float(h))
        effect.updateUniforms()
        effect.reloadPipelineIfNeeded()

         if let renderPipelineState = effect.pipeState {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)

            if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                commandEncoder.setRenderPipelineState(renderPipelineState)
                commandEncoder.setFragmentTexture(effect.ping, index: 0)
                commandEncoder.setFragmentBytes(&effect.uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
                commandEncoder.setVertexBuffer(lowPPlane!.vertexBuffer, offset: 0, index: 0)
                commandEncoder.drawIndexedPrimitives(type: .triangle,
                                                  indexCount: lowPPlane!.indexCount,
                                                  indexType: .uint16,
                                                  indexBuffer: lowPPlane!.indexBuffer,
                                                  indexBufferOffset: 0)
                
                commandEncoder.endEncoding()
            }
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
