//
//  AIService.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation

/// Service for interacting with AI providers
class AIService {
    /// Available AI providers
    private var providers: [AIProvider] = []
    
    /// Storage service for persisting provider data
    private let storageService: StorageService
    
    /// Current generation task that can be cancelled
    private var currentGenerationTask: Task<String, Error>?
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        
        // Load providers from storage or create defaults
        loadProviders()
    }
    
    /// Load AI providers from storage or create defaults
    private func loadProviders() {
        // Try to load providers from storage
        let storedProviders = storageService.loadAIProviders()
        
        if !storedProviders.isEmpty {
            providers = storedProviders
        } else {
            // Create default providers
            providers = SampleData.getSampleAIProviders()
            
            // Save default providers
            for provider in providers {
                storageService.saveAIProvider(provider)
            }
        }
    }
    
    /// Get all available AI providers
    func getAvailableProviders() -> [AIProvider] {
        return providers
    }
    
    /// Get a specific AI provider by ID
    func getProvider(id: UUID) throws -> AIProvider {
        guard let provider = providers.first(where: { $0.id == id }) else {
            throw AIServiceError.providerNotFound
        }
        
        return provider
    }
    
    /// Get the default AI provider
    func getDefaultProvider() -> AIProvider {
        // Return the first enabled provider or the first provider if none are enabled
        return providers.first(where: { $0.isEnabled }) ?? providers.first!
    }
    
    /// Update an AI provider
    func updateProvider(_ provider: AIProvider) {
        // Update the provider in the list
        if let index = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[index] = provider
        } else {
            providers.append(provider)
        }
        
        // Save the updated provider
        storageService.saveAIProvider(provider)
    }
    
    /// Generate a response from an AI provider
    func generateResponse(messages: [Message], provider: AIProvider) async throws -> String {
        // Cancel any existing generation task
        cancelCurrentGeneration()
        
        // Create a new generation task
        let task = Task<String, Error> { [weak self] in
            // In a real app, this would make an API request to the provider
            // For now, we'll just return a simulated response
            
            // Check if the provider is enabled
            guard provider.isEnabled else {
                throw AIServiceError.providerDisabled
            }
            
            // Check if an API key is required and available
            if provider.requiresAPIKey {
                let apiKey = self?.storageService.loadUser()?.apiKeys[provider.id.uuidString]
                guard apiKey != nil && !apiKey!.isEmpty else {
                    throw AIServiceError.missingAPIKey
                }
            }
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Check if the task was cancelled
            try Task.checkCancellation()
            
            // Generate a response based on the last user message
            let lastMessage = messages.last(where: { $0.isFromUser })?.content ?? ""
            
            // Generate different responses based on the content of the message
            if lastMessage.lowercased().contains("hello") || lastMessage.lowercased().contains("hi") {
                return "Hello! I'm an AI assistant powered by \(provider.name). How can I help you today?"
            } else if lastMessage.lowercased().contains("weather") {
                return "I don't have access to real-time weather data, but I can help you find weather information online or discuss weather-related topics. What specifically would you like to know about the weather?"
            } else if lastMessage.lowercased().contains("code") || lastMessage.lowercased().contains("programming") {
                return "I'd be happy to help with programming! I can explain concepts, debug code, or suggest implementations. What programming language or concept are you working with?"
            } else if lastMessage.lowercased().contains("thank") {
                return "You're welcome! If you have any other questions or need assistance with anything else, feel free to ask."
            } else {
                // Default response with markdown formatting
                return """
                I understand you're asking about "\(lastMessage.prefix(30))...". Here's my response:
                
                ## Key Points
                
                1. This is a simulated response from \(provider.name)
                2. In a real implementation, this would be generated by the AI model
                3. The response would be more relevant to your specific query
                
                ```swift
                // Here's how you might implement this in Swift:
                func generateResponse(for query: String) -> String {
                    // AI processing would happen here
                    return "Intelligent response based on: \\(query)"
                }
                ```
                
                Would you like to know more about this topic? I'm happy to elaborate further or discuss related concepts.
                """
            }
        }
        
        // Store the task
        currentGenerationTask = task
        
        // Await the result
        return try await task.value
    }
    
    /// Cancel the current generation task
    func cancelCurrentGeneration() {
        currentGenerationTask?.cancel()
        currentGenerationTask = nil
    }
    
    /// Validate an API key for a provider
    func validateAPIKey(_ apiKey: String, for provider: AIProvider) async throws -> Bool {
        // In a real app, this would make a test API request to validate the key
        // For now, we'll just simulate validation
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Simple validation: key must be at least 20 characters
        return apiKey.count >= 20
    }
    
    /// Errors that can occur in the AI service
    enum AIServiceError: Error, LocalizedError {
        case providerNotFound
        case providerDisabled
        case missingAPIKey
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .providerNotFound:
                return "AI provider not found"
            case .providerDisabled:
                return "AI provider is disabled"
            case .missingAPIKey:
                return "API key is required but not provided"
            case .apiError(let message):
                return "API error: \(message)"
            }
        }
    }
}
