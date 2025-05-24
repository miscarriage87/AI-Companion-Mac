
//
//  Message.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation

/// Represents a chat message in the application
struct Message: Identifiable, Codable, Equatable {
    /// Unique identifier for the message
    let id: UUID
    
    /// Content of the message
    let content: String
    
    /// Timestamp when the message was created
    let timestamp: Date
    
    /// Indicates whether the message is from the user or AI
    let isFromUser: Bool
    
    /// Optional reference to the AI provider that generated this message
    let aiProviderId: UUID?
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isFromUser: Bool, aiProviderId: UUID? = nil) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.aiProviderId = aiProviderId
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a conversation thread containing multiple messages
struct Conversation: Identifiable, Codable {
    /// Unique identifier for the conversation
    let id: UUID
    
    /// Title of the conversation
    var title: String
    
    /// Timestamp when the conversation was created
    let createdAt: Date
    
    /// Timestamp when the conversation was last updated
    var updatedAt: Date
    
    /// Messages in this conversation
    var messages: [Message]
    
    /// AI provider associated with this conversation
    var aiProviderId: UUID
    
    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), updatedAt: Date = Date(), messages: [Message] = [], aiProviderId: UUID) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.aiProviderId = aiProviderId
    }
}
