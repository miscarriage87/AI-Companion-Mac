
import Foundation
import Combine

/// Service for routing AI requests to the appropriate provider
class AIRouter {
    // MARK: - Shared Instance
    
    static let shared = AIRouter()
    
    // MARK: - Properties
    
    private let aiService = AIService.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Routing Methods
    
    /// Route a message to the appropriate AI provider
    /// - Parameters:
    ///   - messages: Array of messages in the conversation
    ///   - options: Options for the request
    /// - Returns: The AI response
    func routeMessage(messages: [Message], options: AIRequestOptions) async throws -> AIResponse {
        // Get the provider for the specified model
        guard let provider = aiService.getProvider(type: options.model.provider) else {
            throw AIRouterError.providerNotFound
        }
        
        do {
            // Send the message to the provider
            return try await provider.sendMessage(messages: messages, options: options)
        } catch {
            // If the primary provider fails, try a fallback provider
            if let fallbackResponse = try? await useFallbackProvider(messages: messages, options: options, originalError: error) {
                return fallbackResponse
            }
            
            // If fallback also fails, throw the original error
            throw error
        }
    }
    
    /// Route a streaming message to the appropriate AI provider
    /// - Parameters:
    ///   - messages: Array of messages in the conversation
    ///   - options: Options for the request
    ///   - onUpdate: Callback for each chunk of the streaming response
    /// - Returns: The final AI response
    func routeStreamingMessage(messages: [Message], options: AIRequestOptions, onUpdate: @escaping (AIResponseChunk) -> Void) async throws -> AIResponse {
        // Get the provider for the specified model
        guard let provider = aiService.getProvider(type: options.model.provider) else {
            throw AIRouterError.providerNotFound
        }
        
        do {
            // Stream the message to the provider
            return try await provider.streamMessage(messages: messages, options: options, onUpdate: onUpdate)
        } catch {
            // If the primary provider fails, try a fallback provider
            if let fallbackResponse = try? await useFallbackStreamingProvider(messages: messages, options: options, onUpdate: onUpdate, originalError: error) {
                return fallbackResponse
            }
            
            // If fallback also fails, throw the original error
            throw error
        }
    }
    
    // MARK: - Fallback Methods
    
    /// Use a fallback provider when the primary provider fails
    /// - Parameters:
    ///   - messages: Array of messages in the conversation
    ///   - options: Options for the request
    ///   - originalError: The error from the primary provider
    /// - Returns: The AI response from the fallback provider
    private func useFallbackProvider(messages: [Message], options: AIRequestOptions, originalError: Error) async throws -> AIResponse {
        // Log the original error
        print("Primary provider failed: \(originalError.localizedDescription)")
        
        // Get a fallback model
        guard let fallbackModel = getFallbackModel(for: options.model) else {
            throw AIRouterError.noFallbackAvailable
        }
        
        // Create new options with the fallback model
        var fallbackOptions = options
        fallbackOptions = AIRequestOptions(
            model: fallbackModel,
            temperature: options.temperature,
            maxTokens: options.maxTokens,
            systemPrompt: options.systemPrompt,
            tools: options.tools
        )
        
        // Get the fallback provider
        guard let fallbackProvider = aiService.getProvider(type: fallbackModel.provider) else {
            throw AIRouterError.providerNotFound
        }
        
        // Send the message to the fallback provider
        return try await fallbackProvider.sendMessage(messages: messages, options: fallbackOptions)
    }
    
    /// Use a fallback provider for streaming when the primary provider fails
    /// - Parameters:
    ///   - messages: Array of messages in the conversation
    ///   - options: Options for the request
    ///   - onUpdate: Callback for each chunk of the streaming response
    ///   - originalError: The error from the primary provider
    /// - Returns: The final AI response from the fallback provider
    private func useFallbackStreamingProvider(messages: [Message], options: AIRequestOptions, onUpdate: @escaping (AIResponseChunk) -> Void, originalError: Error) async throws -> AIResponse {
        // Log the original error
        print("Primary streaming provider failed: \(originalError.localizedDescription)")
        
        // Get a fallback model
        guard let fallbackModel = getFallbackModel(for: options.model) else {
            throw AIRouterError.noFallbackAvailable
        }
        
        // Create new options with the fallback model
        var fallbackOptions = options
        fallbackOptions = AIRequestOptions(
            model: fallbackModel,
            temperature: options.temperature,
            maxTokens: options.maxTokens,
            systemPrompt: options.systemPrompt,
            tools: options.tools
        )
        
        // Get the fallback provider
        guard let fallbackProvider = aiService.getProvider(type: fallbackModel.provider) else {
            throw AIRouterError.providerNotFound
        }
        
        // Notify the user about the fallback
        let fallbackNotification = AIResponseChunk(
            content: "\n[Switching to fallback model: \(fallbackModel.name)]\n",
            isComplete: false,
            finishReason: nil
        )
        onUpdate(fallbackNotification)
        
        // Stream the message to the fallback provider
        return try await fallbackProvider.streamMessage(messages: messages, options: fallbackOptions, onUpdate: onUpdate)
    }
    
    /// Get a fallback model for a given model
    /// - Parameter model: The original model
    /// - Returns: A fallback model, or nil if no fallback is available
    private func getFallbackModel(for model: AIModel) -> AIModel? {
        let availableModels = aiService.getAvailableModels()
        
        // If the current model is OpenAI, try Anthropic
        if model.provider == .openAI {
            return availableModels.first { $0.provider == .anthropic }
        }
        
        // If the current model is Anthropic, try OpenAI
        if model.provider == .anthropic {
            return availableModels.first { $0.provider == .openAI }
        }
        
        // If all else fails, use the mock provider
        return availableModels.first { $0.provider == .mockProvider }
    }
}

// MARK: - AI Router Error

/// Errors that can occur during AI routing
enum AIRouterError: Error, LocalizedError {
    case providerNotFound
    case noFallbackAvailable
    
    var errorDescription: String? {
        switch self {
        case .providerNotFound:
            return "AI provider not found"
        case .noFallbackAvailable:
            return "No fallback AI provider available"
        }
    }
}
