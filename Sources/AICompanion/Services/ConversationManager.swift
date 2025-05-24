
import Foundation

/// Manager for handling conversation history and context
class ConversationManager {
    // MARK: - Shared Instance
    
    static let shared = ConversationManager()
    
    // MARK: - Properties
    
    /// Current conversation
    @Published private(set) var currentConversation: Conversation
    
    /// All conversations
    @Published private(set) var conversations: [Conversation] = []
    
    // MARK: - Initialization
    
    private init() {
        // Create a new conversation
        currentConversation = Conversation(id: UUID(), title: "New Conversation", messages: [])
        conversations = [currentConversation]
        
        // Load conversations from storage
        loadConversations()
    }
    
    // MARK: - Conversation Management
    
    /// Create a new conversation
    /// - Parameter title: Title for the new conversation
    /// - Returns: The new conversation
    func createNewConversation(title: String = "New Conversation") -> Conversation {
        let newConversation = Conversation(id: UUID(), title: title, messages: [])
        conversations.append(newConversation)
        currentConversation = newConversation
        saveConversations()
        return newConversation
    }
    
    /// Set the current conversation
    /// - Parameter conversation: The conversation to set as current
    func setCurrentConversation(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            return
        }
        currentConversation = conversations[index]
    }
    
    /// Add a message to the current conversation
    /// - Parameter message: The message to add
    func addMessage(_ message: Message) {
        currentConversation.messages.append(message)
        
        // If this is the second message (first user message), generate a title
        if currentConversation.messages.count == 2 && message.role == .user {
            generateTitle(from: message.content)
        }
        
        saveConversations()
    }
    
    /// Delete a conversation
    /// - Parameter conversation: The conversation to delete
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        
        // If the deleted conversation was the current one, set a new current conversation
        if currentConversation.id == conversation.id && !conversations.isEmpty {
            currentConversation = conversations[0]
        } else if conversations.isEmpty {
            // If no conversations left, create a new one
            createNewConversation()
        }
        
        saveConversations()
    }
    
    /// Clear the messages in the current conversation
    func clearCurrentConversation() {
        currentConversation.messages.removeAll()
        currentConversation.title = "New Conversation"
        saveConversations()
    }
    
    // MARK: - Context Management
    
    /// Get the context window for a given model
    /// - Parameter model: The AI model
    /// - Returns: Array of messages that fit within the model's context window
    func getContextWindow(for model: AIModel) -> [Message] {
        let messages = currentConversation.messages
        
        // If all messages fit within the context window, return them all
        if estimateTokenCount(for: messages) <= model.contextWindow {
            return messages
        }
        
        // Otherwise, we need to truncate the context
        return truncateContext(messages: messages, maxTokens: model.contextWindow)
    }
    
    /// Estimate the token count for an array of messages
    /// - Parameter messages: The messages to estimate tokens for
    /// - Returns: Estimated token count
    func estimateTokenCount(for messages: [Message]) -> Int {
        // Simple estimation: ~4 chars per token
        let totalChars = messages.reduce(0) { $0 + $1.content.count }
        return totalChars / 4
    }
    
    /// Truncate the context to fit within a token limit
    /// - Parameters:
    ///   - messages: The messages to truncate
    ///   - maxTokens: The maximum number of tokens
    /// - Returns: Truncated array of messages
    private func truncateContext(messages: [Message], maxTokens: Int) -> [Message] {
        var result: [Message] = []
        var tokenCount = 0
        
        // Always include the system message if present
        if let systemMessage = messages.first(where: { $0.role == .system }) {
            result.append(systemMessage)
            tokenCount += estimateTokenCount(for: [systemMessage])
        }
        
        // Add messages from newest to oldest until we reach the token limit
        for message in messages.reversed() {
            if message.role == .system {
                continue // Already added system message
            }
            
            let messageTokens = estimateTokenCount(for: [message])
            if tokenCount + messageTokens <= maxTokens {
                result.insert(message, at: 0)
                tokenCount += messageTokens
            } else {
                break
            }
        }
        
        // If we couldn't add any messages, add at least the most recent one
        if result.isEmpty || (result.count == 1 && result[0].role == .system) {
            let lastMessage = messages.last!
            result.append(lastMessage)
        }
        
        return result
    }
    
    // MARK: - Conversation Summarization
    
    /// Generate a title for the current conversation based on the first user message
    /// - Parameter content: The content of the first user message
    private func generateTitle(from content: String) {
        // For now, just use the first few words of the message
        let words = content.split(separator: " ")
        let titleWords = words.prefix(4).joined(separator: " ")
        let title = titleWords + (words.count > 4 ? "..." : "")
        
        currentConversation.title = title
        saveConversations()
        
        // Generate a better title using AI
        Task {
            do {
                let aiTitle = try await generateTitleWithAI(from: content)
                await MainActor.run {
                    currentConversation.title = aiTitle
                    saveConversations()
                }
            } catch {
                print("Error generating title: \(error.localizedDescription)")
            }
        }
    }
    
    /// Generate a title for a conversation using AI
    /// - Parameter content: The content to base the title on
    /// - Returns: AI-generated title
    private func generateTitleWithAI(from content: String) async throws -> String {
        // Create a system prompt for title generation
        let systemPrompt = "You are a helpful assistant that generates concise, descriptive titles for conversations. Create a short title (5 words or less) that captures the essence of the user's message."
        
        // Create a message for the AI
        let messages = [
            Message(role: .system, content: systemPrompt),
            Message(role: .user, content: content)
        ]
        
        // Get the default model
        let model = AIService.shared.getDefaultModel()
        
        // Create request options
        let options = AIRequestOptions(
            model: model,
            temperature: 0.7,
            maxTokens: 10,
            systemPrompt: systemPrompt
        )
        
        // Send the request to the AI router
        let response = try await AIRouter.shared.routeMessage(messages: messages, options: options)
        
        // Extract the title from the response
        let title = response.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If the title is empty or too long, use the default title
        if title.isEmpty || title.count > 50 {
            let words = content.split(separator: " ")
            let titleWords = words.prefix(4).joined(separator: " ")
            return titleWords + (words.count > 4 ? "..." : "")
        }
        
        return title
    }
    
    /// Summarize a conversation
    /// - Parameter conversation: The conversation to summarize
    /// - Returns: A summary of the conversation
    func summarizeConversation(_ conversation: Conversation) -> String {
        // Default summary if AI summarization fails
        return "A conversation about \(conversation.title) with \(conversation.messages.count) messages."
    }
    
    /// Summarize a conversation using AI
    /// - Parameter conversation: The conversation to summarize
    /// - Returns: AI-generated summary and the messages that were summarized
    func summarizeConversationWithAI(_ conversation: Conversation) async throws -> ConversationSummary {
        // Get messages to summarize (exclude any that have already been summarized)
        let messagesToSummarize = getMessagesToSummarize(conversation)
        
        // If there are no messages to summarize, return an empty summary
        if messagesToSummarize.isEmpty {
            throw ConversationError.noMessagesToSummarize
        }
        
        // Create a system prompt for summarization
        let systemPrompt = """
        You are a helpful assistant that summarizes conversations. Create a concise summary of the conversation so far.
        Focus on the key points, questions, and answers. The summary should be informative enough to provide context for the conversation,
        but brief enough to save tokens. Use bullet points for clarity.
        """
        
        // Format the conversation for the AI
        var formattedConversation = ""
        for message in messagesToSummarize {
            let role = message.role.rawValue.capitalized
            formattedConversation += "[\(role)]: \(message.content)\n\n"
        }
        
        // Create messages for the AI
        let messages = [
            Message(role: .system, content: systemPrompt),
            Message(role: .user, content: "Please summarize this conversation:\n\n\(formattedConversation)")
        ]
        
        // Get the default model
        let model = AIService.shared.getDefaultModel()
        
        // Create request options
        let options = AIRequestOptions(
            model: model,
            temperature: 0.7,
            maxTokens: 300,
            systemPrompt: systemPrompt
        )
        
        // Send the request to the AI router
        let response = try await AIRouter.shared.routeMessage(messages: messages, options: options)
        
        // Extract the summary from the response
        let summaryContent = response.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create a summary object
        let summary = ConversationSummary(
            conversationId: conversation.id,
            content: summaryContent,
            summarizedMessageIds: messagesToSummarize.map { $0.id }
        )
        
        // Save the summary
        saveSummary(summary)
        
        return summary
    }
    
    /// Get messages that need to be summarized
    /// - Parameter conversation: The conversation to get messages from
    /// - Returns: Array of messages that need to be summarized
    private func getMessagesToSummarize(_ conversation: Conversation) -> [Message] {
        // Get the latest summary
        guard let latestSummary = conversation.latestSummary else {
            // If there's no summary, return all messages except the most recent ones
            let messagesToKeep = min(5, conversation.messages.count)
            return Array(conversation.messages.dropLast(messagesToKeep))
        }
        
        // Get messages that haven't been summarized yet
        return conversation.messages.filter { message in
            !latestSummary.summarizedMessageIds.contains(message.id)
        }
    }
    
    /// Save a summary to storage
    /// - Parameter summary: The summary to save
    private func saveSummary(_ summary: ConversationSummary) {
        // TODO: Implement actual persistence
        print("Saving summary: \(summary.content.prefix(50))...")
    }
    
    /// Check if a conversation needs summarization
    /// - Parameters:
    ///   - conversation: The conversation to check
    ///   - model: The AI model being used
    /// - Returns: Whether the conversation needs summarization
    func conversationNeedsSummarization(_ conversation: Conversation, for model: AIModel) -> Bool {
        // Get the token count for the conversation
        let tokenCount = TokenCounter.shared.estimateTokenCount(for: conversation.messages)
        
        // If the token count is greater than 70% of the model's context window, summarize
        let threshold = Int(Double(model.contextWindow) * 0.7)
        return tokenCount > threshold
    }
    
    /// Get the context window for a model, including summaries if needed
    /// - Parameters:
    ///   - model: The AI model
    ///   - includeSummary: Whether to include a summary in the context
    /// - Returns: Array of messages that fit within the model's context window
    func getContextWindowWithSummary(for model: AIModel, includeSummary: Bool = true) -> [Message] {
        // If the conversation doesn't need summarization, return the regular context window
        if !conversationNeedsSummarization(currentConversation, for: model) {
            return getContextWindow(for: model)
        }
        
        // If we don't want to include a summary, return the regular context window
        if !includeSummary {
            return getContextWindow(for: model)
        }
        
        // Get the latest summary
        guard let latestSummary = currentConversation.latestSummary else {
            // If there's no summary, try to create one
            Task {
                do {
                    _ = try await summarizeConversationWithAI(currentConversation)
                } catch {
                    print("Error summarizing conversation: \(error.localizedDescription)")
                }
            }
            
            // Return the regular context window for now
            return getContextWindow(for: model)
        }
        
        // Create a system message with the summary
        let summaryMessage = Message(
            role: .system,
            content: "Previous conversation summary:\n\n\(latestSummary.content)"
        )
        
        // Get messages after the summarized ones
        let summarizedIds = Set(latestSummary.summarizedMessageIds)
        let remainingMessages = currentConversation.messages.filter { !summarizedIds.contains($0.id) }
        
        // If all messages fit within the context window, return them with the summary
        let combinedMessages = [summaryMessage] + remainingMessages
        if TokenCounter.shared.estimateTokenCount(for: combinedMessages) <= model.contextWindow {
            return combinedMessages
        }
        
        // Otherwise, truncate the remaining messages
        return truncateContext(messages: combinedMessages, maxTokens: model.contextWindow)
    }
    
    // MARK: - Conversation Export
    
    /// Export a conversation to a string
    /// - Parameter conversation: The conversation to export
    /// - Returns: String representation of the conversation
    func exportConversation(_ conversation: Conversation) -> String {
        var export = "# \(conversation.title)\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for message in conversation.messages {
            let timestamp = dateFormatter.string(from: message.timestamp)
            let roleString = message.role.rawValue.capitalized
            
            export += "## \(roleString) (\(timestamp))\n\n"
            export += message.content + "\n\n"
        }
        
        return export
    }
    
    // MARK: - Persistence
    
    /// Save conversations to storage
    private func saveConversations() {
        // TODO: Implement actual persistence
        // For now, just print the number of conversations
        print("Saving \(conversations.count) conversations")
    }
    
    /// Load conversations from storage
    private func loadConversations() {
        // TODO: Implement actual persistence
        // For now, just create a sample conversation if none exist
        if conversations.isEmpty {
            createNewConversation()
        }
    }
}

// MARK: - Conversation

/// Struct representing a conversation
struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [Message]
    var createdAt: Date = Date()
    
    init(id: UUID, title: String, messages: [Message]) {
        self.id = id
        self.title = title
        self.messages = messages
    }
}

// MARK: - Conversation Error

/// Errors that can occur during conversation operations
enum ConversationError: Error, LocalizedError {
    case noMessagesToSummarize
    case summaryGenerationFailed
    case tokenLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .noMessagesToSummarize:
            return "No messages to summarize"
        case .summaryGenerationFailed:
            return "Failed to generate conversation summary"
        case .tokenLimitExceeded:
            return "Token limit exceeded for this model"
        }
    }
}
