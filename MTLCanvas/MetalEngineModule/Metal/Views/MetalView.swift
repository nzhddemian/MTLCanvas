//
//  MetalView.swift
//  MetalBase
//
//  Created by Demian on 17/09/2025.
//

import SwiftUI

struct MetalView: View {
    @Binding var isActive: Bool
    @StateObject private var metalModel = MetalViewModel()
    
    var body: some View {
        ZStack{
            Rectangle()
                .fill(Color.white)
                .edgesIgnoringSafeArea(.all)
            
            MetalContainer(model: metalModel)
                .frame(width:LayoutProp.screenSize.width, height:LayoutProp.screenSize.height)
                .ignoresSafeArea(.all)
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                metalModel.startDraw()
            } else {
                metalModel.stopDraw()
            }
        }
        .onDisappear {
            metalModel.disposeResources()
        }
    }
}
