
//
//  Document.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation

/// Document model for use in the app
struct Document: Identifiable, Hashable {
    var id: UUID
    var title: String
    var fileName: String
    var fileExtension: String
    var fileSize: Int64
    var mimeType: String?
    var content: String
    var summary: String?
    var createdAt: Date
    var updatedAt: Date
    var lastAccessedAt: Date
    var filePath: String?
    var tags: [DocumentTag]
    
    /// Create a Document from a Core Data CDDocument
    static func from(cdDocument: CDDocument) -> Document {
        let tags = cdDocument.tags?.compactMap { tag -> DocumentTag? in
            guard let cdTag = tag as? CDTag else { return nil }
            return DocumentTag.from(cdTag: cdTag)
        } ?? []
        
        return Document(
            id: cdDocument.id,
            title: cdDocument.title,
            fileName: cdDocument.fileName,
            fileExtension: cdDocument.fileExtension,
            fileSize: cdDocument.fileSize,
            mimeType: cdDocument.mimeType,
            content: cdDocument.content,
            summary: cdDocument.summary,
            createdAt: cdDocument.createdAt,
            updatedAt: cdDocument.updatedAt,
            lastAccessedAt: cdDocument.lastAccessedAt,
            filePath: cdDocument.filePath,
            tags: tags
        )
    }
}

/// Document tag model for use in the app
struct DocumentTag: Identifiable, Hashable {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    /// Create a DocumentTag from a Core Data CDTag
    static func from(cdTag: CDTag) -> DocumentTag {
        return DocumentTag(
            id: cdTag.id,
            name: cdTag.name,
            color: cdTag.color,
            createdAt: cdTag.createdAt
        )
    }
}

/// Document section model for use in the app
struct DocumentSection: Identifiable, Hashable {
    var id: UUID
    var title: String?
    var content: String
    var startIndex: Int
    var endIndex: Int
    
    /// Create a DocumentSection from a Core Data CDDocumentSection
    static func from(cdSection: CDDocumentSection) -> DocumentSection {
        return DocumentSection(
            id: cdSection.id,
            title: cdSection.title,
            content: cdSection.content,
            startIndex: Int(cdSection.startIndex),
            endIndex: Int(cdSection.endIndex)
        )
    }
}
