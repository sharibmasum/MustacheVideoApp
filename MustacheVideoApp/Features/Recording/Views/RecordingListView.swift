//
//  RecordingListView.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import Foundation
import SwiftUI

struct RecordingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.date, ascending: false)],
        animation: .default)
    private var recordings: FetchedResults<Recording>
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(recordings) { recording in
                    RecordingCell(recording: recording)
                        .contextMenu {
                            Button(action: {
                                deleteRecording(recording)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
    
    private func deleteRecording(_ recording: Recording) {
        if let videoURLString = recording.videoURL {
            let documentsDirectory = FileManager.default.temporaryDirectory
            let fileURL = documentsDirectory.appendingPathComponent(videoURLString)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        viewContext.delete(recording)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting recording: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
