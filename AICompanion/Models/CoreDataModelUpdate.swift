
//
//  CoreDataModelUpdate.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData

/// Helper extension to add document entities to the Core Data model
extension NSPersistentContainer {
    /// Add document entities to the Core Data model
    func addDocumentEntities() {
        guard let model = managedObjectModel.copy() as? NSManagedObjectModel else {
            print("Failed to copy managed object model")
            return
        }
        
        // Create CDDocument entity
        let documentEntity = NSEntityDescription()
        documentEntity.name = "CDDocument"
        documentEntity.managedObjectClassName = "CDDocument"
        
        // Create CDTag entity
        let tagEntity = NSEntityDescription()
        tagEntity.name = "CDTag"
        tagEntity.managedObjectClassName = "CDTag"
        
        // Create CDDocumentSection entity
        let sectionEntity = NSEntityDescription()
        sectionEntity.name = "CDDocumentSection"
        sectionEntity.managedObjectClassName = "CDDocumentSection"
        
        // Add attributes to CDDocument
        let documentAttributes: [String: NSAttributeDescription] = [
            "id": createAttribute(name: "id", type: .UUIDAttributeType),
            "title": createAttribute(name: "title", type: .stringAttributeType),
            "fileName": createAttribute(name: "fileName", type: .stringAttributeType),
            "fileExtension": createAttribute(name: "fileExtension", type: .stringAttributeType),
            "fileSize": createAttribute(name: "fileSize", type: .integer64AttributeType),
            "mimeType": createAttribute(name: "mimeType", type: .stringAttributeType, optional: true),
            "content": createAttribute(name: "content", type: .stringAttributeType),
            "summary": createAttribute(name: "summary", type: .stringAttributeType, optional: true),
            "createdAt": createAttribute(name: "createdAt", type: .dateAttributeType),
            "updatedAt": createAttribute(name: "updatedAt", type: .dateAttributeType),
            "lastAccessedAt": createAttribute(name: "lastAccessedAt", type: .dateAttributeType),
            "filePath": createAttribute(name: "filePath", type: .stringAttributeType, optional: true),
            "embedding": createAttribute(name: "embedding", type: .binaryDataAttributeType, optional: true),
            "metadata": createAttribute(name: "metadata", type: .binaryDataAttributeType, optional: true)
        ]
        
        // Add attributes to CDTag
        let tagAttributes: [String: NSAttributeDescription] = [
            "id": createAttribute(name: "id", type: .UUIDAttributeType),
            "name": createAttribute(name: "name", type: .stringAttributeType),
            "color": createAttribute(name: "color", type: .stringAttributeType),
            "createdAt": createAttribute(name: "createdAt", type: .dateAttributeType)
        ]
        
        // Add attributes to CDDocumentSection
        let sectionAttributes: [String: NSAttributeDescription] = [
            "id": createAttribute(name: "id", type: .UUIDAttributeType),
            "title": createAttribute(name: "title", type: .stringAttributeType, optional: true),
            "content": createAttribute(name: "content", type: .stringAttributeType),
            "startIndex": createAttribute(name: "startIndex", type: .integer32AttributeType),
            "endIndex": createAttribute(name: "endIndex", type: .integer32AttributeType),
            "embedding": createAttribute(name: "embedding", type: .binaryDataAttributeType, optional: true)
        ]
        
        // Set attributes
        documentEntity.properties = Array(documentAttributes.values)
        tagEntity.properties = Array(tagAttributes.values)
        sectionEntity.properties = Array(sectionAttributes.values)
        
        // Create relationships
        
        // Document to Tag (many-to-many)
        let documentToTags = NSRelationshipDescription()
        documentToTags.name = "tags"
        documentToTags.destinationEntity = tagEntity
        documentToTags.deleteRule = .nullifyDeleteRule
        documentToTags.minCount = 0
        documentToTags.maxCount = 0 // Many
        
        let tagToDocuments = NSRelationshipDescription()
        tagToDocuments.name = "documents"
        tagToDocuments.destinationEntity = documentEntity
        tagToDocuments.deleteRule = .nullifyDeleteRule
        tagToDocuments.minCount = 0
        tagToDocuments.maxCount = 0 // Many
        
        documentToTags.inverseRelationship = tagToDocuments
        tagToDocuments.inverseRelationship = documentToTags
        
        // Document to Section (one-to-many)
        let documentToSections = NSRelationshipDescription()
        documentToSections.name = "sections"
        documentToSections.destinationEntity = sectionEntity
        documentToSections.deleteRule = .cascadeDeleteRule
        documentToSections.minCount = 0
        documentToSections.maxCount = 0 // Many
        
        let sectionToDocument = NSRelationshipDescription()
        sectionToDocument.name = "document"
        sectionToDocument.destinationEntity = documentEntity
        sectionToDocument.deleteRule = .nullifyDeleteRule
        sectionToDocument.minCount = 1
        sectionToDocument.maxCount = 1 // One
        
        documentToSections.inverseRelationship = sectionToDocument
        sectionToDocument.inverseRelationship = documentToSections
        
        // Document to Conversation (many-to-many)
        let documentToConversations = NSRelationshipDescription()
        documentToConversations.name = "conversations"
        documentToConversations.destinationEntity = model.entitiesByName["CDConversation"]
        documentToConversations.deleteRule = .nullifyDeleteRule
        documentToConversations.minCount = 0
        documentToConversations.maxCount = 0 // Many
        
        let conversationToDocuments = NSRelationshipDescription()
        conversationToDocuments.name = "documents"
        conversationToDocuments.destinationEntity = documentEntity
        conversationToDocuments.deleteRule = .nullifyDeleteRule
        conversationToDocuments.minCount = 0
        conversationToDocuments.maxCount = 0 // Many
        
        documentToConversations.inverseRelationship = conversationToDocuments
        conversationToDocuments.inverseRelationship = documentToConversations
        
        // Add relationships to properties
        documentEntity.properties = documentEntity.properties + [documentToTags, documentToSections, documentToConversations]
        tagEntity.properties = tagEntity.properties + [tagToDocuments]
        sectionEntity.properties = sectionEntity.properties + [sectionToDocument]
        
        // Add entities to model
        model.entities = model.entities + [documentEntity, tagEntity, sectionEntity]
        
        // Update the managed object model
        self.managedObjectModel = model
    }
    
    /// Create an attribute description
    private func createAttribute(name: String, type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
