import Foundation

/// Service for counting tokens in text
class TokenCounter {
    // MARK: - Shared Instance
    
    static let shared = TokenCounter()
    
    // MARK: - Properties
    
    /// Average characters per token (for estimation)
    private let averageCharsPerToken: Double = 4.0
    
    /// Regex patterns for token counting
    private let patterns: [String: NSRegularExpression] = [
        "word": try! NSRegularExpression(pattern: "\\b\\w+\\b", options: []),
        "punctuation": try! NSRegularExpression(pattern: "[!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~]", options: []),
        "whitespace": try! NSRegularExpression(pattern: "\\s+", options: []),
        "number": try! NSRegularExpression(pattern: "\\d+", options: [])
    ]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Token Counting
    
    /// Estimate the number of tokens in a string
    /// - Parameter text: The text to count tokens for
    /// - Returns: Estimated token count
    func estimateTokenCount(for text: String) -> Int {
        // Simple estimation based on character count
        return Int(ceil(Double(text.count) / averageCharsPerToken))
    }
    
    /// Estimate the number of tokens in a message
    /// - Parameter message: The message to count tokens for
    /// - Returns: Estimated token count
    func estimateTokenCount(for message: Message) -> Int {
        // Add overhead for message metadata (role, etc.)
        let roleOverhead = 4 // Approximate token overhead for role
        return roleOverhead + estimateTokenCount(for: message.content)
    }
    
    /// Estimate the number of tokens in an array of messages
    /// - Parameter messages: The messages to count tokens for
    /// - Returns: Estimated token count
    func estimateTokenCount(for messages: [Message]) -> Int {
        // Sum the token counts for all messages
        return messages.reduce(0) { $0 + estimateTokenCount(for: $1) }
    }
    
    /// More accurate token counting using regex patterns
    /// - Parameter text: The text to count tokens for
    /// - Returns: More accurate token count
    func countTokens(for text: String) -> Int {
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        // Count words
        let wordCount = patterns["word"]!.numberOfMatches(in: text, options: [], range: range)
        
        // Count punctuation
        let punctuationCount = patterns["punctuation"]!.numberOfMatches(in: text, options: [], range: range)
        
        // Count whitespace
        let whitespaceCount = patterns["whitespace"]!.numberOfMatches(in: text, options: [], range: range)
        
        // Count numbers (counted separately as they tokenize differently)
        let numberCount = patterns["number"]!.numberOfMatches(in: text, options: [], range: range)
        
        // Adjust for special tokenization rules
        let specialAdjustment = Int(Double(text.count) * 0.05) // 5% adjustment for special cases
        
        return wordCount + punctuationCount + whitespaceCount + numberCount + specialAdjustment
    }
    
    /// Check if a conversation exceeds a token limit
    /// - Parameters:
    ///   - conversation: The conversation to check
    ///   - limit: The token limit
    /// - Returns: Whether the conversation exceeds the limit
    func conversationExceedsLimit(_ conversation: Conversation, limit: Int) -> Bool {
        return estimateTokenCount(for: conversation.messages) > limit
    }
}
