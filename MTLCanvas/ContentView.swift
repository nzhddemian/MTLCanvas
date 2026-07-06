//
//  ContentView.swift
//  MTLCanvas
//
//  Created by demian on 7/5/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var metalModel = MetalViewModel()
    var body: some View {
        VStack {
            MetalContainer(model: metalModel)
                .frame(width:LayoutProp.screenSize.width, height:LayoutProp.screenSize.height)
                .ignoresSafeArea(.all)
        }
      
        .onDisappear {
            metalModel.disposeResources()
        }
    }
}
