//
//  ChatViewModel+Documents.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine

/// Extension to ChatViewModel for document-related functionality
extension ChatViewModel {
    // MARK: - Properties
    
    /// Documents referenced in the current conversation
    @Published var referencedDocuments: [Document] = []
    
    /// Document being viewed in detail
    @Published var selectedDocument: Document?
    
    /// Whether to include document context in AI prompts
    @Published var includeDocumentContext: Bool = true
    
    /// Maximum number of document chunks to include in context
    @Published var maxDocumentChunks: Int = 3
    
    // MARK: - Document Integration
    
    /// Add a document reference to the current conversation
    /// - Parameter document: Document to reference
    func addDocumentReference(_ document: Document) {
        // Check if document is already referenced
        guard !referencedDocuments.contains(where: { $0.id == document.id }) else {
            return
        }
        
        // Add to referenced documents
        referencedDocuments.append(document)
        
        // Add system message about the document
        let systemMessage = Message(
            role: .system,
            content: "Document added: \(document.title)"
        )
        
        // Add message to conversation
        conversationManager.addMessage(systemMessage)
        
        // Update conversation in Core Data
        Task {
            try? await updateConversationDocuments()
        }
    }
    
    /// Remove a document reference from the current conversation
    /// - Parameter document: Document to remove
    func removeDocumentReference(_ document: Document) {
        // Remove from referenced documents
        referencedDocuments.removeAll { $0.id == document.id }
        
        // Add system message about the document removal
        let systemMessage = Message(
            role: .system,
            content: "Document removed: \(document.title)"
        )
        
        // Add message to conversation
        conversationManager.addMessage(systemMessage)
        
        // Update conversation in Core Data
        Task {
            try? await updateConversationDocuments()
        }
    }
    
    /// Update the conversation's document references in Core Data
    private func updateConversationDocuments() async throws {
        guard let currentConversation = conversationManager.currentConversation else {
            return
        }
        
        // Get persistence controller
        let persistenceController = PersistenceController.shared
        
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Fetch the conversation
                    let fetchRequest = NSFetchRequest<CDConversation>(entityName: "CDConversation")
                    fetchRequest.predicate = NSPredicate(format: "id == %@", currentConversation.id as CVarArg)
                    
                    let results = try context.fetch(fetchRequest)
                    guard let cdConversation = results.first else {
                        throw DocumentError.documentNotFound
                    }
                    
                    // Fetch the documents
                    let documentIds = self.referencedDocuments.map { $0.id }
                    let documentFetchRequest = NSFetchRequest<CDDocument>(entityName: "CDDocument")
                    documentFetchRequest.predicate = NSPredicate(format: "id IN %@", documentIds)
                    
                    let cdDocuments = try context.fetch(documentFetchRequest)
                    
                    // Update the relationship
                    cdConversation.setValue(NSSet(array: cdDocuments), forKey: "documents")
                    
                    // Save context
                    try context.save()
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get document context for AI prompts
    /// - Returns: Document context string
    func getDocumentContext() -> String {
        guard includeDocumentContext && !referencedDocuments.isEmpty else {
            return ""
        }
        
        var context = "### Referenced Documents ###\n\n"
        
        for (index, document) in referencedDocuments.enumerated() {
            context += "Document \(index + 1): \(document.title)\n"
            
            // Add summary if available
            if let summary = document.summary {
                context += "Summary: \(summary)\n\n"
            }
            
            // Add relevant content chunks
            let chunks = getRelevantContentChunks(from: document)
            for (i, chunk) in chunks.enumerated() {
                context += "Excerpt \(i + 1):\n\"\(chunk)\"\n\n"
            }
            
            context += "---\n\n"
        }
        
        return context
    }
    
    /// Get relevant content chunks from a document based on recent messages
    /// - Parameter document: Document to get chunks from
    /// - Returns: Array of content chunks
    private func getRelevantContentChunks(from document: Document) -> [String] {
        // Get recent user messages
        let recentUserMessages = messages.suffix(5).filter { $0.role == .user }
        
        // If no recent messages, return the beginning of the document
        guard !recentUserMessages.isEmpty else {
            return [String(document.content.prefix(1000))]
        }
        
        // Combine recent messages into a query
        let query = recentUserMessages.map { $0.content }.joined(separator: " ")
        
        // Split document into chunks
        let chunks = splitIntoChunks(document.content, maxChunkSize: 1000, overlapSize: 100)
        
        // Score chunks based on relevance to query
        let scoredChunks = chunks.map { chunk -> (chunk: String, score: Double) in
            let score = calculateRelevanceScore(query: query, chunk: chunk)
            return (chunk: chunk, score: score)
        }
        
        // Sort by score and take top chunks
        let topChunks = scoredChunks.sorted { $0.score > $1.score }
            .prefix(maxDocumentChunks)
            .map { $0.chunk }
        
        return Array(topChunks)
    }
    
    /// Split text into chunks with overlap
    /// - Parameters:
    ///   - text: Text to split
    ///   - maxChunkSize: Maximum chunk size
    ///   - overlapSize: Overlap size between chunks
    /// - Returns: Array of text chunks
    private func splitIntoChunks(_ text: String, maxChunkSize: Int, overlapSize: Int) -> [String] {
        var chunks: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let endDistance = min(maxChunkSize, text.distance(from: startIndex, to: text.endIndex))
            let endIndex = text.index(startIndex, offsetBy: endDistance)
            
            let chunk = String(text[startIndex..<endIndex])
            chunks.append(chunk)
            
            // Move start index for next chunk, with overlap
            let nextStartDistance = max(0, endDistance - overlapSize)
            startIndex = text.index(startIndex, offsetBy: nextStartDistance)
        }
        
        return chunks
    }
    
    /// Calculate relevance score between query and chunk
    /// - Parameters:
    ///   - query: Search query
    ///   - chunk: Text chunk
    /// - Returns: Relevance score
    private func calculateRelevanceScore(query: String, chunk: String) -> Double {
        let queryWords = query.lowercased().split(separator: " ")
        let chunkLower = chunk.lowercased()
        
        var score = 0.0
        
        for word in queryWords {
            if chunkLower.contains(word) {
                score += 1.0
            }
        }
        
        return score / Double(queryWords.count)
    }
    
    /// Include document citations in AI responses
    /// - Parameter response: AI response text
    /// - Returns: Response with citations
    func includeDocumentCitations(in response: String) -> String {
        guard !referencedDocuments.isEmpty else {
            return response
        }
        
        var citedResponse = response
        
        // Add citations for each document mentioned
        for (index, document) in referencedDocuments.enumerated() {
            let documentTitle = document.title
            
            // Check if document title is mentioned in the response
            if citedResponse.localizedCaseInsensitiveContains(documentTitle) {
                // Add citation marker
                citedResponse = citedResponse.replacingOccurrences(
                    of: documentTitle,
                    with: "\(documentTitle) [Doc \(index + 1)]",
                    options: .caseInsensitive
                )
            }
        }
        
        // Add citation footer
        citedResponse += "\n\n---\nReferences:\n"
        for (index, document) in referencedDocuments.enumerated() {
            citedResponse += "[\(index + 1)] \(document.title)\n"
        }
        
        return citedResponse
    }
    
    /// Override sendMessage to include document context
    override func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Create user message
        let userMessage = Message(role: .user, content: inputText)
        
        // Add user message to conversation
        conversationManager.addMessage(userMessage)
        
        // Clear input text
        inputText = ""
        
        // Get context window for the selected model, including summary if needed
        var contextMessages = conversationManager.getContextWindowWithSummary(for: selectedModel)
        
        // Add document context if enabled
        if includeDocumentContext && !referencedDocuments.isEmpty {
            let documentContext = getDocumentContext()
            
            // Add document context as a system message
            if !documentContext.isEmpty {
                let documentContextMessage = Message(role: .system, content: documentContext)
                contextMessages.append(documentContextMessage)
            }
        }
        
        // Create request options
        let options = AIRequestOptions(
            model: selectedModel,
            temperature: temperature,
            maxTokens: nil,
            systemPrompt: nil,
            tools: nil
        )
        
        // Set generating flag
        isGenerating = true
        
        // Use streaming or non-streaming based on user preference
        if useStreaming {
            sendStreamingMessage(contextMessages: contextMessages, options: options)
        } else {
            sendNonStreamingMessage(contextMessages: contextMessages, options: options)
        }
    }
    
    /// Load referenced documents for a conversation
    /// - Parameter conversationId: Conversation ID
    func loadReferencedDocuments(for conversationId: UUID) async {
        // Get persistence controller
        let persistenceController = PersistenceController.shared
        
        do {
            let documents = try await withCheckedThrowingContinuation { continuation in
                persistenceController.performBackgroundTask { context in
                    do {
                        // Fetch the conversation
                        let fetchRequest = NSFetchRequest<CDConversation>(entityName: "CDConversation")
                        fetchRequest.predicate = NSPredicate(format: "id == %@", conversationId as CVarArg)
                        
                        let results = try context.fetch(fetchRequest)
                        guard let cdConversation = results.first else {
                            continuation.resume(throwing: DocumentError.documentNotFound)
                            return
                        }
                        
                        // Get referenced documents
                        guard let cdDocuments = cdConversation.value(forKey: "documents") as? NSSet else {
                            continuation.resume(returning: [])
                            return
                        }
                        
                        // Convert to Document models
                        let documents = cdDocuments.compactMap { document -> Document? in
                            guard let cdDocument = document as? CDDocument else { return nil }
                            return Document.from(cdDocument: cdDocument)
                        }
                        
                        continuation.resume(returning: documents)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Update referenced documents on main thread
            await MainActor.run {
                self.referencedDocuments = documents
            }
        } catch {
            print("Error loading referenced documents: \(error)")
        }
    }
}
