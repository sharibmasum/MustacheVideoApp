//
//  ARVideoRecorder.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import Foundation
import ARKit
import RealityKit


class ARVideoRecorder: NSObject {
    private var arView: ARView
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var captureSession: AVCaptureSession?
    private var audioInput: AVAssetWriterInput?
    private var startTime: CMTime?
    
    init(arView: ARView) {
        self.arView = arView
        super.init()
        setupAudioCapture()
    }
    
    private func setupAudioCapture() {
        captureSession = AVCaptureSession()
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              captureSession?.canAddInput(audioInput) ?? false else {
            return
        }
        
        captureSession?.addInput(audioInput)
    }
    
    func startRecording() {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        
        // Creating asset writer
        do {
            videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        } catch {
            print("Error creating asset writer: \(error)")
            return
        }
        
        // video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: arView.frame.width,
            AVVideoHeightKey: arView.frame.height
        ]
        
        // creating video input
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true
        
        // creating pixel buffer adaptor
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: arView.frame.width,
            kCVPixelBufferHeightKey as String: arView.frame.height
            
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput!,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        // create audio input
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
                     AVSampleRateKey: 44100,
                     AVNumberOfChannelsKey: 2
        ]
        
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput?.expectsMediaDataInRealTime = true
        
        // add inputs to writer
        if videoWriter?.canAdd(videoWriterInput!) ?? false {
            videoWriter?.add(videoWriterInput!)
        }
        
        if videoWriter?.canAdd(audioInput!) ?? false {
            videoWriter?.add(audioInput!)
        }
        
        // Start recording
        videoWriter?.startWriting()
        videoWriter?.startSession(atSourceTime: CMTime.zero)
        startTime = CMTime.zero
        captureSession?.startRunning()
        arView.session.delegate = self
        
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        // Stop capturing
        captureSession?.stopRunning()
        
        // Finish writing
        videoWriterInput?.markAsFinished()
        audioInput?.markAsFinished()
        
        videoWriter?.finishWriting { [weak self] in
            guard let self = self else { return }
            completion(self.videoWriter?.outputURL)
        }
    }
}

extension ARVideoRecorder: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let videoWriterInput = videoWriterInput,
              let pixelBufferAdaptor = pixelBufferAdaptor,
              videoWriterInput.isReadyForMoreMediaData else {
            return
        }
    
        // get pixel buffer from the current frame and getting time stamp
        let pixelBuffer = frame.capturedImage
        let timestamp = CMTime(seconds: frame.timestamp, preferredTimescale: 600)
        
        // write the pixel buffer
        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: timestamp)
    }
}

