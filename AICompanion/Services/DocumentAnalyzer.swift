
//
//  DocumentAnalyzer.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import NaturalLanguage
import CoreML

/// Analyzer for document content
class DocumentAnalyzer {
    /// Shared instance for singleton access
    static let shared = DocumentAnalyzer()
    
    /// AI service for generating embeddings and summaries
    private let aiService = AIService.shared
    
    /// Initialize the document analyzer
    private init() {}
    
    /// Summarize a document
    /// - Parameter document: Document to summarize
    /// - Returns: Summary text
    func summarizeDocument(_ document: Document) async throws -> String {
        // Prepare the prompt for summarization
        let prompt = """
        Please provide a concise summary of the following document:
        
        Title: \(document.title)
        
        Content:
        \(document.content.prefix(10000)) // Limit content to avoid token limits
        
        Please include:
        1. Main topics and themes
        2. Key points or findings
        3. Important details
        
        Keep the summary under 500 words.
        """
        
        // Create request options
        let options = AIRequestOptions(
            model: aiService.getDefaultModel(),
            temperature: 0.3, // Lower temperature for more factual responses
            maxTokens: 1000,
            systemPrompt: "You are an expert document summarizer. Your task is to create concise, accurate summaries that capture the essential information from documents.",
            tools: nil
        )
        
        // Send request to AI service
        let messages = [Message(role: .user, content: prompt)]
        let response = try await aiService.sendMessage(messages: messages, options: options)
        
        return response.message.content
    }
    
    /// Generate an embedding for a document
    /// - Parameter document: Document to generate embedding for
    /// - Returns: Embedding data
    func generateEmbedding(for document: Document) async throws -> Data {
        // Prepare text for embedding
        // Use title and content, but limit length to avoid token limits
        let textForEmbedding = "\(document.title)\n\n\(document.content.prefix(10000))"
        
        // Generate embedding using AI service
        let embedding = try await aiService.generateEmbedding(text: textForEmbedding)
        
        // Convert embedding to Data
        return try JSONEncoder().encode(embedding)
    }
    
    /// Extract key information from a document
    /// - Parameter document: Document to analyze
    /// - Returns: Dictionary of key information
    func extractKeyInformation(from document: Document) async throws -> [String: Any] {
        // Prepare the prompt for information extraction
        let prompt = """
        Please extract key information from the following document:
        
        Title: \(document.title)
        
        Content:
        \(document.content.prefix(10000)) // Limit content to avoid token limits
        
        Extract the following information in JSON format:
        1. Main topics (array of strings)
        2. Key entities (people, organizations, locations)
        3. Dates mentioned
        4. Important facts or statistics
        5. Document type or category
        
        Format your response as valid JSON only, without any additional text.
        """
        
        // Create request options
        let options = AIRequestOptions(
            model: aiService.getDefaultModel(),
            temperature: 0.2, // Lower temperature for more factual responses
            maxTokens: 1000,
            systemPrompt: "You are an expert information extraction system. Extract structured information from documents and return it in valid JSON format only.",
            tools: nil
        )
        
        // Send request to AI service
        let messages = [Message(role: .user, content: prompt)]
        let response = try await aiService.sendMessage(messages: messages, options: options)
        
        // Parse JSON response
        guard let data = response.message.content.data(using: .utf8) else {
            throw AnalyzerError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AnalyzerError.invalidJSON
        }
        
        return json
    }
    
    /// Segment a document into sections
    /// - Parameter document: Document to segment
    /// - Returns: Array of document sections
    func segmentDocument(_ document: Document) async throws -> [DocumentSection] {
        // Use NLTokenizer to split document into paragraphs
        let tokenizer = NLTokenizer(unit: .paragraph)
        tokenizer.string = document.content
        
        var sections: [DocumentSection] = []
        var currentSectionTitle: String?
        var currentSectionContent = ""
        var currentStartIndex = 0
        
        tokenizer.enumerateTokens(in: document.content.startIndex..<document.content.endIndex) { tokenRange, _ in
            let paragraph = String(document.content[tokenRange])
            
            // Skip empty paragraphs
            guard !paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return true
            }
            
            // Check if paragraph is a heading
            if isHeading(paragraph) {
                // If we have content for the current section, save it
                if !currentSectionContent.isEmpty {
                    let section = DocumentSection(
                        id: UUID(),
                        title: currentSectionTitle,
                        content: currentSectionContent,
                        startIndex: currentStartIndex,
                        endIndex: document.content.distance(from: document.content.startIndex, to: tokenRange.lowerBound)
                    )
                    sections.append(section)
                }
                
                // Start a new section
                currentSectionTitle = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                currentSectionContent = ""
                currentStartIndex = document.content.distance(from: document.content.startIndex, to: tokenRange.lowerBound)
            } else {
                // Add paragraph to current section
                if !currentSectionContent.isEmpty {
                    currentSectionContent += "\n\n"
                }
                currentSectionContent += paragraph
            }
            
            return true
        }
        
        // Add the last section
        if !currentSectionContent.isEmpty {
            let section = DocumentSection(
                id: UUID(),
                title: currentSectionTitle,
                content: currentSectionContent,
                startIndex: currentStartIndex,
                endIndex: document.content.count
            )
            sections.append(section)
        }
        
        return sections
    }
    
    /// Check if a paragraph is a heading
    /// - Parameter paragraph: Paragraph to check
    /// - Returns: Whether the paragraph is a heading
    private func isHeading(_ paragraph: String) -> Bool {
        let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for Markdown headings
        if trimmed.hasPrefix("#") {
            return true
        }
        
        // Check for short, all-caps paragraphs
        if trimmed.count < 100 && trimmed.uppercased() == trimmed && trimmed.contains(where: { $0.isLetter }) {
            return true
        }
        
        // Check for numbered headings
        if trimmed.range(of: "^\\d+(\\.\\d+)*\\s+\\w+", options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
}

/// Analyzer errors
enum AnalyzerError: Error, LocalizedError {
    case invalidResponse
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service"
        case .invalidJSON:
            return "Invalid JSON in response"
        }
    }
}
