
import Foundation
import KeychainAccess
import Combine

// MARK: - AI Provider Protocol

/// Protocol defining the interface for AI providers
protocol AIProvider {
    /// Provider type
    var providerType: AIProviderType { get }
    
    /// Send a message to the AI provider and receive a response
    /// - Parameters:
    ///   - messages: Array of messages in the conversation
    ///   - options: Options for the request
    /// - Returns: The AI response
    func sendMessage(messages: [Message], options: AIRequestOptions) async throws -> AIResponse
    
    /// Stream a message to the AI provider and receive a streaming response
    /// - Parameters:
    ///   - messages: Array of messages in the conversation
    ///   - options: Options for the request
    ///   - onUpdate: Callback for each chunk of the streaming response
    /// - Returns: The final AI response
    func streamMessage(messages: [Message], options: AIRequestOptions, onUpdate: @escaping (AIResponseChunk) -> Void) async throws -> AIResponse
}

// MARK: - AI Provider Type

/// Enum representing different AI provider types
enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case mockProvider = "Mock Provider" // For testing
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

// MARK: - AI Model

/// Struct representing an AI model
struct AIModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let provider: AIProviderType
    let contextWindow: Int
    let capabilities: [AIModelCapability]
    
    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - AI Model Capability

/// Enum representing different AI model capabilities
enum AIModelCapability: String, Codable {
    case chat
    case imageGeneration
    case imageAnalysis
    case audioTranscription
    case toolUse
}

// MARK: - AI Request Options

/// Struct representing options for an AI request
struct AIRequestOptions {
    let model: AIModel
    let temperature: Double
    let maxTokens: Int?
    let systemPrompt: String?
    let tools: [AITool]?
    
    init(
        model: AIModel,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        systemPrompt: String? = nil,
        tools: [AITool]? = nil
    ) {
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.systemPrompt = systemPrompt
        self.tools = tools
    }
}

// MARK: - AI Tool

/// Struct representing a tool that can be used by the AI
struct AITool: Codable {
    let name: String
    let description: String
    let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case parameters
    }
    
    init(name: String, description: String, parameters: [String: Any]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        // Handle parameters as JSON
        let parametersString = try container.decode(String.self, forKey: .parameters)
        if let data = parametersString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            parameters = json
        } else {
            parameters = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        
        // Convert parameters to JSON string
        if let data = try? JSONSerialization.data(withJSONObject: parameters, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            try container.encode(jsonString, forKey: .parameters)
        } else {
            try container.encode("{}", forKey: .parameters)
        }
    }
}

// MARK: - Message

/// Struct representing a message in a conversation
struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Message Role

/// Enum representing different message roles
enum MessageRole: String, Codable {
    case system
    case user
    case assistant
    case tool
}

// MARK: - AI Response

/// Struct representing an AI response
struct AIResponse {
    let message: Message
    let usage: AITokenUsage?
    let finishReason: AIFinishReason?
}

// MARK: - AI Response Chunk

/// Struct representing a chunk of an AI streaming response
struct AIResponseChunk {
    let content: String
    let isComplete: Bool
    let finishReason: AIFinishReason?
}

// MARK: - AI Token Usage

/// Struct representing token usage information
struct AITokenUsage {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}

// MARK: - AI Finish Reason

/// Enum representing different finish reasons for an AI response
enum AIFinishReason: String, Codable {
    case stop
    case length
    case contentFilter
    case toolCalls
    case error
}

// MARK: - AI Service Error

/// Errors that can occur during AI service operations
enum AIServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case invalidResponseFormat
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please add your API key in Settings."
        case .invalidResponse:
            return "Invalid response from the server."
        case .invalidResponseFormat:
            return "Invalid response format from the server."
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - AI Service

/// Service for interacting with AI providers
class AIService {
    // MARK: - Shared Instance
    
    static let shared = AIService()
    
    // MARK: - Properties
    
    private var providers: [AIProviderType: AIProvider] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // Register providers
        registerProviders()
    }
    
    // MARK: - Provider Registration
    
    /// Register all available AI providers
    private func registerProviders() {
        // Register OpenAI provider
        providers[.openAI] = OpenAIProvider()
        
        // Register Anthropic provider
        providers[.anthropic] = AnthropicProvider()
        
        // Register mock provider for testing
        providers[.mockProvider] = MockAIProvider()
    }
    
    // MARK: - Provider Access
    
    /// Get an AI provider by type
    /// - Parameter type: The provider type
    /// - Returns: The AI provider
    func getProvider(type: AIProviderType) -> AIProvider? {
        return providers[type]
    }
    
    /// Get all available AI models
    /// - Returns: Array of available AI models
    func getAvailableModels() -> [AIModel] {
        var models: [AIModel] = []
        
        // OpenAI models
        models.append(contentsOf: [
            AIModel(
                id: "gpt-3.5-turbo",
                name: "GPT-3.5 Turbo",
                provider: .openAI,
                contextWindow: 16385,
                capabilities: [.chat]
            ),
            AIModel(
                id: "gpt-4",
                name: "GPT-4",
                provider: .openAI,
                contextWindow: 8192,
                capabilities: [.chat, .toolUse]
            ),
            AIModel(
                id: "gpt-4-turbo",
                name: "GPT-4 Turbo",
                provider: .openAI,
                contextWindow: 128000,
                capabilities: [.chat, .toolUse, .imageAnalysis]
            ),
            AIModel(
                id: "gpt-4o",
                name: "GPT-4o",
                provider: .openAI,
                contextWindow: 128000,
                capabilities: [.chat, .toolUse, .imageAnalysis]
            )
        ])
        
        // Anthropic models
        models.append(contentsOf: [
            AIModel(
                id: "claude-3-opus-20240229",
                name: "Claude 3 Opus",
                provider: .anthropic,
                contextWindow: 200000,
                capabilities: [.chat, .toolUse, .imageAnalysis]
            ),
            AIModel(
                id: "claude-3-sonnet-20240229",
                name: "Claude 3 Sonnet",
                provider: .anthropic,
                contextWindow: 200000,
                capabilities: [.chat, .toolUse, .imageAnalysis]
            ),
            AIModel(
                id: "claude-3-haiku-20240307",
                name: "Claude 3 Haiku",
                provider: .anthropic,
                contextWindow: 200000,
                capabilities: [.chat, .imageAnalysis]
            )
        ])
        
        // Mock model for testing
        models.append(
            AIModel(
                id: "mock-model",
                name: "Mock Model",
                provider: .mockProvider,
                contextWindow: 10000,
                capabilities: [.chat]
            )
        )
        
        return models
    }
    
    // MARK: - Default Model
    
    /// Get the default AI model
    /// - Returns: The default AI model
    func getDefaultModel() -> AIModel {
        return getAvailableModels().first { $0.id == "gpt-3.5-turbo" } ?? getAvailableModels().first!
    }
}

// MARK: - OpenAI Provider

/// Implementation of the AIProvider protocol for OpenAI
class OpenAIProvider: AIProvider {
    // MARK: - Properties
    
    let providerType: AIProviderType = .openAI
    private let keychain = KeychainAccess.Keychain(service: "com.aicompanion.settings")
    
    // MARK: - Methods
    
    func sendMessage(messages: [Message], options: AIRequestOptions) async throws -> AIResponse {
        // Get API key from keychain
        guard let apiKey = try? keychain.get("openai_api_key"), !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        // Create URL request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert our messages to OpenAI format
        let openAIMessages = messages.map { message -> [String: Any] in
            return [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
        
        // Create request body
        var requestBody: [String: Any] = [
            "model": options.model.id,
            "messages": openAIMessages,
            "temperature": options.temperature
        ]
        
        // Add max tokens if specified
        if let maxTokens = options.maxTokens {
            requestBody["max_tokens"] = maxTokens
        }
        
        // Add system prompt if specified
        if let systemPrompt = options.systemPrompt {
            let systemMessage: [String: Any] = [
                "role": "system",
                "content": systemPrompt
            ]
            var updatedMessages = openAIMessages
            updatedMessages.insert(systemMessage, at: 0)
            requestBody["messages"] = updatedMessages
        }
        
        // Add tools if specified
        if let tools = options.tools, !tools.isEmpty {
            let openAITools = tools.map { tool -> [String: Any] in
                return [
                    "type": "function",
                    "function": [
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": tool.parameters
                    ]
                ]
            }
            requestBody["tools"] = openAITools
        }
        
        // Encode request body
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              let usage = json["usage"] as? [String: Any],
              let promptTokens = usage["prompt_tokens"] as? Int,
              let completionTokens = usage["completion_tokens"] as? Int,
              let totalTokens = usage["total_tokens"] as? Int else {
            throw AIServiceError.invalidResponseFormat
        }
        
        // Get finish reason
        let finishReasonString = firstChoice["finish_reason"] as? String ?? "stop"
        let finishReason = AIFinishReason(rawValue: finishReasonString) ?? .stop
        
        // Create response
        let responseMessage = Message(role: .assistant, content: content)
        let tokenUsage = AITokenUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens
        )
        
        return AIResponse(
            message: responseMessage,
            usage: tokenUsage,
            finishReason: finishReason
        )
    }
    
    func streamMessage(messages: [Message], options: AIRequestOptions, onUpdate: @escaping (AIResponseChunk) -> Void) async throws -> AIResponse {
        // Get API key from keychain
        guard let apiKey = try? keychain.get("openai_api_key"), !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        // Create URL request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert our messages to OpenAI format
        let openAIMessages = messages.map { message -> [String: Any] in
            return [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
        
        // Create request body
        var requestBody: [String: Any] = [
            "model": options.model.id,
            "messages": openAIMessages,
            "temperature": options.temperature,
            "stream": true
        ]
        
        // Add max tokens if specified
        if let maxTokens = options.maxTokens {
            requestBody["max_tokens"] = maxTokens
        }
        
        // Add system prompt if specified
        if let systemPrompt = options.systemPrompt {
            let systemMessage: [String: Any] = [
                "role": "system",
                "content": systemPrompt
            ]
            var updatedMessages = openAIMessages
            updatedMessages.insert(systemMessage, at: 0)
            requestBody["messages"] = updatedMessages
        }
        
        // Add tools if specified
        if let tools = options.tools, !tools.isEmpty {
            let openAITools = tools.map { tool -> [String: Any] in
                return [
                    "type": "function",
                    "function": [
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": tool.parameters
                    ]
                ]
            }
            requestBody["tools"] = openAITools
        }
        
        // Encode request body
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send streaming request
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.httpError(httpResponse.statusCode)
        }
        
        // Process streaming response
        var fullContent = ""
        var finishReason: AIFinishReason?
        
        for try await line in asyncBytes.lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }
            
            // Skip "data: [DONE]" message
            if line == "data: [DONE]" {
                break
            }
            
            // Remove "data: " prefix
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = line.dropFirst(6)
            
            // Parse JSON
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first else {
                continue
            }
            
            // Extract content delta
            if let delta = firstChoice["delta"] as? [String: Any],
               let content = delta["content"] as? String {
                fullContent += content
                
                let chunk = AIResponseChunk(
                    content: content,
                    isComplete: false,
                    finishReason: nil
                )
                
                onUpdate(chunk)
            }
            
            // Check for finish reason
            if let finishReasonString = firstChoice["finish_reason"] as? String,
               !finishReasonString.isEmpty,
               let reason = AIFinishReason(rawValue: finishReasonString) {
                finishReason = reason
                
                let chunk = AIResponseChunk(
                    content: "",
                    isComplete: true,
                    finishReason: reason
                )
                
                onUpdate(chunk)
            }
        }
        
        // Create final response
        let responseMessage = Message(role: .assistant, content: fullContent)
        
        // We don't get token usage in streaming responses, so estimate it
        let promptTokens = estimateTokenCount(for: messages)
        let completionTokens = estimateTokenCount(for: [responseMessage])
        
        let tokenUsage = AITokenUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: promptTokens + completionTokens
        )
        
        return AIResponse(
            message: responseMessage,
            usage: tokenUsage,
            finishReason: finishReason ?? .stop
        )
    }
    
    // Helper method to estimate token count
    private func estimateTokenCount(for messages: [Message]) -> Int {
        // Simple estimation: ~4 chars per token
        let totalChars = messages.reduce(0) { $0 + $1.content.count }
        return totalChars / 4
    }
}

// MARK: - Anthropic Provider

/// Implementation of the AIProvider protocol for Anthropic
class AnthropicProvider: AIProvider {
    // MARK: - Properties
    
    let providerType: AIProviderType = .anthropic
    private let keychain = KeychainAccess.Keychain(service: "com.aicompanion.settings")
    
    // MARK: - Methods
    
    func sendMessage(messages: [Message], options: AIRequestOptions) async throws -> AIResponse {
        // Get API key from keychain
        guard let apiKey = try? keychain.get("anthropic_api_key"), !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        // Create URL request
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("anthropic-swift/1.0", forHTTPHeaderField: "anthropic-version")
        
        // Convert our messages to Anthropic format
        var anthropicMessages: [[String: Any]] = []
        
        for message in messages {
            // Skip system messages as they're handled differently in Anthropic
            if message.role == .system {
                continue
            }
            
            anthropicMessages.append([
                "role": message.role == .assistant ? "assistant" : "user",
                "content": message.content
            ])
        }
        
        // Create request body
        var requestBody: [String: Any] = [
            "model": options.model.id,
            "messages": anthropicMessages,
            "temperature": options.temperature
        ]
        
        // Add max tokens if specified
        if let maxTokens = options.maxTokens {
            requestBody["max_tokens"] = maxTokens
        }
        
        // Add system prompt if specified
        if let systemPrompt = options.systemPrompt {
            requestBody["system"] = systemPrompt
        } else {
            // Find system message in our messages
            if let systemMessage = messages.first(where: { $0.role == .system }) {
                requestBody["system"] = systemMessage.content
            }
        }
        
        // Encode request body
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIServiceError.invalidResponseFormat
        }
        
        // Get finish reason
        let finishReasonString = json["stop_reason"] as? String ?? "stop"
        let finishReason = AIFinishReason(rawValue: finishReasonString) ?? .stop
        
        // Create response
        let responseMessage = Message(role: .assistant, content: text)
        
        // Anthropic doesn't provide token usage, so estimate it
        let promptTokens = estimateTokenCount(for: messages)
        let completionTokens = estimateTokenCount(for: [responseMessage])
        
        let tokenUsage = AITokenUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: promptTokens + completionTokens
        )
        
        return AIResponse(
            message: responseMessage,
            usage: tokenUsage,
            finishReason: finishReason
        )
    }
    
    func streamMessage(messages: [Message], options: AIRequestOptions, onUpdate: @escaping (AIResponseChunk) -> Void) async throws -> AIResponse {
        // Get API key from keychain
        guard let apiKey = try? keychain.get("anthropic_api_key"), !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        // Create URL request
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("anthropic-swift/1.0", forHTTPHeaderField: "anthropic-version")
        
        // Convert our messages to Anthropic format
        var anthropicMessages: [[String: Any]] = []
        
        for message in messages {
            // Skip system messages as they're handled differently in Anthropic
            if message.role == .system {
                continue
            }
            
            anthropicMessages.append([
                "role": message.role == .assistant ? "assistant" : "user",
                "content": message.content
            ])
        }
        
        // Create request body
        var requestBody: [String: Any] = [
            "model": options.model.id,
            "messages": anthropicMessages,
            "temperature": options.temperature,
            "stream": true
        ]
        
        // Add max tokens if specified
        if let maxTokens = options.maxTokens {
            requestBody["max_tokens"] = maxTokens
        }
        
        // Add system prompt if specified
        if let systemPrompt = options.systemPrompt {
            requestBody["system"] = systemPrompt
        } else {
            // Find system message in our messages
            if let systemMessage = messages.first(where: { $0.role == .system }) {
                requestBody["system"] = systemMessage.content
            }
        }
        
        // Encode request body
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send streaming request
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.httpError(httpResponse.statusCode)
        }
        
        // Process streaming response
        var fullContent = ""
        var finishReason: AIFinishReason?
        
        for try await line in asyncBytes.lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }
            
            // Skip "data: [DONE]" message
            if line == "data: [DONE]" {
                break
            }
            
            // Remove "data: " prefix
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = line.dropFirst(6)
            
            // Parse JSON
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            
            // Extract content delta
            if let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                fullContent += text
                
                let chunk = AIResponseChunk(
                    content: text,
                    isComplete: false,
                    finishReason: nil
                )
                
                onUpdate(chunk)
            }
            
            // Check for finish reason
            if let stopReason = json["stop_reason"] as? String,
               !stopReason.isEmpty {
                if let reason = AIFinishReason(rawValue: stopReason) {
                    finishReason = reason
                } else {
                    finishReason = .stop
                }
                
                let chunk = AIResponseChunk(
                    content: "",
                    isComplete: true,
                    finishReason: finishReason
                )
                
                onUpdate(chunk)
            }
        }
        
        // Create final response
        let responseMessage = Message(role: .assistant, content: fullContent)
        
        // Anthropic doesn't provide token usage, so estimate it
        let promptTokens = estimateTokenCount(for: messages)
        let completionTokens = estimateTokenCount(for: [responseMessage])
        
        let tokenUsage = AITokenUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: promptTokens + completionTokens
        )
        
        return AIResponse(
            message: responseMessage,
            usage: tokenUsage,
            finishReason: finishReason ?? .stop
        )
    }
    
    // Helper method to estimate token count
    private func estimateTokenCount(for messages: [Message]) -> Int {
        // Simple estimation: ~4 chars per token
        let totalChars = messages.reduce(0) { $0 + $1.content.count }
        return totalChars / 4
    }
}

// MARK: - Mock AI Provider

/// Mock implementation of the AIProvider protocol for testing
class MockAIProvider: AIProvider {
    // MARK: - Properties
    
    let providerType: AIProviderType = .mockProvider
    
    // MARK: - Methods
    
    func sendMessage(messages: [Message], options: AIRequestOptions) async throws -> AIResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Create a mock response
        let responseContent = "This is a mock response for testing. You said: \(messages.last?.content ?? "")"
        let responseMessage = Message(role: .assistant, content: responseContent)
        
        let usage = AITokenUsage(
            promptTokens: 50,
            completionTokens: 25,
            totalTokens: 75
        )
        
        return AIResponse(
            message: responseMessage,
            usage: usage,
            finishReason: .stop
        )
    }
    
    func streamMessage(messages: [Message], options: AIRequestOptions, onUpdate: @escaping (AIResponseChunk) -> Void) async throws -> AIResponse {
        var fullResponse = ""
        let mockResponse = "This is a mock streaming response for testing. You said: \(messages.last?.content ?? "")"
        
        // Simulate streaming by sending chunks of the response
        for i in 0..<mockResponse.count {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 50_000_000)
            
            let index = mockResponse.index(mockResponse.startIndex, offsetBy: i)
            let character = String(mockResponse[index])
            fullResponse += character
            
            let chunk = AIResponseChunk(
                content: character,
                isComplete: i == mockResponse.count - 1,
                finishReason: i == mockResponse.count - 1 ? .stop : nil
            )
            
            onUpdate(chunk)
        }
        
        let responseMessage = Message(role: .assistant, content: fullResponse)
        
        let usage = AITokenUsage(
            promptTokens: 50,
            completionTokens: 25,
            totalTokens: 75
        )
        
        return AIResponse(
            message: responseMessage,
            usage: usage,
            finishReason: .stop
        )
    }
}
