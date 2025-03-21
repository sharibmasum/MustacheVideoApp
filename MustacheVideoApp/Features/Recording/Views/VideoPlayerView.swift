//
//  VideoPlayerView.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-20.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let recording: Recording
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var showControls = true
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showControls.toggle()
                        }
                    }
            } else {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                    )
            }
            
            if showControls {
                VStack {
                    HStack {
                        Spacer()
                        Text(recording.tag ?? "Untitled")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            player?.pause()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 20)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Slider(value: $currentTime, in: 0...(duration == 0 ? 100 : duration), onEditingChanged: sliderEditingChanged)
                            .accentColor(.white)
                            .padding(.horizontal)
                        
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: togglePlayPause) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Duration
                            Text(formatTime(duration))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .background(LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .onReceive(timer) { _ in
            updatePlayerTime()
        }
    }
    
    private func setupPlayer() {
        guard let videoURLString = recording.videoURL else { return }
        
        let documentsDirectory = FileManager.default.temporaryDirectory
        let fileURL = documentsDirectory.appendingPathComponent(videoURLString)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            player = AVPlayer(url: fileURL)
            
            let playerItem = player?.currentItem
            if let duration = playerItem?.asset.duration {
                self.duration = CMTimeGetSeconds(duration)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.showControls = false
                }
            }
            
            player?.play()
            isPlaying = true
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main) { _ in
                    self.player?.seek(to: CMTime.zero)
                    self.currentTime = 0
                    self.isPlaying = false
                }
        }
    }
    
    private func updatePlayerTime() {
        guard let player = player, isPlaying else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        self.currentTime = currentTime
    }
    
    private func sliderEditingChanged(editing: Bool) {
        if editing {
            player?.pause()
            isPlaying = false
        } else {
            let targetTime = CMTime(seconds: currentTime, preferredTimescale: 600)
            player?.seek(to: targetTime)
            
            player?.play()
            isPlaying = true
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
