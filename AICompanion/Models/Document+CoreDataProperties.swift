
//
//  Document+CoreDataProperties.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData

extension CDDocument {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDocument> {
        return NSFetchRequest<CDDocument>(entityName: "CDDocument")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var fileName: String
    @NSManaged public var fileExtension: String
    @NSManaged public var fileSize: Int64
    @NSManaged public var mimeType: String?
    @NSManaged public var content: String
    @NSManaged public var summary: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastAccessedAt: Date
    @NSManaged public var filePath: String?
    @NSManaged public var embedding: Data?
    @NSManaged public var metadata: Data?
    @NSManaged public var conversations: NSSet?
    @NSManaged public var tags: NSSet?
}

// MARK: Generated accessors for conversations
extension CDDocument {
    @objc(addConversationsObject:)
    @NSManaged public func addToConversations(_ value: CDConversation)

    @objc(removeConversationsObject:)
    @NSManaged public func removeFromConversations(_ value: CDConversation)

    @objc(addConversations:)
    @NSManaged public func addToConversations(_ values: NSSet)

    @objc(removeConversations:)
    @NSManaged public func removeFromConversations(_ values: NSSet)
}

// MARK: Generated accessors for tags
extension CDDocument {
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: CDTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: CDTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}
