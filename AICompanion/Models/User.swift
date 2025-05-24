
//
//  User.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation

/// Represents a user of the application
struct User: Identifiable, Codable {
    /// Unique identifier for the user
    let id: UUID
    
    /// Username for display purposes
    var username: String
    
    /// Email address of the user
    var email: String
    
    /// User preferences
    var preferences: UserPreferences
    
    /// User's API keys for different AI providers
    var apiKeys: [String: String]
    
    init(id: UUID = UUID(), username: String, email: String, preferences: UserPreferences = UserPreferences(), apiKeys: [String: String] = [:]) {
        self.id = id
        self.username = username
        self.email = email
        self.preferences = preferences
        self.apiKeys = apiKeys
    }
}

/// User preferences for application settings
struct UserPreferences: Codable {
    /// Whether to use dark mode
    var isDarkMode: Bool = false
    
    /// Default AI provider to use
    var defaultAIProviderId: UUID?
    
    /// Font size for chat messages
    var fontSize: Int = 14
    
    /// Whether to show timestamps on messages
    var showTimestamps: Bool = true
    
    /// Whether to save chat history locally
    var saveChatHistory: Bool = true
    
    /// Maximum number of conversations to keep in history
    var maxConversationHistory: Int = 50
    
    /// Whether to show user avatars in chat
    var showUserAvatars: Bool = true
    
    /// Whether to show AI avatars in chat
    var showAIAvatars: Bool = true
    
    /// Spacing between messages (0: compact, 1: normal, 2: spacious)
    var messageSpacing: Double = 1.0
}
