//
//  AIMemoryManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import CoreData
import Combine
import NaturalLanguage

/// Manager for handling AI long-term memory
class AIMemoryManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = AIMemoryManager()
    
    /// Memory entries stored in the system
    @Published private(set) var memoryEntries: [AIMemoryEntry] = []
    
    /// Persistence controller for Core Data operations
    private let persistenceController: PersistenceController
    
    /// Memory cache for quick access to frequently used memories
    private let memoryCache = NSCache<NSString, AIMemoryEntry>()
    
    /// Background task manager for memory operations
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    /// Natural language embedder for semantic search
    private let embedder = NLEmbedding.wordEmbedding(for: .english)
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        
        // Configure memory cache
        memoryCache.countLimit = 100
        
        // Load memories from persistent storage
        loadMemories()
    }
    
    /// Load memories from persistent storage
    private func loadMemories() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDMemory> = CDMemory.fetchRequest()
        
        backgroundTaskManager.executeTask {
            do {
                let cdMemories = try context.fetch(fetchRequest)
                
                // Convert Core Data entities to domain models
                let memories = cdMemories.map { cdMemory in
                    let memory = AIMemoryEntry(
                        id: cdMemory.id,
                        content: cdMemory.content,
                        createdAt: cdMemory.createdAt,
                        lastAccessedAt: cdMemory.lastAccessedAt,
                        importanceScore: cdMemory.importanceScore,
                        tags: cdMemory.tags as? [String] ?? [],
                        userId: cdMemory.userId,
                        embedding: cdMemory.embedding as? [Float] ?? []
                    )
                    
                    // Cache the memory
                    self.memoryCache.setObject(memory, forKey: memory.id.uuidString as NSString)
                    
                    return memory
                }
                
                // Update the published property on the main thread
                DispatchQueue.main.async {
                    self.memoryEntries = memories
                }
                
                return true
            } catch {
                print("Failed to load memories: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    /// Store a new memory
    func storeMemory(_ content: String, tags: [String] = [], userId: UUID, importanceScore: Double = 0.5) async throws -> AIMemoryEntry {
        // Create a new memory entry
        let memory = AIMemoryEntry(
            content: content,
            importanceScore: importanceScore,
            tags: tags,
            userId: userId,
            embedding: try await generateEmbedding(for: content)
        )
        
        // Save to Core Data
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            // Create a new Core Data entity
            let cdMemory = CDMemory(context: context)
            cdMemory.id = memory.id
            cdMemory.content = memory.content
            cdMemory.createdAt = memory.createdAt
            cdMemory.lastAccessedAt = memory.lastAccessedAt
            cdMemory.importanceScore = memory.importanceScore
            cdMemory.tags = memory.tags as NSArray
            cdMemory.userId = memory.userId
            cdMemory.embedding = memory.embedding as NSArray
            
            // Save the context
            try context.save()
        }
        
        // Cache the memory
        memoryCache.setObject(memory, forKey: memory.id.uuidString as NSString)
        
        // Update the published property on the main thread
        DispatchQueue.main.async {
            self.memoryEntries.append(memory)
        }
        
        return memory
    }
    
    /// Retrieve a memory by ID
    func retrieveMemory(id: UUID) -> AIMemoryEntry? {
        // Check the cache first
        if let memory = memoryCache.object(forKey: id.uuidString as NSString) {
            // Update last accessed time
            memory.lastAccessedAt = Date()
            
            // Update in Core Data
            updateMemoryAccessTime(id: id, lastAccessedAt: memory.lastAccessedAt)
            
            return memory
        }
        
        // If not in cache, check the published list
        if let memory = memoryEntries.first(where: { $0.id == id }) {
            // Update last accessed time
            memory.lastAccessedAt = Date()
            
            // Update in Core Data
            updateMemoryAccessTime(id: id, lastAccessedAt: memory.lastAccessedAt)
            
            // Cache the memory
            memoryCache.setObject(memory, forKey: id.uuidString as NSString)
            
            return memory
        }
        
        // If not found, fetch from Core Data
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDMemory> = CDMemory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let cdMemory = results.first {
                // Convert to domain model
                let memory = AIMemoryEntry(
                    id: cdMemory.id,
                    content: cdMemory.content,
                    createdAt: cdMemory.createdAt,
                    lastAccessedAt: Date(), // Update last accessed time
                    importanceScore: cdMemory.importanceScore,
                    tags: cdMemory.tags as? [String] ?? [],
                    userId: cdMemory.userId,
                    embedding: cdMemory.embedding as? [Float] ?? []
                )
                
                // Update last accessed time in Core Data
                cdMemory.lastAccessedAt = memory.lastAccessedAt
                try context.save()
                
                // Cache the memory
                memoryCache.setObject(memory, forKey: id.uuidString as NSString)
                
                return memory
            }
        } catch {
            print("Failed to retrieve memory: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Update memory access time
    private func updateMemoryAccessTime(id: UUID, lastAccessedAt: Date) {
        let context = persistenceController.container.newBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<CDMemory> = CDMemory.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if let cdMemory = results.first {
                    cdMemory.lastAccessedAt = lastAccessedAt
                    try context.save()
                }
            } catch {
                print("Failed to update memory access time: \(error.localizedDescription)")
            }
        }
    }
    
    /// Delete a memory
    func deleteMemory(id: UUID) async throws {
        // Remove from cache
        memoryCache.removeObject(forKey: id.uuidString as NSString)
        
        // Remove from published list
        DispatchQueue.main.async {
            self.memoryEntries.removeAll { $0.id == id }
        }
        
        // Remove from Core Data
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<CDMemory> = CDMemory.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            
            if let cdMemory = results.first {
                context.delete(cdMemory)
                try context.save()
            }
        }
    }
    
    /// Search for memories by text
    func searchMemories(query: String, userId: UUID, limit: Int = 5) async throws -> [AIMemoryEntry] {
        // Generate embedding for the query
        let queryEmbedding = try await generateEmbedding(for: query)
        
        // Get all memories for the user
        let userMemories = memoryEntries.filter { $0.userId == userId }
        
        // Calculate similarity scores
        let memoriesWithScores = userMemories.map { memory -> (memory: AIMemoryEntry, score: Float) in
            let similarity = cosineSimilarity(queryEmbedding, memory.embedding)
            return (memory: memory, score: similarity)
        }
        
        // Sort by similarity score (descending)
        let sortedMemories = memoriesWithScores.sorted { $0.score > $1.score }
        
        // Take the top results
        let topMemories = sortedMemories.prefix(limit).map { $0.memory }
        
        // Update last accessed time for retrieved memories
        for memory in topMemories {
            memory.lastAccessedAt = Date()
            updateMemoryAccessTime(id: memory.id, lastAccessedAt: memory.lastAccessedAt)
        }
        
        return Array(topMemories)
    }
    
    /// Search for memories by tags
    func searchMemoriesByTags(tags: [String], userId: UUID, limit: Int = 5) -> [AIMemoryEntry] {
        // Get all memories for the user
        let userMemories = memoryEntries.filter { $0.userId == userId }
        
        // Filter by tags
        let filteredMemories = userMemories.filter { memory in
            // Check if any of the memory's tags match the search tags
            return !Set(memory.tags).intersection(Set(tags)).isEmpty
        }
        
        // Sort by importance score (descending)
        let sortedMemories = filteredMemories.sorted { $0.importanceScore > $1.importanceScore }
        
        // Take the top results
        let topMemories = sortedMemories.prefix(limit)
        
        // Update last accessed time for retrieved memories
        for memory in topMemories {
            memory.lastAccessedAt = Date()
            updateMemoryAccessTime(id: memory.id, lastAccessedAt: memory.lastAccessedAt)
        }
        
        return Array(topMemories)
    }
    
    /// Update memory importance score
    func updateMemoryImportance(id: UUID, importanceScore: Double) async throws {
        // Update in cache
        if let memory = memoryCache.object(forKey: id.uuidString as NSString) {
            memory.importanceScore = importanceScore
        }
        
        // Update in published list
        if let index = memoryEntries.firstIndex(where: { $0.id == id }) {
            memoryEntries[index].importanceScore = importanceScore
        }
        
        // Update in Core Data
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<CDMemory> = CDMemory.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            
            if let cdMemory = results.first {
                cdMemory.importanceScore = importanceScore
                try context.save()
            }
        }
    }
    
    /// Generate embedding for text
    private func generateEmbedding(for text: String) async throws -> [Float] {
        // In a real implementation, this would use a more sophisticated embedding model
        // For this example, we'll use a simple word embedding
        
        guard let embedder = self.embedder else {
            // If embedder is not available, return an empty embedding
            return Array(repeating: 0.0, count: 300)
        }
        
        // Tokenize the text
        let tokens = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(100) // Limit to 100 tokens
        
        // Get embeddings for each token
        var embeddings: [[Float]] = []
        
        for token in tokens {
            if let vector = embedder.vector(for: token) {
                // Convert Double to Float
                let floatVector = vector.map { Float($0) }
                embeddings.append(floatVector)
            }
        }
        
        // If no embeddings were found, return an empty embedding
        if embeddings.isEmpty {
            return Array(repeating: 0.0, count: 300)
        }
        
        // Average the embeddings
        let embeddingSize = embeddings[0].count
        var averageEmbedding = Array(repeating: Float(0.0), count: embeddingSize)
        
        for embedding in embeddings {
            for i in 0..<embeddingSize {
                averageEmbedding[i] += embedding[i]
            }
        }
        
        for i in 0..<embeddingSize {
            averageEmbedding[i] /= Float(embeddings.count)
        }
        
        // Normalize the embedding
        let magnitude = sqrt(averageEmbedding.map { $0 * $0 }.reduce(0, +))
        
        if magnitude > 0 {
            for i in 0..<embeddingSize {
                averageEmbedding[i] /= magnitude
            }
        }
        
        return averageEmbedding
    }
    
    /// Calculate cosine similarity between two embeddings
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count && !a.isEmpty else {
            return 0.0
        }
        
        var dotProduct: Float = 0.0
        var magnitudeA: Float = 0.0
        var magnitudeB: Float = 0.0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }
        
        magnitudeA = sqrt(magnitudeA)
        magnitudeB = sqrt(magnitudeB)
        
        if magnitudeA == 0 || magnitudeB == 0 {
            return 0.0
        }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    /// Prune old memories
    func pruneOldMemories(olderThan date: Date, exceptImportantOnes: Bool = true) async throws {
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<CDMemory> = CDMemory.fetchRequest()
            
            if exceptImportantOnes {
                // Don't delete important memories
                fetchRequest.predicate = NSPredicate(format: "createdAt < %@ AND importanceScore < 0.7", date as NSDate)
            } else {
                fetchRequest.predicate = NSPredicate(format: "createdAt < %@", date as NSDate)
            }
            
            let results = try context.fetch(fetchRequest)
            
            for cdMemory in results {
                // Remove from cache
                self.memoryCache.removeObject(forKey: cdMemory.id.uuidString as NSString)
                
                // Delete from Core Data
                context.delete(cdMemory)
            }
            
            try context.save()
            
            // Update published list
            DispatchQueue.main.async {
                if exceptImportantOnes {
                    self.memoryEntries.removeAll { $0.createdAt < date && $0.importanceScore < 0.7 }
                } else {
                    self.memoryEntries.removeAll { $0.createdAt < date }
                }
            }
        }
    }
}

/// Represents a memory entry stored by the AI
class AIMemoryEntry: NSObject, Identifiable {
    /// Unique identifier for the memory
    let id: UUID
    
    /// Content of the memory
    let content: String
    
    /// Timestamp when the memory was created
    let createdAt: Date
    
    /// Timestamp when the memory was last accessed
    var lastAccessedAt: Date
    
    /// Importance score of the memory (0-1)
    var importanceScore: Double
    
    /// Tags associated with the memory for retrieval
    var tags: [String]
    
    /// User ID associated with this memory
    let userId: UUID
    
    /// Embedding vector for semantic search
    let embedding: [Float]
    
    init(id: UUID = UUID(), content: String, createdAt: Date = Date(), lastAccessedAt: Date = Date(), importanceScore: Double = 0.5, tags: [String] = [], userId: UUID, embedding: [Float] = []) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.importanceScore = importanceScore
        self.tags = tags
        self.userId = userId
        self.embedding = embedding
    }
}

/// Core Data entity for Memory
@objc(CDMemory)
public class CDMemory: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var content: String
    @NSManaged public var createdAt: Date
    @NSManaged public var lastAccessedAt: Date
    @NSManaged public var importanceScore: Double
    @NSManaged public var tags: NSArray
    @NSManaged public var userId: UUID
    @NSManaged public var embedding: NSArray
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMemory> {
        return NSFetchRequest<CDMemory>(entityName: "CDMemory")
    }
}
