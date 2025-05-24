
//
//  DocumentSection+CoreDataProperties.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData

extension CDDocumentSection {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDocumentSection> {
        return NSFetchRequest<CDDocumentSection>(entityName: "CDDocumentSection")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var content: String
    @NSManaged public var startIndex: Int32
    @NSManaged public var endIndex: Int32
    @NSManaged public var embedding: Data?
    @NSManaged public var document: CDDocument
}
