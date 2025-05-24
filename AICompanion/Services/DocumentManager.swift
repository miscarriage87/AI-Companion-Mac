//
//  DocumentManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData
import PDFKit
import QuickLookThumbnailing
import UniformTypeIdentifiers
import Combine
import NaturalLanguage

/// Manager for document operations
class DocumentManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = DocumentManager()
    
    /// Documents loaded in memory
    @Published var documents: [Document] = []
    
    /// Tags available for documents
    @Published var tags: [DocumentTag] = []
    
    /// Currently selected document
    @Published var selectedDocument: Document?
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Whether to show the error alert
    @Published var showError: Bool = false
    
    /// Persistence controller for Core Data operations
    private let persistenceController = PersistenceController.shared
    
    /// Document analyzer for AI-powered analysis
    private let documentAnalyzer = DocumentAnalyzer.shared
    
    /// Document search manager for searching documents
    private let searchManager = DocumentSearchManager.shared
    
    /// Document parser factory for creating parsers
    private let parserFactory = DocumentParserFactory()
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Document storage directory
    private let documentsDirectory: URL
    
    /// Initialize the document manager
    private init() {
        // Get the application support directory for document storage
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        documentsDirectory = appSupportDir.appendingPathComponent("AICompanion/Documents")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        
        // Load documents and tags
        loadDocuments()
        loadTags()
    }
    
    // MARK: - Document Operations
    
    /// Load all documents from Core Data
    func loadDocuments() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.updatedAt, ascending: false)]
        
        do {
            let cdDocuments = try context.fetch(fetchRequest)
            documents = cdDocuments.map { Document.from(cdDocument: $0) }
        } catch {
            errorMessage = "Failed to load documents: \(error.localizedDescription)"
            showError = true
            print("Error loading documents: \(error)")
        }
    }
    
    /// Load all tags from Core Data
    func loadTags() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDTag.name, ascending: true)]
        
        do {
            let cdTags = try context.fetch(fetchRequest)
            tags = cdTags.map { DocumentTag.from(cdTag: $0) }
        } catch {
            errorMessage = "Failed to load tags: \(error.localizedDescription)"
            showError = true
            print("Error loading tags: \(error)")
        }
    }
    
    /// Import a document from a file URL
    /// - Parameters:
    ///   - url: URL of the file to import
    ///   - makeLocalCopy: Whether to make a local copy of the file
    ///   - progressHandler: Handler for reporting progress
    ///   - completion: Completion handler with the imported document or error
    func importDocument(from url: URL, makeLocalCopy: Bool = true, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Result<Document, Error>) -> Void) {
        // Report initial progress
        progressHandler?(0.1)
        
        // Get file attributes
        guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = fileAttributes[.size] as? NSNumber else {
            completion(.failure(DocumentError.fileAttributesNotAvailable))
            return
        }
        
        // Get file extension and type
        let fileExtension = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent
        
        // Create a parser for the file type
        guard let parser = parserFactory.createParser(for: fileExtension) else {
            completion(.failure(DocumentError.unsupportedFileFormat))
            return
        }
        
        // Parse the document
        Task {
            do {
                // Extract text from the document
                progressHandler?(0.2)
                let content = try await parser.extractText(from: url, progressHandler: { progress in
                    // Scale progress from 0.2 to 0.6
                    progressHandler?(0.2 + progress * 0.4)
                })
                
                // Generate a title if needed
                progressHandler?(0.6)
                let title = fileName.replacingOccurrences(of: ".\(fileExtension)$", with: "", options: .regularExpression)
                
                // Make a local copy if requested
                var localURL: URL?
                if makeLocalCopy {
                    let destinationURL = documentsDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    localURL = destinationURL
                }
                
                // Create document in Core Data
                progressHandler?(0.7)
                let document = try await saveDocument(
                    title: title,
                    fileName: fileName,
                    fileExtension: fileExtension,
                    fileSize: fileSize.int64Value,
                    mimeType: UTType(filenameExtension: fileExtension)?.preferredMIMEType,
                    content: content,
                    filePath: localURL?.path
                )
                
                // Analyze document with AI
                progressHandler?(0.8)
                Task {
                    do {
                        try await analyzeDocument(document)
                    } catch {
                        print("Error analyzing document: \(error)")
                    }
                }
                
                // Return the document
                progressHandler?(1.0)
                completion(.success(document))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Import a document from a URL (web URL)
    /// - Parameters:
    ///   - url: Web URL to import
    ///   - progressHandler: Handler for reporting progress
    ///   - completion: Completion handler with the imported document or error
    func importDocument(from webURL: URL, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Result<Document, Error>) -> Void) {
        // Report initial progress
        progressHandler?(0.1)
        
        // Download the content
        let task = URLSession.shared.dataTask(with: webURL) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(DocumentError.downloadFailed))
                return
            }
            
            // Get content type
            let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? "text/plain"
            
            // Determine file extension based on content type
            let fileExtension: String
            if contentType.contains("text/html") {
                fileExtension = "html"
            } else if contentType.contains("application/pdf") {
                fileExtension = "pdf"
            } else if contentType.contains("text/plain") {
                fileExtension = "txt"
            } else {
                fileExtension = "txt" // Default to text
            }
            
            // Save the file locally
            let fileName = webURL.lastPathComponent.isEmpty ? "document" : webURL.lastPathComponent
            let localFileName = "\(UUID().uuidString).\(fileExtension)"
            let localURL = self.documentsDirectory.appendingPathComponent(localFileName)
            
            do {
                try data.write(to: localURL)
                progressHandler?(0.3)
                
                // Create a parser for the file type
                guard let parser = self.parserFactory.createParser(for: fileExtension) else {
                    completion(.failure(DocumentError.unsupportedFileFormat))
                    return
                }
                
                // Parse the document
                Task {
                    do {
                        // Extract text from the document
                        progressHandler?(0.4)
                        let content = try await parser.extractText(from: localURL, progressHandler: { progress in
                            // Scale progress from 0.4 to 0.7
                            progressHandler?(0.4 + progress * 0.3)
                        })
                        
                        // Generate a title
                        progressHandler?(0.7)
                        let title: String
                        if fileExtension == "html" {
                            // Try to extract title from HTML
                            title = self.extractTitleFromHTML(content) ?? webURL.host ?? "Web Document"
                        } else {
                            title = webURL.host ?? "Web Document"
                        }
                        
                        // Create document in Core Data
                        progressHandler?(0.8)
                        let document = try await self.saveDocument(
                            title: title,
                            fileName: fileName,
                            fileExtension: fileExtension,
                            fileSize: Int64(data.count),
                            mimeType: contentType,
                            content: content,
                            filePath: localURL.path
                        )
                        
                        // Analyze document with AI
                        progressHandler?(0.9)
                        Task {
                            do {
                                try await self.analyzeDocument(document)
                            } catch {
                                print("Error analyzing document: \(error)")
                            }
                        }
                        
                        // Return the document
                        progressHandler?(1.0)
                        completion(.success(document))
                    } catch {
                        completion(.failure(error))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Save a document to Core Data
    /// - Parameters:
    ///   - title: Document title
    ///   - fileName: Original file name
    ///   - fileExtension: File extension
    ///   - fileSize: File size in bytes
    ///   - mimeType: MIME type of the file
    ///   - content: Text content of the document
    ///   - filePath: Path to the local copy of the file
    /// - Returns: The saved document
    private func saveDocument(title: String, fileName: String, fileExtension: String, fileSize: Int64, mimeType: String?, content: String, filePath: String?) async throws -> Document {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Create new document
                    let cdDocument = CDDocument(context: context)
                    cdDocument.id = UUID()
                    cdDocument.title = title
                    cdDocument.fileName = fileName
                    cdDocument.fileExtension = fileExtension
                    cdDocument.fileSize = fileSize
                    cdDocument.mimeType = mimeType
                    cdDocument.content = content
                    cdDocument.createdAt = Date()
                    cdDocument.updatedAt = Date()
                    cdDocument.lastAccessedAt = Date()
                    cdDocument.filePath = filePath
                    
                    // Save context
                    try context.save()
                    
                    // Create document model
                    let document = Document.from(cdDocument: cdDocument)
                    
                    // Update documents array on main thread
                    Task { @MainActor in
                        self.documents.insert(document, at: 0)
                    }
                    
                    continuation.resume(returning: document)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Delete a document
    /// - Parameter document: Document to delete
    func deleteDocument(_ document: Document) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the document
                    let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
                    
                    let results = try context.fetch(fetchRequest)
                    guard let cdDocument = results.first else {
                        throw DocumentError.documentNotFound
                    }
                    
                    // Delete local file if it exists
                    if let filePath = cdDocument.filePath, FileManager.default.fileExists(atPath: filePath) {
                        try FileManager.default.removeItem(atPath: filePath)
                    }
                    
                    // Delete from Core Data
                    context.delete(cdDocument)
                    try context.save()
                    
                    // Update documents array on main thread
                    Task { @MainActor in
                        self.documents.removeAll { $0.id == document.id }
                        if self.selectedDocument?.id == document.id {
                            self.selectedDocument = nil
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update a document
    /// - Parameter document: Document to update
    func updateDocument(_ document: Document) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the document
                    let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
                    
                    let results = try context.fetch(fetchRequest)
                    guard let cdDocument = results.first else {
                        throw DocumentError.documentNotFound
                    }
                    
                    // Update properties
                    cdDocument.title = document.title
                    cdDocument.updatedAt = Date()
                    cdDocument.lastAccessedAt = Date()
                    
                    // Save context
                    try context.save()
                    
                    // Update documents array on main thread
                    Task { @MainActor in
                        if let index = self.documents.firstIndex(where: { $0.id == document.id }) {
                            self.documents[index] = document
                        }
                        
                        if self.selectedDocument?.id == document.id {
                            self.selectedDocument = document
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get a document by ID
    /// - Parameter id: Document ID
    /// - Returns: The document, if found
    func getDocument(id: UUID) async throws -> Document {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the document
                    let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    
                    let results = try context.fetch(fetchRequest)
                    guard let cdDocument = results.first else {
                        throw DocumentError.documentNotFound
                    }
                    
                    // Update last accessed date
                    cdDocument.lastAccessedAt = Date()
                    try context.save()
                    
                    // Create document model
                    let document = Document.from(cdDocument: cdDocument)
                    continuation.resume(returning: document)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Document Analysis
    
    /// Analyze a document with AI
    /// - Parameter document: Document to analyze
    func analyzeDocument(_ document: Document) async throws {
        // Generate summary
        let summary = try await documentAnalyzer.summarizeDocument(document)
        
        // Generate embeddings
        let embedding = try await documentAnalyzer.generateEmbedding(for: document)
        
        // Extract key information
        let metadata = try await documentAnalyzer.extractKeyInformation(from: document)
        
        // Update document in Core Data
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the document
                    let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
                    
                    let results = try context.fetch(fetchRequest)
                    guard let cdDocument = results.first else {
                        throw DocumentError.documentNotFound
                    }
                    
                    // Update properties
                    cdDocument.summary = summary
                    cdDocument.embedding = embedding
                    cdDocument.metadata = try JSONEncoder().encode(metadata)
                    cdDocument.updatedAt = Date()
                    
                    // Save context
                    try context.save()
                    
                    // Update documents array on main thread
                    Task { @MainActor in
                        if let index = self.documents.firstIndex(where: { $0.id == document.id }) {
                            var updatedDocument = self.documents[index]
                            updatedDocument.summary = summary
                            self.documents[index] = updatedDocument
                            
                            if self.selectedDocument?.id == document.id {
                                self.selectedDocument = updatedDocument
                            }
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Tag Operations
    
    /// Create a new tag
    /// - Parameters:
    ///   - name: Tag name
    ///   - color: Tag color (hex code)
    /// - Returns: The created tag
    func createTag(name: String, color: String) async throws -> DocumentTag {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Create new tag
                    let cdTag = CDTag(context: context)
                    cdTag.id = UUID()
                    cdTag.name = name
                    cdTag.color = color
                    cdTag.createdAt = Date()
                    
                    // Save context
                    try context.save()
                    
                    // Create tag model
                    let tag = DocumentTag.from(cdTag: cdTag)
                    
                    // Update tags array on main thread
                    Task { @MainActor in
                        self.tags.append(tag)
                        self.tags.sort { $0.name < $1.name }
                    }
                    
                    continuation.resume(returning: tag)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Delete a tag
    /// - Parameter tag: Tag to delete
    func deleteTag(_ tag: DocumentTag) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the tag
                    let fetchRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
                    
                    let results = try context.fetch(fetchRequest)
                    guard let cdTag = results.first else {
                        throw DocumentError.tagNotFound
                    }
                    
                    // Delete from Core Data
                    context.delete(cdTag)
                    try context.save()
                    
                    // Update tags array on main thread
                    Task { @MainActor in
                        self.tags.removeAll { $0.id == tag.id }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Add a tag to a document
    /// - Parameters:
    ///   - tag: Tag to add
    ///   - document: Document to tag
    func addTag(_ tag: DocumentTag, to document: Document) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the document
                    let documentFetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    documentFetchRequest.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
                    
                    let documentResults = try context.fetch(documentFetchRequest)
                    guard let cdDocument = documentResults.first else {
                        throw DocumentError.documentNotFound
                    }
                    
                    // Fetch the tag
                    let tagFetchRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
                    tagFetchRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
                    
                    let tagResults = try context.fetch(tagFetchRequest)
                    guard let cdTag = tagResults.first else {
                        throw DocumentError.tagNotFound
                    }
                    
                    // Add tag to document
                    cdDocument.addToTags(cdTag)
                    try context.save()
                    
                    // Update document model
                    let updatedDocument = Document.from(cdDocument: cdDocument)
                    
                    // Update documents array on main thread
                    Task { @MainActor in
                        if let index = self.documents.firstIndex(where: { $0.id == document.id }) {
                            self.documents[index] = updatedDocument
                        }
                        
                        if self.selectedDocument?.id == document.id {
                            self.selectedDocument = updatedDocument
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Remove a tag from a document
    /// - Parameters:
    ///   - tag: Tag to remove
    ///   - document: Document to untag
    func removeTag(_ tag: DocumentTag, from document: Document) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the document
                    let documentFetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    documentFetchRequest.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
                    
                    let documentResults = try context.fetch(documentFetchRequest)
                    guard let cdDocument = documentResults.first else {
                        throw DocumentError.documentNotFound
                    }
                    
                    // Fetch the tag
                    let tagFetchRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
                    tagFetchRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
                    
                    let tagResults = try context.fetch(tagFetchRequest)
                    guard let cdTag = tagResults.first else {
                        throw DocumentError.tagNotFound
                    }
                    
                    // Remove tag from document
                    cdDocument.removeFromTags(cdTag)
                    try context.save()
                    
                    // Update document model
                    let updatedDocument = Document.from(cdDocument: cdDocument)
                    
                    // Update documents array on main thread
                    Task { @MainActor in
                        if let index = self.documents.firstIndex(where: { $0.id == document.id }) {
                            self.documents[index] = updatedDocument
                        }
                        
                        if self.selectedDocument?.id == document.id {
                            self.selectedDocument = updatedDocument
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Extract title from HTML content
    /// - Parameter htmlContent: HTML content
    /// - Returns: Title if found, nil otherwise
    private func extractTitleFromHTML(_ htmlContent: String) -> String? {
        // Simple regex to extract title
        let titlePattern = "<title>(.*?)</title>"
        guard let regex = try? NSRegularExpression(pattern: titlePattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(htmlContent.startIndex..., in: htmlContent)
        guard let match = regex.firstMatch(in: htmlContent, options: [], range: range) else {
            return nil
        }
        
        guard let titleRange = Range(match.range(at: 1), in: htmlContent) else {
            return nil
        }
        
        return String(htmlContent[titleRange])
    }
    
    /// Generate a thumbnail for a document
    /// - Parameter document: Document to generate thumbnail for
    /// - Returns: Thumbnail image if successful, nil otherwise
    func generateThumbnail(for document: Document) async -> NSImage? {
        guard let filePath = document.filePath, FileManager.default.fileExists(atPath: filePath) else {
            return nil
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        // For PDFs, use PDFKit
        if document.fileExtension.lowercased() == "pdf" {
            guard let pdfDocument = PDFDocument(url: fileURL) else {
                return nil
            }
            
            guard let pdfPage = pdfDocument.page(at: 0) else {
                return nil
            }
            
            let thumbnailSize = CGSize(width: 200, height: 200)
            return pdfPage.thumbnail(of: thumbnailSize, for: .mediaBox)
        }
        
        // For other file types, use QuickLook
        let size = CGSize(width: 200, height: 200)
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        
        let request = QLThumbnailGenerator.Request(
            fileAt: fileURL,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        
        do {
            let generator = QLThumbnailGenerator.shared
            let thumbnail = try await generator.generateBestRepresentation(for: request)
            return thumbnail.nsImage
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
}

/// Document error types
enum DocumentError: Error, LocalizedError {
    case fileAttributesNotAvailable
    case unsupportedFileFormat
    case documentNotFound
    case tagNotFound
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .fileAttributesNotAvailable:
            return "Could not access file attributes"
        case .unsupportedFileFormat:
            return "Unsupported file format"
        case .documentNotFound:
            return "Document not found"
        case .tagNotFound:
            return "Tag not found"
        case .downloadFailed:
            return "Failed to download document"
        }
    }
}
