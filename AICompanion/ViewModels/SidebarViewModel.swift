
//
//  SidebarViewModel.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Combine

/// View model for handling sidebar functionality
@MainActor
class SidebarViewModel: ObservableObject {
    /// List of conversations
    @Published var conversations: [Conversation] = []
    
    /// List of AI providers
    @Published var aiProviders: [AIProvider] = []
    
    /// Currently selected conversation ID
    @Published var selectedConversationId: UUID?
    
    /// Search text for filtering conversations
    @Published var searchText: String = ""
    
    /// Storage service for persisting data
    private let storageService: StorageService
    
    /// AI service for provider information
    private let aiService: AIService
    
    /// Chat view model for communication
    private weak var chatViewModel: ChatViewModel?
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(storageService: StorageService = StorageService(), aiService: AIService = AIService()) {
        self.storageService = storageService
        self.aiService = aiService
        
        // Set up notification for auto-refreshing conversations
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshConversations),
            name: NSNotification.Name("ConversationSaved"),
            object: nil
        )
        
        // Load conversations and AI providers
        loadData()
        
        // Set up publishers
        setupPublishers()
    }
    
    deinit {
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Set the chat view model for communication
    func setChatViewModel(_ viewModel: ChatViewModel) {
        self.chatViewModel = viewModel
    }
    
    /// Load conversations and AI providers from storage
    private func loadData() {
        // Load conversations
        conversations = storageService.loadConversations()
            .sorted(by: { $0.updatedAt > $1.updatedAt })
        
        // Load AI providers
        aiProviders = aiService.getAvailableProviders()
        
        // Select the most recent conversation if available
        if let recentConversation = conversations.first {
            selectedConversationId = recentConversation.id
        }
    }
    
    /// Set up publishers to react to changes
    private func setupPublishers() {
        // When selected conversation changes, load it in the chat view model
        $selectedConversationId
            .dropFirst()
            .sink { [weak self] conversationId in
                guard let self = self, let conversationId = conversationId else { return }
                self.chatViewModel?.loadConversation(conversationId)
            }
            .store(in: &cancellables)
    }
    
    /// Delete a conversation
    func deleteConversation(_ conversation: Conversation) {
        // Remove from the list
        conversations.removeAll(where: { $0.id == conversation.id })
        
        // If the deleted conversation was selected, select another one
        if selectedConversationId == conversation.id {
            selectedConversationId = conversations.first?.id
        }
        
        // Delete from storage
        storageService.deleteConversation(conversation.id)
    }
    
    /// Rename a conversation
    func renameConversation(_ conversation: Conversation, newTitle: String) {
        // Update the conversation
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var updatedConversation = conversation
            updatedConversation.title = newTitle.isEmpty ? "Untitled Chat" : newTitle
            conversations[index] = updatedConversation
            
            // If this is the currently selected conversation, update it in the chat view model
            if selectedConversationId == conversation.id {
                chatViewModel?.currentConversation = updatedConversation
            }
            
            // Save the updated conversation
            storageService.saveConversation(updatedConversation)
        }
    }
    
    /// Select an AI provider
    func selectAIProvider(_ provider: AIProvider) {
        // Toggle the enabled state
        if let index = aiProviders.firstIndex(where: { $0.id == provider.id }) {
            var updatedProvider = provider
            updatedProvider.isEnabled = !provider.isEnabled
            aiProviders[index] = updatedProvider
            
            // Save the updated provider
            aiService.updateProvider(updatedProvider)
        }
    }
    
    /// Toggle the sidebar visibility
    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    /// Create a new folder for organizing conversations
    func createNewFolder(name: String) {
        // This would typically create a folder in the data model
        // For now, we'll just print a message
        print("Creating new folder: \(name)")
    }
    
    /// Move a conversation to a folder
    func moveConversationToFolder(conversation: Conversation, folderId: UUID) {
        // This would typically update the conversation's folder ID
        // For now, we'll just print a message
        print("Moving conversation \(conversation.id) to folder \(folderId)")
    }
    
    /// Refresh the conversations list
    @objc func refreshConversations() {
        loadData()
    }
    
    /// Filter conversations by search text
    func filteredConversations() -> [Conversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
}
