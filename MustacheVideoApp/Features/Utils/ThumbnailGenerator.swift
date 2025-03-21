//
//  ThumbnailGenerator.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-20.
//

import UIKit
import AVFoundation
import ARKit
import RealityKit

class ThumbnailGenerator {
    static func snapshotFromARView(_ arView: ARView) -> UIImage? {
        var capturedImage: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        

        arView.snapshot(saveToHDR: false) { image in
            capturedImage = image
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 1.0)
        
        return capturedImage
    }

}
