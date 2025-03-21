//
//  ARViewModel.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import Foundation
import ARKit
import RealityKit

class ARViewModel: NSObject, ObservableObject, ARSessionDelegate {
    let arView = ARView(frame: .zero)
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var lastRecordingURL: URL?
    
    private var mustacheEntity: ModelEntity?
    private var faceAnchor: AnchorEntity?
    private var recordingTimer: Timer?
    private var videoRecorder: ARVideoRecorder?
    
    private let mustacheWidth: Float = 0.08
    private let mustacheHeight: Float = 0.02
    private var currentMustacheName: String = "mustache1"
    
    override init() {
        super.init()
        setupARView()
    }
    
    private func setupARView() {
        arView.session.delegate = self
        
        // creating video recorder
        videoRecorder = ARVideoRecorder(arView: arView)
    }
    
    func checkPermissions() {
           AVCaptureDevice.requestAccess(for: .video) { granted in
               DispatchQueue.main.async {
                   if granted {
                       AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                           DispatchQueue.main.async {
                               if audioGranted {
                                   self.startSession()
                               }
                           }
                       }
                   }
               }
           }
       }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            
            // Start the AR session
            self.arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            // Create face anchor and update UI on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Creating a face anchor
                self.faceAnchor = AnchorEntity(.face)
                self.arView.scene.addAnchor(self.faceAnchor!)
                
                // Adding initial mustache
                self.updateMustache(imageName: self.currentMustacheName)
            }
        }
    }
    
    func stopSession () {
        arView.session.pause()
        
        if isRecording {
            stopRecording()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRecording = false
            }
    }
    
    func updateMustache(imageName: String) {
        if imageName == currentMustacheName && mustacheEntity != nil {
            return
        }
        
        // if there is an existing mustache
        mustacheEntity?.removeFromParent()
        // creating new mustache
        let material = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
        let mustacheMesh = MeshResource.generatePlane(width: mustacheWidth, height: mustacheHeight)
        mustacheEntity = ModelEntity(mesh: mustacheMesh, materials: [material])
        
        // loading the texture
        if let texture = try? TextureResource.load(named: imageName) {
            var material = SimpleMaterial()
            material.baseColor = MaterialColorParameter.texture(texture)
            material.metallic = 0.0
            material.roughness = 1.0
            mustacheEntity?.model?.materials = [material]
        }
        
        // position the mustache
        mustacheEntity?.position = SIMD3<Float>(0, -0.025, 0.06)
        
        // add face to anchor
        faceAnchor?.addChild(mustacheEntity!)
    }
    
    func startRecording() {
        isRecording = true
        recordingDuration = 0
        
        // Start recording timer on main thread
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
        }
        
        // Start video recording on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.videoRecorder?.startRecording()
        }
    }
    
    
    func stopRecording () {
        isRecording = false
        recordingTimer?.invalidate()
        
        videoRecorder?.stopRecording { [weak self] url in
                   guard let self = self, let url = url else { return }
                   self.lastRecordingURL = url
               }
           }
    
    func discardRecording() {
          guard let url = lastRecordingURL else { return }
          
          // Delete recording file
          do {
              try FileManager.default.removeItem(at: url)
              lastRecordingURL = nil
          } catch {
              print("Error deleting recording: \(error)")
          }
      }
}
