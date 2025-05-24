
import Foundation
import Combine
import AVFoundation

class ChatViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Messages in the current conversation
    @Published var messages: [Message] = []
    
    /// Text being typed by the user
    @Published var inputText: String = ""
    
    /// Whether the AI is currently generating a response
    @Published var isGenerating: Bool = false
    
    /// Error message to display
    @Published var errorMessage: String? = nil
    
    /// Whether to show the error alert
    @Published var showError: Bool = false
    
    /// Current AI model
    @Published var selectedModel: AIModel
    
    /// Available AI models
    @Published var availableModels: [AIModel] = []
    
    /// Temperature setting for AI responses
    @Published var temperature: Double = 0.7
    
    /// Whether to use streaming for AI responses
    @Published var useStreaming: Bool = true
    
    // MARK: - Voice Settings
    
    /// Whether voice input is enabled
    @Published var isVoiceInputEnabled: Bool = true
    
    /// Whether continuous listening mode is enabled
    @Published var isContinuousListeningEnabled: Bool = false
    
    /// Voice input timeout in seconds
    @Published var voiceInputTimeout: Double = 10
    
    /// Whether voice output is enabled
    @Published var isVoiceOutputEnabled: Bool = true
    
    /// Whether to automatically read AI responses
    @Published var autoReadResponses: Bool = false
    
    /// Selected voice identifier for speech synthesis
    @Published var selectedVoiceIdentifier: String?
    
    /// Speech rate (0.0 - 1.0)
    @Published var speechRate: Float = 0.5
    
    /// Speech pitch (0.5 - 2.0)
    @Published var speechPitch: Float = 1.0
    
    /// Speech volume (0.0 - 1.0)
    @Published var speechVolume: Float = 1.0
    
    /// Whether voice commands are enabled
    @Published var isVoiceCommandsEnabled: Bool = true
    
    /// Conversation manager
    private let conversationManager = ConversationManager.shared
    
    /// AI router
    private let aiRouter = AIRouter.shared
    
    /// AI service
    private let aiService = AIService.shared
    
    /// User defaults for settings
    private let userDefaults = UserDefaults.standard
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Get available models
        availableModels = aiService.getAvailableModels()
        
        // Set default model
        selectedModel = aiService.getDefaultModel()
        
        // Load voice settings
        loadVoiceSettings()
        
        // Subscribe to conversation manager updates
        conversationManager.$currentConversation
            .sink { [weak self] conversation in
                self?.messages = conversation.messages
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Voice Settings
    
    /// Load voice settings from UserDefaults
    func loadVoiceSettings() {
        isVoiceInputEnabled = userDefaults.bool(forKey: "voice_input_enabled")
        isContinuousListeningEnabled = userDefaults.bool(forKey: "continuous_listening_enabled")
        voiceInputTimeout = userDefaults.double(forKey: "voice_input_timeout")
        
        isVoiceOutputEnabled = userDefaults.bool(forKey: "voice_output_enabled")
        autoReadResponses = userDefaults.bool(forKey: "auto_read_responses")
        selectedVoiceIdentifier = userDefaults.string(forKey: "selected_voice_identifier")
        
        speechRate = userDefaults.float(forKey: "speech_rate")
        speechPitch = userDefaults.float(forKey: "speech_pitch")
        speechVolume = userDefaults.float(forKey: "speech_volume")
        
        isVoiceCommandsEnabled = userDefaults.bool(forKey: "voice_commands_enabled")
        
        // Set default values if not already set
        if voiceInputTimeout == 0 {
            voiceInputTimeout = 10
        }
        
        if speechRate == 0 {
            speechRate = 0.5
        }
        
        if speechPitch == 0 {
            speechPitch = 1.0
        }
        
        if speechVolume == 0 {
            speechVolume = 1.0
        }
        
        // Set default values for boolean settings
        if !userDefaults.bool(forKey: "voice_settings_initialized") {
            isVoiceInputEnabled = true
            isVoiceOutputEnabled = true
            isVoiceCommandsEnabled = true
            
            // Save default settings
            userDefaults.set(isVoiceInputEnabled, forKey: "voice_input_enabled")
            userDefaults.set(isVoiceOutputEnabled, forKey: "voice_output_enabled")
            userDefaults.set(isVoiceCommandsEnabled, forKey: "voice_commands_enabled")
            userDefaults.set(true, forKey: "voice_settings_initialized")
        }
    }
    
    /// Save voice settings to UserDefaults
    func saveVoiceSettings() {
        userDefaults.set(isVoiceInputEnabled, forKey: "voice_input_enabled")
        userDefaults.set(isContinuousListeningEnabled, forKey: "continuous_listening_enabled")
        userDefaults.set(voiceInputTimeout, forKey: "voice_input_timeout")
        
        userDefaults.set(isVoiceOutputEnabled, forKey: "voice_output_enabled")
        userDefaults.set(autoReadResponses, forKey: "auto_read_responses")
        
        if let voiceIdentifier = selectedVoiceIdentifier {
            userDefaults.set(voiceIdentifier, forKey: "selected_voice_identifier")
        }
        
        userDefaults.set(speechRate, forKey: "speech_rate")
        userDefaults.set(speechPitch, forKey: "speech_pitch")
        userDefaults.set(speechVolume, forKey: "speech_volume")
        
        userDefaults.set(isVoiceCommandsEnabled, forKey: "voice_commands_enabled")
    }
    
    // MARK: - Message Handling
    
    /// Send a message to the AI
    func sendMessage() {
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
        let contextMessages = conversationManager.getContextWindowWithSummary(for: selectedModel)
        
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
    
    /// Send a non-streaming message to the AI
    /// - Parameters:
    ///   - contextMessages: Messages to include in the context
    ///   - options: Request options
    private func sendNonStreamingMessage(contextMessages: [Message], options: AIRequestOptions) {
        Task {
            do {
                // Send message to AI router
                let response = try await aiRouter.routeMessage(messages: contextMessages, options: options)
                
                // Update UI on main thread
                await MainActor.run {
                    // Add AI response to conversation
                    conversationManager.addMessage(response.message)
                    
                    // Reset generating flag
                    isGenerating = false
                }
            } catch {
                // Handle error
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isGenerating = false
                }
            }
        }
    }
    
    /// Send a streaming message to the AI
    /// - Parameters:
    ///   - contextMessages: Messages to include in the context
    ///   - options: Request options
    private func sendStreamingMessage(contextMessages: [Message], options: AIRequestOptions) {
        // Create a placeholder message for the AI response
        let placeholderMessage = Message(role: .assistant, content: "")
        conversationManager.addMessage(placeholderMessage)
        
        // Keep track of the full response content
        var responseContent = ""
        
        Task {
            do {
                // Send streaming message to AI router
                let response = try await aiRouter.routeStreamingMessage(
                    messages: contextMessages,
                    options: options,
                    onUpdate: { [weak self] chunk in
                        // Update response content
                        responseContent += chunk.content
                        
                        // Update the placeholder message with the current content
                        Task { @MainActor in
                            // Find the index of the placeholder message
                            if let index = self?.messages.firstIndex(where: { $0.id == placeholderMessage.id }) {
                                // Create an updated message
                                let updatedMessage = Message(
                                    id: placeholderMessage.id,
                                    role: .assistant,
                                    content: responseContent,
                                    timestamp: placeholderMessage.timestamp
                                )
                                
                                // Replace the placeholder message
                                self?.messages[index] = updatedMessage
                            }
                        }
                    }
                )
                
                // Update UI on main thread
                await MainActor.run {
                    // Find the index of the placeholder message
                    if let index = messages.firstIndex(where: { $0.id == placeholderMessage.id }) {
                        // Create the final message
                        let finalMessage = Message(
                            id: placeholderMessage.id,
                            role: .assistant,
                            content: response.message.content,
                            timestamp: placeholderMessage.timestamp
                        )
                        
                        // Replace the placeholder message
                        messages[index] = finalMessage
                        
                        // Update the conversation manager
                        conversationManager.addMessage(finalMessage)
                    }
                    
                    // Reset generating flag
                    isGenerating = false
                }
            } catch {
                // Handle error
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isGenerating = false
                    
                    // Remove the placeholder message
                    messages.removeAll { $0.id == placeholderMessage.id }
                }
            }
        }
    }
    
    /// Regenerate the last AI response
    func regenerateResponse() {
        // Find the last user message and AI response
        guard let lastUserMessageIndex = messages.lastIndex(where: { $0.role == .user }),
              lastUserMessageIndex < messages.count - 1 else {
            return
        }
        
        // Remove the last AI response
        _ = messages[lastUserMessageIndex]
        messages.removeLast(messages.count - lastUserMessageIndex - 1)
        
        // Get context window for the selected model, including summary if needed
        let contextMessages = conversationManager.getContextWindowWithSummary(for: selectedModel)
        
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
    
    // MARK: - Conversation Management
    
    /// Create a new conversation
    func newConversation() {
        _ = conversationManager.createNewConversation()
    }
    
    /// Clear the current conversation
    func clearConversation() {
        conversationManager.clearCurrentConversation()
    }
    
    // MARK: - Conversation Summarization
    
    /// Check if the current conversation needs summarization
    var conversationNeedsSummarization: Bool {
        return conversationManager.conversationNeedsSummarization(conversationManager.currentConversation, for: selectedModel)
    }
    
    /// Get the estimated token count for the current conversation
    var currentConversationTokenCount: Int {
        return TokenCounter.shared.estimateTokenCount(for: messages)
    }
    
    /// Get the token limit for the current model
    var currentModelTokenLimit: Int {
        return selectedModel.contextWindow
    }
    
    /// Manually trigger conversation summarization
    func summarizeConversation() async {
        isGenerating = true
        
        do {
            let summary = try await conversationManager.summarizeConversationWithAI(conversationManager.currentConversation)
            
            await MainActor.run {
                // Show a notification that summarization was successful
                let summaryMessage = Message(
                    role: .system,
                    content: "Conversation summarized successfully. \(summary.summarizedMessageIds.count) messages have been summarized."
                )
                
                // Add the summary message temporarily
                messages.append(summaryMessage)
                
                // Remove it after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.messages.removeAll { $0.id == summaryMessage.id }
                }
                
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to summarize conversation: \(error.localizedDescription)"
                showError = true
                isGenerating = false
            }
        }
    }
}
