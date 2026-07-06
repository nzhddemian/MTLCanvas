//
//  MetalContainer.swift
//  MTLCanvas
//
//  Created by Demian on 20/10/2025.
//


import SwiftUI
import UIKit



public struct MetalContainer: UIViewRepresentable {
    var model: MetalViewModel
    
    
    public init(model: MetalViewModel) {
        self.model = model
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = model.mtlView
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        view.addGestureRecognizer(panGesture)
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        print("update MTLView")
    }

    public final class Coordinator: NSObject {
        private let model: MetalViewModel

        init(model: MetalViewModel) {
            self.model = model
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            let currentLocation = SIMD2<Float>(
                Float(location.x),
                Float(location.y)
            )

            model.updateDrawTouch(
                current: currentLocation,
                in: gesture.view?.bounds.size ?? LayoutProp.screenSize
            )
        }
    }
}
