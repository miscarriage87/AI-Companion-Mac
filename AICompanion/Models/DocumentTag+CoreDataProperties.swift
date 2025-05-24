
//
//  DocumentTag+CoreDataProperties.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData

extension CDTag {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTag> {
        return NSFetchRequest<CDTag>(entityName: "CDTag")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var color: String
    @NSManaged public var createdAt: Date
    @NSManaged public var documents: NSSet?
}

// MARK: Generated accessors for documents
extension CDTag {
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: CDDocument)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: CDDocument)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
}
