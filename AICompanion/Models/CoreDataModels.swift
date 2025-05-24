//
//  CoreDataModels.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData

/// Core Data entity for Conversation
@objc(CDConversation)
public class CDConversation: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var messages: NSSet
    @NSManaged public var provider: CDProvider
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> Conversation {
        let messagesArray = (messages.allObjects as? [CDMessage] ?? [])
            .sorted { $0.timestamp < $1.timestamp }
            .map { $0.toDomainModel() }
        
        return Conversation(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: messagesArray,
            aiProviderId: provider.id
        )
    }
    
    /// Update Core Data entity from domain model
    func update(from model: Conversation, in context: NSManagedObjectContext) {
        self.title = model.title
        self.updatedAt = model.updatedAt
        
        // Provider is handled separately
    }
}

/// Core Data entity for Message
@objc(CDMessage)
public class CDMessage: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var content: String
    @NSManaged public var timestamp: Date
    @NSManaged public var isFromUser: Bool
    @NSManaged public var conversation: CDConversation
    @NSManaged public var provider: CDProvider?
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> Message {
        return Message(
            id: id,
            content: content,
            timestamp: timestamp,
            isFromUser: isFromUser,
            aiProviderId: provider?.id
        )
    }
    
    /// Update Core Data entity from domain model
    func update(from model: Message) {
        self.content = model.content
        self.timestamp = model.timestamp
        self.isFromUser = model.isFromUser
        
        // Provider and conversation are handled separately
    }
}

/// Core Data entity for AI Provider
@objc(CDProvider)
public class CDProvider: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var providerDescription: String
    @NSManaged public var apiBaseURL: String
    @NSManaged public var requiresAPIKey: Bool
    @NSManaged public var maxContextLength: Int32
    @NSManaged public var isEnabled: Bool
    @NSManaged public var models: NSSet?
    @NSManaged public var conversations: NSSet?
    @NSManaged public var messages: NSSet?
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> AIProvider {
        let modelsArray = (models?.allObjects as? [CDModel] ?? [])
            .map { $0.toDomainModel() }
        
        return AIProvider(
            id: id,
            name: name,
            description: providerDescription,
            apiBaseURL: URL(string: apiBaseURL) ?? URL(string: "https://api.example.com")!,
            requiresAPIKey: requiresAPIKey,
            availableModels: modelsArray,
            maxContextLength: Int(maxContextLength),
            isEnabled: isEnabled
        )
    }
    
    /// Update Core Data entity from domain model
    func update(from model: AIProvider) {
        self.name = model.name
        self.providerDescription = model.description
        self.apiBaseURL = model.apiBaseURL.absoluteString
        self.requiresAPIKey = model.requiresAPIKey
        self.maxContextLength = Int32(model.maxContextLength)
        self.isEnabled = model.isEnabled
        
        // Models are handled separately
    }
}

/// Core Data entity for AI Model
@objc(CDModel)
public class CDModel: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var modelId: String
    @NSManaged public var displayName: String
    @NSManaged public var modelDescription: String
    @NSManaged public var maxContextLength: Int32
    @NSManaged public var supportsStreaming: Bool
    @NSManaged public var costPerInputToken: Double
    @NSManaged public var costPerOutputToken: Double
    @NSManaged public var provider: CDProvider
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> AIModel {
        return AIModel(
            id: id,
            modelId: modelId,
            displayName: displayName,
            description: modelDescription,
            maxContextLength: Int(maxContextLength),
            supportsStreaming: supportsStreaming,
            costPerInputToken: costPerInputToken,
            costPerOutputToken: costPerOutputToken
        )
    }
    
    /// Update Core Data entity from domain model
    func update(from model: AIModel) {
        self.modelId = model.modelId
        self.displayName = model.displayName
        self.modelDescription = model.description
        self.maxContextLength = Int32(model.maxContextLength)
        self.supportsStreaming = model.supportsStreaming
        self.costPerInputToken = model.costPerInputToken
        self.costPerOutputToken = model.costPerOutputToken
    }
}

// MARK: - Extensions for Fetched Results Controller

extension CDConversation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDConversation> {
        return NSFetchRequest<CDConversation>(entityName: "CDConversation")
    }
    
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: CDMessage)
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: CDMessage)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

extension CDMessage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMessage> {
        return NSFetchRequest<CDMessage>(entityName: "CDMessage")
    }
}

extension CDProvider {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDProvider> {
        return NSFetchRequest<CDProvider>(entityName: "CDProvider")
    }
    
    @objc(addModelsObject:)
    @NSManaged public func addToModels(_ value: CDModel)
    
    @objc(removeModelsObject:)
    @NSManaged public func removeFromModels(_ value: CDModel)
    
    @objc(addModels:)
    @NSManaged public func addToModels(_ values: NSSet)
    
    @objc(removeModels:)
    @NSManaged public func removeFromModels(_ values: NSSet)
    
    @objc(addConversationsObject:)
    @NSManaged public func addToConversations(_ value: CDConversation)
    
    @objc(removeConversationsObject:)
    @NSManaged public func removeFromConversations(_ value: CDConversation)
    
    @objc(addConversations:)
    @NSManaged public func addToConversations(_ values: NSSet)
    
    @objc(removeConversations:)
    @NSManaged public func removeFromConversations(_ values: NSSet)
    
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: CDMessage)
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: CDMessage)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

extension CDModel {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDModel> {
        return NSFetchRequest<CDModel>(entityName: "CDModel")
    }
}
