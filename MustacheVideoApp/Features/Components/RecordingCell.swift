//
//  RecordingCell.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-20.
//

import Foundation
import SwiftUI
import AVFoundation

struct RecordingCell: View {
    let recording: Recording
    @State private var showVideoPlayer = false
    
    var body: some View {
        Button(action: {
            showVideoPlayer = true
        }) {
            VStack(alignment: .leading) {
                ZStack {
                    if let thumbnailData = recording.thumbnail, let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 120)
                    }
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.tag ?? "Untitled")
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text(timeString(recording.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let date = recording.date {
                            Text(dateFormatter.string(from: date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoPlayerView(recording: recording)
        }
    }
    
    private func timeString(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}
