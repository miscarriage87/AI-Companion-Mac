//
//  PersistenceController.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData
import SwiftUI

/// Controller for managing Core Data persistence
class PersistenceController {
    /// Shared instance for singleton access
    static let shared = PersistenceController()
    
    /// Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create sample data for previews
        let viewContext = controller.container.viewContext
        
        // Create sample AI provider
        let provider = CDProvider(context: viewContext)
        provider.id = UUID()
        provider.name = "Sample Provider"
        provider.providerDescription = "A sample AI provider for previews"
        provider.apiBaseURL = "https://api.example.com"
        provider.requiresAPIKey = true
        provider.maxContextLength = 4096
        provider.isEnabled = true
        
        // Create sample conversation
        let conversation = CDConversation(context: viewContext)
        conversation.id = UUID()
        conversation.title = "Sample Conversation"
        conversation.createdAt = Date()
        conversation.updatedAt = Date()
        conversation.provider = provider
        
        // Create sample messages
        let userMessage = CDMessage(context: viewContext)
        userMessage.id = UUID()
        userMessage.content = "Hello, AI!"
        userMessage.timestamp = Date().addingTimeInterval(-60)
        userMessage.isFromUser = true
        userMessage.conversation = conversation
        
        let aiMessage = CDMessage(context: viewContext)
        aiMessage.id = UUID()
        aiMessage.content = "Hello! How can I assist you today?"
        aiMessage.timestamp = Date()
        aiMessage.isFromUser = false
        aiMessage.provider = provider
        aiMessage.conversation = conversation
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    /// Core Data persistent container
    let container: NSPersistentContainer
    
    /// Initialize the persistence controller
    /// - Parameter inMemory: Whether to use an in-memory store (for previews)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AICompanion")
        
        // Configure the persistent store
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Get the application support directory
            let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let storeURL = appSupportDir.appendingPathComponent("AICompanion/AICompanion.sqlite")
            
            // Create directory if it doesn't exist
            try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            
            // Configure store description
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
        }
        
        // Load the persistent store
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Handle error
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Configure the view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// Save the view context if there are changes
    /// - Returns: Whether the save was successful
    @discardableResult
    func save() -> Bool {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
                return false
            }
        }
        return true
    }
    
    /// Create a background context for performing operations
    /// - Returns: A new background context
    func backgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    /// Perform a task in a background context
    /// - Parameter task: The task to perform
    func performBackgroundTask(_ task: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(task)
    }
    
    /// Reset the Core Data stack
    func reset() {
        // Delete the persistent store
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            
            // Recreate the persistent store
            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            print("Failed to reset Core Data stack: \(error)")
        }
    }
}
