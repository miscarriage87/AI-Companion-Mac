
//
//  DocumentSearchManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData
import NaturalLanguage

/// Manager for document search operations
class DocumentSearchManager {
    /// Shared instance for singleton access
    static let shared = DocumentSearchManager()
    
    /// Persistence controller for Core Data operations
    private let persistenceController = PersistenceController.shared
    
    /// AI service for generating embeddings
    private let aiService = AIService.shared
    
    /// Initialize the document search manager
    private init() {}
    
    /// Search documents by keyword
    /// - Parameters:
    ///   - query: Search query
    ///   - limit: Maximum number of results
    /// - Returns: Array of matching documents with relevance scores
    func searchByKeyword(query: String, limit: Int = 10) async throws -> [(document: Document, relevance: Double)] {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Create fetch request
                    let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    
                    // Create compound predicate for title and content
                    let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
                    let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
                    let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
                    
                    fetchRequest.predicate = compoundPredicate
                    fetchRequest.fetchLimit = limit
                    
                    // Execute fetch request
                    let results = try context.fetch(fetchRequest)
                    
                    // Calculate relevance scores
                    var scoredResults: [(document: Document, relevance: Double)] = []
                    
                    for cdDocument in results {
                        let document = Document.from(cdDocument: cdDocument)
                        
                        // Calculate relevance score based on keyword frequency and position
                        let relevance = self.calculateKeywordRelevance(query: query, document: document)
                        
                        scoredResults.append((document: document, relevance: relevance))
                    }
                    
                    // Sort by relevance
                    scoredResults.sort { $0.relevance > $1.relevance }
                    
                    continuation.resume(returning: scoredResults)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Search documents by semantic similarity
    /// - Parameters:
    ///   - query: Search query
    ///   - limit: Maximum number of results
    /// - Returns: Array of matching documents with similarity scores
    func searchBySimilarity(query: String, limit: Int = 10) async throws -> [(document: Document, similarity: Double)] {
        // Generate embedding for query
        let queryEmbedding = try await aiService.generateEmbedding(text: query)
        
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch all documents with embeddings
                    let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "embedding != nil")
                    
                    let results = try context.fetch(fetchRequest)
                    
                    // Calculate similarity scores
                    var scoredResults: [(document: Document, similarity: Double)] = []
                    
                    for cdDocument in results {
                        guard let embeddingData = cdDocument.embedding,
                              let documentEmbedding = try? JSONDecoder().decode([Double].self, from: embeddingData) else {
                            continue
                        }
                        
                        let document = Document.from(cdDocument: cdDocument)
                        
                        // Calculate cosine similarity
                        let similarity = cosineSimilarity(queryEmbedding, documentEmbedding)
                        
                        scoredResults.append((document: document, similarity: similarity))
                    }
                    
                    // Sort by similarity
                    scoredResults.sort { $0.similarity > $1.similarity }
                    
                    // Limit results
                    let limitedResults = Array(scoredResults.prefix(limit))
                    
                    continuation.resume(returning: limitedResults)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Hybrid search combining keyword and semantic search
    /// - Parameters:
    ///   - query: Search query
    ///   - limit: Maximum number of results
    /// - Returns: Array of matching documents with combined scores
    func hybridSearch(query: String, limit: Int = 10) async throws -> [(document: Document, score: Double)] {
        // Perform both search types
        async let keywordResults = searchByKeyword(query: query, limit: limit * 2)
        async let similarityResults = searchBySimilarity(query: query, limit: limit * 2)
        
        // Combine results
        let (keywordDocs, similarityDocs) = try await (keywordResults, similarityResults)
        
        // Create a dictionary to combine scores
        var combinedScores: [UUID: Double] = [:]
        var documents: [UUID: Document] = [:]
        
        // Add keyword search results (weight: 0.4)
        for (document, relevance) in keywordDocs {
            combinedScores[document.id] = relevance * 0.4
            documents[document.id] = document
        }
        
        // Add similarity search results (weight: 0.6)
        for (document, similarity) in similarityDocs {
            combinedScores[document.id] = (combinedScores[document.id] ?? 0) + similarity * 0.6
            documents[document.id] = document
        }
        
        // Convert to array and sort
        let results = combinedScores.compactMap { id, score -> (document: Document, score: Double)? in
            guard let document = documents[id] else { return nil }
            return (document: document, score: score)
        }.sorted { $0.score > $1.score }
        
        // Limit results
        return Array(results.prefix(limit))
    }
    
    /// Calculate keyword relevance score
    /// - Parameters:
    ///   - query: Search query
    ///   - document: Document to score
    /// - Returns: Relevance score
    private func calculateKeywordRelevance(query: String, document: Document) -> Double {
        let lowercaseQuery = query.lowercased()
        let lowercaseTitle = document.title.lowercased()
        let lowercaseContent = document.content.lowercased()
        
        // Count occurrences in title (weighted higher)
        let titleOccurrences = lowercaseTitle.components(separatedBy: lowercaseQuery).count - 1
        
        // Count occurrences in content
        let contentOccurrences = lowercaseContent.components(separatedBy: lowercaseQuery).count - 1
        
        // Check if query appears in the first 1000 characters (weighted higher)
        let contentPrefix = String(lowercaseContent.prefix(1000))
        let appearsInPrefix = contentPrefix.contains(lowercaseQuery)
        
        // Calculate score
        let score = Double(titleOccurrences * 10 + contentOccurrences) + (appearsInPrefix ? 5.0 : 0.0)
        
        return score
    }
    
    /// Calculate cosine similarity between two embeddings
    /// - Parameters:
    ///   - a: First embedding
    ///   - b: Second embedding
    /// - Returns: Similarity score (0.0 to 1.0)
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count && !a.isEmpty else { return 0.0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    /// Find similar documents to a given document
    /// - Parameters:
    ///   - document: Reference document
    ///   - limit: Maximum number of results
    /// - Returns: Array of similar documents with similarity scores
    func findSimilarDocuments(to document: Document, limit: Int = 5) async throws -> [(document: Document, similarity: Double)] {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the reference document
                    let fetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
                    
                    let results = try context.fetch(fetchRequest)
                    guard let referenceDocument = results.first,
                          let embeddingData = referenceDocument.embedding,
                          let referenceEmbedding = try? JSONDecoder().decode([Double].self, from: embeddingData) else {
                        throw SearchError.embeddingNotFound
                    }
                    
                    // Fetch all other documents with embeddings
                    let otherDocumentsFetchRequest: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
                    otherDocumentsFetchRequest.predicate = NSPredicate(format: "id != %@ AND embedding != nil", document.id as CVarArg)
                    
                    let otherDocuments = try context.fetch(otherDocumentsFetchRequest)
                    
                    // Calculate similarity scores
                    var scoredResults: [(document: Document, similarity: Double)] = []
                    
                    for cdDocument in otherDocuments {
                        guard let embeddingData = cdDocument.embedding,
                              let documentEmbedding = try? JSONDecoder().decode([Double].self, from: embeddingData) else {
                            continue
                        }
                        
                        let doc = Document.from(cdDocument: cdDocument)
                        
                        // Calculate cosine similarity
                        let similarity = self.cosineSimilarity(referenceEmbedding, documentEmbedding)
                        
                        scoredResults.append((document: doc, similarity: similarity))
                    }
                    
                    // Sort by similarity
                    scoredResults.sort { $0.similarity > $1.similarity }
                    
                    // Limit results
                    let limitedResults = Array(scoredResults.prefix(limit))
                    
                    continuation.resume(returning: limitedResults)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

/// Search errors
enum SearchError: Error, LocalizedError {
    case embeddingNotFound
    
    var errorDescription: String? {
        switch self {
        case .embeddingNotFound:
            return "Document embedding not found"
        }
    }
}
