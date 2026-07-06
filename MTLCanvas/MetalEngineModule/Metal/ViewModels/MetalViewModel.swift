//
//  MetalViewModel.swift
//  MTLCanvas
//
//  Created by Demian on 07/10/2025.
//

import SwiftUI
import MetalKit
import Combine


/// View model managing the Metal renderer.
public class MetalViewModel: ObservableObject {
    private var lastTouchLocation: SIMD2<Float>? = nil
    var renderer: MetalRenderer?
    var isActive: Bool {
        didSet(val){
            val ? startDraw() : stopDraw()
        }
    }
    public var mtlView: MTKView {
        get { renderer!.mtlView }
        set (newVal){ renderer!.mtlView = newVal }
    }
    
    public init() {
        
        renderer = MetalRenderer()
        isActive = true
        
    }
    
    public func startDraw(){
        mtlView.isPaused = false
    }
    public func stopDraw(){
        mtlView.isPaused = true
    }
    
    public func updateDrawTouch(current: SIMD2<Float>, in size: CGSize = LayoutProp.screenSize) {
        let normalizedCurrent = SIMD2<Float>(
            current.x / Float(size.width),
            current.y / Float(size.height)
        )
        renderer?.updateLayerTouch(current: normalizedCurrent, previous: normalizedCurrent)
    }
    public func disposeResources() {
        mtlView.isPaused = true
//        renderer?.disposeResources()
        
        renderer = nil
    }
    
    
}

