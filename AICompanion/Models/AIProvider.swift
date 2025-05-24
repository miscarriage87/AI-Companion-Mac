
//
//  AIProvider.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation

/// Represents an AI provider service that can be used for chat
struct AIProvider: Identifiable, Codable, Equatable {
    /// Unique identifier for the AI provider
    let id: UUID
    
    /// Name of the AI provider (e.g., "OpenAI", "Anthropic", etc.)
    let name: String
    
    /// Description of the AI provider
    let description: String
    
    /// Base URL for API requests
    let apiBaseURL: URL
    
    /// Whether this provider requires an API key
    let requiresAPIKey: Bool
    
    /// Available models from this provider
    let availableModels: [AIModel]
    
    /// Maximum context length supported by this provider
    let maxContextLength: Int
    
    /// Whether this provider is currently enabled
    var isEnabled: Bool
    
    init(id: UUID = UUID(), name: String, description: String, apiBaseURL: URL, requiresAPIKey: Bool = true, availableModels: [AIModel] = [], maxContextLength: Int = 4096, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.apiBaseURL = apiBaseURL
        self.requiresAPIKey = requiresAPIKey
        self.availableModels = availableModels
        self.maxContextLength = maxContextLength
        self.isEnabled = isEnabled
    }
    
    static func == (lhs: AIProvider, rhs: AIProvider) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents an AI model from a provider
struct AIModel: Identifiable, Codable, Equatable {
    /// Unique identifier for the model
    let id: UUID
    
    /// Model identifier used in API requests
    let modelId: String
    
    /// Display name for the model
    let displayName: String
    
    /// Description of the model's capabilities
    let description: String
    
    /// Maximum context length for this specific model
    let maxContextLength: Int
    
    /// Whether this model supports streaming responses
    let supportsStreaming: Bool
    
    /// Cost per 1000 input tokens
    let costPerInputToken: Double
    
    /// Cost per 1000 output tokens
    let costPerOutputToken: Double
    
    init(id: UUID = UUID(), modelId: String, displayName: String, description: String, maxContextLength: Int, supportsStreaming: Bool = true, costPerInputToken: Double = 0.0, costPerOutputToken: Double = 0.0) {
        self.id = id
        self.modelId = modelId
        self.displayName = displayName
        self.description = description
        self.maxContextLength = maxContextLength
        self.supportsStreaming = supportsStreaming
        self.costPerInputToken = costPerInputToken
        self.costPerOutputToken = costPerOutputToken
    }
    
    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.id == rhs.id
    }
}
