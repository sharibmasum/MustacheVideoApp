//
//  PersistenceController.swift
//  MustacheVideoApp
//
//  Created by sharib masum on 2025-03-18.
//

import Foundation
import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory:Bool = false) {
        container = NSPersistentContainer(name: "MustacheModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error loading core data ")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
    }
    
    static var preview: PersistenceController = {
           let controller = PersistenceController(inMemory: true)
           
           // Create 10 sample recordings for previews
           let viewContext = controller.container.viewContext
           for i in 0..<5 {
               let newRecording = Recording(context: viewContext)
               newRecording.id = UUID()
               newRecording.tag = "Sample Recording \(i+1)"
               newRecording.duration = Double(60 + i*30) // 1:00, 1:30, etc.
               newRecording.date = Date().addingTimeInterval(-Double(i) * 86400) // Days ago
           }
           
           do {
               try viewContext.save()
           } catch {
               fatalError("Error creating preview data: \(error)")
           }
           
           return controller
       }()
    
}
