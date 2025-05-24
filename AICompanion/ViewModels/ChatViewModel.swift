
//
//  ChatViewModel.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Combine

/// View model for handling chat functionality
@MainActor
class ChatViewModel: ObservableObject {
    /// Current conversation
    @Published var currentConversation: Conversation?
    
    /// Messages in the current conversation
    @Published var messages: [Message] = []
    
    /// Whether the AI is currently processing a message
    @Published var isProcessing: Bool = false
    
    /// Error message if something goes wrong
    @Published var errorMessage: String?
    
    /// Current AI provider
    @Published var currentProvider: AIProvider?
    
    /// AI service for handling message generation
    private let aiService: AIService
    
    /// Storage service for persisting conversations
    private let storageService: StorageService
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(aiService: AIService = AIService(), storageService: StorageService = StorageService()) {
        self.aiService = aiService
        self.storageService = storageService
        
        // Set up notification for auto-saving
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveCurrentConversation),
            name: NSApplication.willResignActiveNotification,
            object: nil
        )
        
        // Load the most recent conversation or create a new one
        if let recentConversation = storageService.loadRecentConversation() {
            self.currentConversation = recentConversation
            self.messages = recentConversation.messages
            
            // Load the provider for this conversation
            Task {
                await loadCurrentProvider()
            }
        } else {
            startNewChat()
        }
    }
    
    /// Load the current provider based on the conversation's provider ID
    private func loadCurrentProvider() async {
        guard let conversation = currentConversation else { return }
        
        do {
            let provider = try aiService.getProvider(id: conversation.aiProviderId)
            currentProvider = provider
        } catch {
            errorMessage = "Error loading AI provider: \(error.localizedDescription)"
        }
    }
    
    /// Start a new chat conversation
    func startNewChat() {
        // Get the default AI provider or use the first available one
        let defaultProviderId = storageService.loadUser()?.preferences.defaultAIProviderId ?? aiService.getDefaultProvider().id
        
        // Create a new conversation
        let newConversation = Conversation(
            title: "New Chat",
            messages: [],
            aiProviderId: defaultProviderId
        )
        
        currentConversation = newConversation
        messages = []
        
        // Load the provider for this conversation
        Task {
            await loadCurrentProvider()
        }
        
        // Save the new conversation
        storageService.saveConversation(newConversation)
    }
    
    /// Send a message in the current conversation
    func sendMessage(_ content: String) {
        guard let conversation = currentConversation else {
            startNewChat()
            return sendMessage(content)
        }
        
        // Create a new user message
        let userMessage = Message(
            content: content,
            isFromUser: true
        )
        
        // Add the message to the current conversation
        messages.append(userMessage)
        
        // Update the conversation
        var updatedConversation = conversation
        updatedConversation.messages.append(userMessage)
        updatedConversation.updatedAt = Date()
        
        // If this is the first message, generate a title for the conversation
        if updatedConversation.messages.count == 1 {
            let title = content.prefix(30).trimmingCharacters(in: .whitespacesAndNewlines)
            updatedConversation.title = title.isEmpty ? "New Chat" : title
        }
        
        currentConversation = updatedConversation
        
        // Save the updated conversation
        storageService.saveConversation(updatedConversation)
        
        // Generate AI response
        generateAIResponse(for: updatedConversation)
    }
    
    /// Generate an AI response for the given conversation
    private func generateAIResponse(for conversation: Conversation) {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                // Get the AI provider for this conversation
                let provider = try aiService.getProvider(id: conversation.aiProviderId)
                currentProvider = provider
                
                // Generate the AI response
                let aiResponse = try await aiService.generateResponse(
                    messages: conversation.messages,
                    provider: provider
                )
                
                // Create a new AI message
                let aiMessage = Message(
                    content: aiResponse,
                    isFromUser: false,
                    aiProviderId: provider.id
                )
                
                // Add the AI message to the conversation
                messages.append(aiMessage)
                
                // Update the conversation
                var updatedConversation = conversation
                updatedConversation.messages.append(aiMessage)
                updatedConversation.updatedAt = Date()
                currentConversation = updatedConversation
                
                // Save the updated conversation
                storageService.saveConversation(updatedConversation)
                
                isProcessing = false
            } catch {
                errorMessage = "Error generating AI response: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
    
    /// Clear the current chat
    func clearCurrentChat() {
        guard let conversation = currentConversation else { return }
        
        // Create a new empty conversation with the same ID and provider
        let clearedConversation = Conversation(
            id: conversation.id,
            title: "New Chat",
            createdAt: Date(),
            updatedAt: Date(),
            messages: [],
            aiProviderId: conversation.aiProviderId
        )
        
        currentConversation = clearedConversation
        messages = []
        
        // Save the cleared conversation
        storageService.saveConversation(clearedConversation)
    }
    
    /// Export the current chat to a file
    func exportChat() {
        guard let conversation = currentConversation, !conversation.messages.isEmpty else {
            errorMessage = "No messages to export"
            return
        }
        
        Task {
            do {
                try await storageService.exportConversation(conversation)
            } catch {
                errorMessage = "Error exporting chat: \(error.localizedDescription)"
            }
        }
    }
    
    /// Change the AI provider for the current conversation
    func changeProvider(to providerId: UUID) {
        guard let conversation = currentConversation else { return }
        
        // Update the conversation with the new provider
        var updatedConversation = conversation
        updatedConversation.aiProviderId = providerId
        currentConversation = updatedConversation
        
        // Load the new provider
        Task {
            await loadCurrentProvider()
        }
        
        // Save the updated conversation
        storageService.saveConversation(updatedConversation)
    }
    
    /// Load a specific conversation
    func loadConversation(_ conversationId: UUID) {
        guard let conversation = storageService.loadConversation(conversationId) else {
            errorMessage = "Conversation not found"
            return
        }
        
        currentConversation = conversation
        messages = conversation.messages
        
        // Load the provider for this conversation
        Task {
            await loadCurrentProvider()
        }
    }
    
    /// Regenerate the last AI response
    func regenerateLastResponse() {
        guard let conversation = currentConversation, !conversation.messages.isEmpty else { return }
        
        // Check if the last message is from the AI
        if let lastMessage = conversation.messages.last, !lastMessage.isFromUser {
            // Remove the last message
            var updatedMessages = conversation.messages
            updatedMessages.removeLast()
            
            // Update the conversation
            var updatedConversation = conversation
            updatedConversation.messages = updatedMessages
            currentConversation = updatedConversation
            messages = updatedMessages
            
            // Save the updated conversation
            storageService.saveConversation(updatedConversation)
            
            // Generate a new AI response
            generateAIResponse(for: updatedConversation)
        } else {
            // If the last message is from the user, just generate a new response
            generateAIResponse(for: conversation)
        }
    }
    
    /// Stop the current AI response generation
    func stopGeneration() {
        if isProcessing {
            aiService.cancelCurrentGeneration()
            isProcessing = false
        }
    }
    
    /// Save the current conversation
    @objc func saveCurrentConversation() {
        if let conversation = currentConversation {
            storageService.saveConversation(conversation)
            PersistenceController.shared.save()
        }
    }
    
    /// Called when the view model is deallocated
    deinit {
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        
        // Save current conversation
        saveCurrentConversation()
    }
}
