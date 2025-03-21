//
//  ARViewContainer.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import Foundation
import SwiftUI
import ARKit
import RealityKit


struct ARViewContainer: UIViewRepresentable {
    var arViewModel: ARViewModel
    var currentMustache: String
    
    func makeUIView(context: Context) -> ARView {
        return arViewModel.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        arViewModel.updateMustache(imageName: currentMustache)
    }
}
