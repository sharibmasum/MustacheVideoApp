//
//  MustacheVideoAppApp.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import SwiftUI

@main
struct MustacheARApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
