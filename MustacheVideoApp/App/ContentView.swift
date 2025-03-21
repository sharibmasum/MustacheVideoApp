//
//  ContentView.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingRecordingScreen = false
    
    var body: some View {
        NavigationView {
            RecordingListView()
                .navigationTitle("Mustache AR")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action : {
                            isShowingRecordingScreen = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                        }
                    }
                }
                .fullScreenCover(isPresented: $isShowingRecordingScreen) {
                                 VideoRecordingView()
                }
        }
    }
}

#Preview {
    ContentView()
}
