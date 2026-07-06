//
//  MetalEffect.swift
//  MetalBase
//
//  Created by Demian Nezhdanov on 19/07/2025.
//


import MetalKit
import MetalPerformanceShaders





struct MetalEffect{
    
    var pong:MTLTexture?
    var ping:MTLTexture?
    
    var pipeState: MTLRenderPipelineState?
    private var pipelineLibraryRevision = -1
    
    init () {
     
        pong = MetalDevice.texture(LayoutProp.screenSize, pixelFormat: .rgba8Unorm)
        ping = MetalDevice.texture(LayoutProp.screenSize, pixelFormat: .rgba8Unorm)
        uniforms.u_mouse = SIMD2<Float>(0.5, 0.5)
        reloadPipelineIfNeeded()
    }

    mutating func reloadPipelineIfNeeded() {
        let currentRevision = MetalDevice.shared.libraryRevision
        guard pipelineLibraryRevision != currentRevision else { return }

        guard let vertexFunction = MetalDevice.shared.defaultLibrary.makeFunction(name: "bg_vertex") else {
            pipeState = nil
            pipelineLibraryRevision = currentRevision
            print("Failed to reload pipeline: missing bg_vertex function")
            return
        }

        guard let fragmentFunction = MetalDevice.shared.defaultLibrary.makeFunction(name: "bg_second_fragment") else {
            pipeState = nil
            pipelineLibraryRevision = currentRevision
            print("Failed to reload pipeline: missing bg_second_fragment function")
            return
        }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction

        do {
            pipeState = try MetalDevice.shared.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            pipelineLibraryRevision = currentRevision
            print("Reloaded Metal pipeline for shader library revision \(currentRevision)")
        } catch {
            pipeState = nil
            pipelineLibraryRevision = currentRevision
            print("Failed to reload Metal pipeline: \(error)")
        }
    }
  

  
    var uniforms = Uniforms(
       u_time: 0.0,
       size: 0,
       u_mouse: .zero,
       u_pmouse: .zero,
       touchDistance: .zero,
       dir: .zero,
       resolution: .zero
   )
    mutating func updateTouch(current: SIMD2<Float>, previous: SIMD2<Float>) {
        uniforms.u_mouse = current
    }
  
    mutating func updateUniforms(){
        
        uniforms.u_time += 0.01

    }

}




extension MetalRenderer{
   
    
    // MARK: - Animation Updates
    func drawLayer(_ commandBuffer: MTLCommandBuffer, _ drawable: CAMetalDrawable) {
     
         
    
    }
    
    
    
}
