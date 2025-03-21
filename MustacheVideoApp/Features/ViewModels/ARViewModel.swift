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
    @Published var isUsingFrontCamera = true
    
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
        
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        arView.addGestureRecognizer(doubleTapGesture)
    
        videoRecorder = ARVideoRecorder(arView: arView)
    }
    
    @objc private func handleDoubleTap() {
        isUsingFrontCamera.toggle()
        stopSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startSession()
        }
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
            
            self.arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.faceAnchor = AnchorEntity(.face)
                self.arView.scene.addAnchor(self.faceAnchor!)
                
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
        mustacheEntity?.removeFromParent()
        currentMustacheName = imageName
        
        let planeSize = SIMD2<Float>(mustacheWidth, mustacheHeight)
        let planeMesh = MeshResource.generatePlane(width: planeSize.x, height: planeSize.y)
        
        if let texture = try? TextureResource.load(named: imageName) {
            var unlitMaterial = UnlitMaterial()
            unlitMaterial.color = .init(tint: .white.withAlphaComponent(1.0), texture: .init(texture))
            mustacheEntity = ModelEntity(mesh: planeMesh, materials: [unlitMaterial])
            mustacheEntity?.position = SIMD3<Float>(0, -0.025, 0.06)
            faceAnchor?.addChild(mustacheEntity!)
        }
        
        //        if imageName == currentMustacheName && mustacheEntity != nil {
        //                return
        //            }
        //            mustacheEntity?.removeFromParent()
        //            let mustacheMesh = MeshResource.generatePlane(width: mustacheWidth, height: mustacheHeight)
        //
        //            if let texture = try? TextureResource.load(named: imageName) {
        //                var material = SimpleMaterial()
        //                material.color.tint = UIColor(white: 1.0, alpha: 0.0)
        //                material.metallic = 0.0
        //                material.roughness = 1.0
        //                material.blending = .alpha
        //
        //                mustacheEntity = ModelEntity(mesh: mustacheMesh, materials: [material])
        //                mustacheEntity?.position = SIMD3<Float>(0, -0.025, 0.06)
        //                faceAnchor?.addChild(mustacheEntity!)
        //                currentMustacheName = imageName
        //            }
    }
    
    
    func startRecording() {
        isRecording = true
        recordingDuration = 0
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
        }
        
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
        
        do {
            try FileManager.default.removeItem(at: url)
            lastRecordingURL = nil
        } catch {
            print("Error deleting recording: \(error)")
        }
    }
}
