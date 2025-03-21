//
//  VIdeoRecordingView.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import Foundation
import SwiftUI
import ARKit

struct VideoRecordingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var arViewModel = ARViewModel()
    @State private var showingSaveDialog = false
    @State private var recordingTag = ""
    @State private var currentMustacheIndex = 0
    
    let mustacheOptions = ["mustache1", "mustache2", "mustache3"]
    
    var body: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel, currentMustache: mustacheOptions[currentMustacheIndex])
                .edgesIgnoringSafeArea(.all)
        
            
            VStack {
                Spacer()
                
                //mustache scroll view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach (0..<mustacheOptions.count, id: \.self) { index in
                            Button(action: {
                                currentMustacheIndex = index
                            }) {
                                Image(mustacheOptions[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height:40)
                                    .padding(8)
                                    .background(currentMustacheIndex == index ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 70)
                .background(Color.black.opacity(0.5))
                
                
                
                
            }
            
            HStack {
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    if arViewModel.isRecording {
                        arViewModel.stopRecording()
                        showingSaveDialog = true
                    } else {
                        arViewModel.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .fill(arViewModel.isRecording ? Color.red : Color.red.opacity(0.7))
                            .frame(width: 60, height: 60)
                    }
                }
                
                Spacer()

                
                Button(action: {
                    arViewModel.stopSession()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: 30)
            .padding(.horizontal, 30)
            .offset(y: 250)
            
            
            
            if arViewModel.isRecording {
                VStack  {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(timeString(arViewModel.recordingDuration))
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    
                    Spacer()
                }
                .padding(.top, 50)
            }
        }
        .overlay(
            Group {
                if showingSaveDialog {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Text("Save Your Recording")
                                .font(.headline)
                            
                            TextField("Enter tag...", text: $recordingTag)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            
                            HStack {
                                Button("Cancel") {
                                    showingSaveDialog = false
                                    arViewModel.discardRecording()
                                }
                                .padding()
                                .foregroundColor(.red)
                                
                                Spacer()
                                
                                Button("Save") {
                                    saveRecording()
                                    showingSaveDialog = false
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .padding()
                                .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    }
                }
            }
        )
        .onAppear {
            arViewModel.checkPermissions()
        }
        .onDisappear {
            arViewModel.stopSession()
        }
        
    }
    
    
    private func saveRecording() {
        guard let videoURL = arViewModel.lastRecordingURL else { return }
        var thumbnail = ThumbnailGenerator.snapshotFromARView(arViewModel.arView) // something wrong here
        
        let newRecording = Recording(context: viewContext)
        newRecording.id = UUID()
        newRecording.videoURL = videoURL.lastPathComponent
        newRecording.duration = arViewModel.recordingDuration
        newRecording.tag = recordingTag.isEmpty ? "Untitled" : recordingTag
        newRecording.date = Date()
        
        if let thumbnail = thumbnail, let imageData = thumbnail.jpegData(compressionQuality: 0.7) {
            newRecording.thumbnail = imageData
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving recording: \(error)")
        }
        
    }

    private func timeString(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


#Preview {
    ContentView()
}
