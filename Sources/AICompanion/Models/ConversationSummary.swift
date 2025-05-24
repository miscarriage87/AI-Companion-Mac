import Foundation

/// Struct representing a summary of a conversation
struct ConversationSummary: Codable, Identifiable {
    /// Unique identifier for the summary
    let id: UUID
    
    /// ID of the conversation this summary is for
    let conversationId: UUID
    
    /// The summary text
    let content: String
    
    /// Timestamp when the summary was created
    let createdAt: Date
    
    /// Messages that were summarized
    let summarizedMessageIds: [UUID]
    
    /// Token count of the summary
    let tokenCount: Int
    
    init(
        id: UUID = UUID(),
        conversationId: UUID,
        content: String,
        createdAt: Date = Date(),
        summarizedMessageIds: [UUID],
        tokenCount: Int? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.content = content
        self.createdAt = createdAt
        self.summarizedMessageIds = summarizedMessageIds
        self.tokenCount = tokenCount ?? TokenCounter.shared.estimateTokenCount(for: content)
    }
}

/// Extension to Conversation for summary-related functionality
extension Conversation {
    /// Get all summaries for this conversation
    var summaries: [ConversationSummary] {
        // In a real implementation, this would fetch from storage
        // For now, return an empty array
        return []
    }
    
    /// Get the latest summary for this conversation
    var latestSummary: ConversationSummary? {
        // In a real implementation, this would fetch from storage
        // For now, return nil
        return summaries.sorted(by: { $0.createdAt > $1.createdAt }).first
    }
    
    /// Check if this conversation has any summaries
    var hasSummaries: Bool {
        return !summaries.isEmpty
    }
}
