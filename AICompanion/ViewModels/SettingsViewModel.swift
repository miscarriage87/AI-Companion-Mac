
//
//  SettingsViewModel.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Combine
import KeychainAccess

/// View model for handling settings functionality
@MainActor
class SettingsViewModel: ObservableObject {
    // User profile settings
    @Published var username: String = ""
    @Published var email: String = ""
    
    // Chat settings
    @Published var saveChatHistory: Bool = true
    @Published var maxConversationHistory: Int = 50
    @Published var showTimestamps: Bool = true
    
    // AI provider settings
    @Published var aiProviders: [AIProvider] = []
    @Published var defaultAIProviderId: UUID? = nil
    @Published var apiKeys: [String: String] = [:]
    @Published var enabledProviders: Set<UUID> = []
    
    // Keychain for secure storage
    private let keychain = KeychainAccess.Keychain(service: "com.aicompanion.settings")
    
    // Appearance settings
    @Published var isDarkMode: Bool = false
    @Published var fontSize: Int = 14
    @Published var accentColor: Color = .blue
    @Published var showUserAvatars: Bool = true
    @Published var showAIAvatars: Bool = true
    @Published var messageSpacing: Double = 1.0
    
    // Advanced settings
    @Published var enableAnalytics: Bool = false
    @Published var debugMode: Bool = false
    @Published var showAPIRequests: Bool = false
    @Published var logToConsole: Bool = false
    
    // UI state
    @Published var showSettings: Bool = false
    @Published var isValidatingAPIKey: Bool = false
    @Published var apiKeyValidationResults: [UUID: Bool] = [:]
    
    /// Storage service for persisting settings
    private let storageService: StorageService
    
    /// AI service for provider information
    private let aiService: AIService
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(storageService: StorageService = StorageService(), aiService: AIService = AIService()) {
        self.storageService = storageService
        self.aiService = aiService
        
        // Load settings
        loadSettings()
        
        // Set up publishers to save settings when they change
        setupPublishers()
    }
    
    /// Load settings from storage
    private func loadSettings() {
        // Load user
        if let user = storageService.loadUser() {
            username = user.username
            email = user.email
            
            // Load preferences
            let prefs = user.preferences
            saveChatHistory = prefs.saveChatHistory
            maxConversationHistory = prefs.maxConversationHistory
            showTimestamps = prefs.showTimestamps
            isDarkMode = prefs.isDarkMode
            fontSize = prefs.fontSize
            defaultAIProviderId = prefs.defaultAIProviderId
            showUserAvatars = prefs.showUserAvatars
            showAIAvatars = prefs.showAIAvatars
            messageSpacing = prefs.messageSpacing
            
            // Load API keys from user object for backward compatibility
            apiKeys = user.apiKeys
            
            // Migrate API keys to Keychain if they're not already there
            for (providerIdString, apiKey) in user.apiKeys {
                if let providerId = UUID(uuidString: providerIdString) {
                    let apiKeyKey = "apiKey_\(providerId.uuidString)"
                    if (try? keychain.get(apiKeyKey)) == nil {
                        try? keychain.set(apiKey, key: apiKeyKey)
                    }
                }
            }
        }
        
        // Load AI providers
        aiProviders = aiService.getAvailableProviders()
        
        // Set enabled providers
        enabledProviders = Set(aiProviders.filter { $0.isEnabled }.map { $0.id })
    }
    
    /// Set up publishers to save settings when they change
    private func setupPublishers() {
        // Combine multiple publishers into one
        Publishers.MergeMany(
            $username.dropFirst().debounce(for: 0.5, scheduler: RunLoop.main),
            $email.dropFirst().debounce(for: 0.5, scheduler: RunLoop.main),
            $saveChatHistory.dropFirst(),
            $maxConversationHistory.dropFirst(),
            $showTimestamps.dropFirst(),
            $isDarkMode.dropFirst(),
            $fontSize.dropFirst(),
            $defaultAIProviderId.dropFirst(),
            $apiKeys.dropFirst().debounce(for: 0.5, scheduler: RunLoop.main),
            $showUserAvatars.dropFirst(),
            $showAIAvatars.dropFirst(),
            $messageSpacing.dropFirst(),
            $accentColor.dropFirst().debounce(for: 0.5, scheduler: RunLoop.main)
        )
        .sink { [weak self] _ in
            self?.saveSettings()
        }
        .store(in: &cancellables)
        
        // Save enabled providers when they change
        $enabledProviders
            .dropFirst()
            .sink { [weak self] enabledIds in
                self?.updateEnabledProviders(enabledIds)
            }
            .store(in: &cancellables)
    }
    
    /// Save settings to storage
    private func saveSettings() {
        // Create user preferences
        let preferences = UserPreferences(
            isDarkMode: isDarkMode,
            defaultAIProviderId: defaultAIProviderId,
            fontSize: fontSize,
            showTimestamps: showTimestamps,
            saveChatHistory: saveChatHistory,
            maxConversationHistory: maxConversationHistory,
            showUserAvatars: showUserAvatars,
            showAIAvatars: showAIAvatars,
            messageSpacing: messageSpacing
        )
        
        // Create or update user
        let user = User(
            id: storageService.loadUser()?.id ?? UUID(),
            username: username,
            email: email,
            preferences: preferences,
            apiKeys: apiKeys
        )
        
        // Save user
        storageService.saveUser(user)
        
        // Apply appearance settings
        applyAppearanceSettings()
        
        // Post notification that settings have changed
        NotificationCenter.default.post(name: NSNotification.Name("UserSettingsChanged"), object: nil)
    }
    
    /// Update enabled providers
    private func updateEnabledProviders(_ enabledIds: Set<UUID>) {
        for provider in aiProviders {
            let isEnabled = enabledIds.contains(provider.id)
            if provider.isEnabled != isEnabled {
                var updatedProvider = provider
                updatedProvider.isEnabled = isEnabled
                aiService.updateProvider(updatedProvider)
            }
        }
        
        // Reload providers
        aiProviders = aiService.getAvailableProviders()
    }
    
    /// Apply appearance settings
    private func applyAppearanceSettings() {
        // Set app appearance based on dark mode setting
        NSApp.appearance = isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        
        // Set accent color
        // Note: This would typically require additional code to apply the color to the app
    }
    
    /// Reset all settings to defaults
    func resetSettings() {
        username = ""
        email = ""
        saveChatHistory = true
        maxConversationHistory = 50
        showTimestamps = true
        isDarkMode = false
        fontSize = 14
        accentColor = .blue
        showUserAvatars = true
        showAIAvatars = true
        messageSpacing = 1.0
        defaultAIProviderId = nil
        apiKeys = [:]
        enableAnalytics = false
        debugMode = false
        showAPIRequests = false
        logToConsole = false
        
        // Clear API keys from Keychain
        for provider in aiProviders {
            let apiKeyKey = "apiKey_\(provider.id.uuidString)"
            try? keychain.remove(apiKeyKey)
        }
        
        // Reset enabled providers
        for provider in aiProviders {
            var updatedProvider = provider
            updatedProvider.isEnabled = true
            aiService.updateProvider(updatedProvider)
        }
        
        // Reload providers
        aiProviders = aiService.getAvailableProviders()
        enabledProviders = Set(aiProviders.map { $0.id })
        
        // Save settings
        saveSettings()
    }
    
    /// Export all user data
    func exportAllData() {
        Task {
            do {
                try await storageService.exportAllData()
            } catch {
                print("Error exporting data: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clear all user data
    func clearAllData() {
        Task {
            do {
                try await storageService.clearAllData()
                
                // Clear API keys from Keychain
                for provider in aiProviders {
                    let apiKeyKey = "apiKey_\(provider.id.uuidString)"
                    try? keychain.remove(apiKeyKey)
                }
                
                // Reset settings after clearing data
                loadSettings()
            } catch {
                print("Error clearing data: \(error.localizedDescription)")
            }
        }
    }
    
    /// Validate an API key for a provider
    func validateAPIKey(for providerId: UUID) {
        guard let provider = aiProviders.first(where: { $0.id == providerId }) else {
            apiKeyValidationResults[providerId] = false
            return
        }
        
        // Get API key from Keychain
        let apiKeyKey = "apiKey_\(providerId.uuidString)"
        guard let apiKey = try? keychain.get(apiKeyKey), !apiKey.isEmpty else {
            // Fallback to the old method if not in Keychain
            guard let apiKey = apiKeys[providerId.uuidString], !apiKey.isEmpty else {
                apiKeyValidationResults[providerId] = false
                return
            }
            
            // Store in Keychain for future use
            try? keychain.set(apiKey, key: apiKeyKey)
            
            validateAPIKeyWithService(apiKey: apiKey, provider: provider, providerId: providerId)
            return
        }
        
        validateAPIKeyWithService(apiKey: apiKey, provider: provider, providerId: providerId)
    }
    
    /// Helper method to validate API key with the service
    private func validateAPIKeyWithService(apiKey: String, provider: AIProvider, providerId: UUID) {
        isValidatingAPIKey = true
        
        Task {
            do {
                let isValid = try await aiService.validateAPIKey(apiKey, for: provider)
                apiKeyValidationResults[providerId] = isValid
                isValidatingAPIKey = false
            } catch {
                apiKeyValidationResults[providerId] = false
                isValidatingAPIKey = false
                print("Error validating API key: \(error.localizedDescription)")
            }
        }
    }
    
    /// Save API key to Keychain
    func saveAPIKey(_ apiKey: String, for providerId: UUID) {
        let apiKeyKey = "apiKey_\(providerId.uuidString)"
        
        do {
            try keychain.set(apiKey, key: apiKeyKey)
            
            // Also update the in-memory dictionary for backward compatibility
            apiKeys[providerId.uuidString] = apiKey
            
            // Save settings to update the user object
            saveSettings()
        } catch {
            print("Error saving API key to Keychain: \(error.localizedDescription)")
        }
    }
    
    /// Get API key from Keychain
    func getAPIKey(for providerId: UUID) -> String {
        let apiKeyKey = "apiKey_\(providerId.uuidString)"
        
        // Try to get from Keychain first
        if let apiKey = try? keychain.get(apiKeyKey) {
            return apiKey
        }
        
        // Fallback to the old method
        return apiKeys[providerId.uuidString] ?? ""
    }
    
    /// Delete API key from Keychain
    func deleteAPIKey(for providerId: UUID) {
        let apiKeyKey = "apiKey_\(providerId.uuidString)"
        
        do {
            try keychain.remove(apiKeyKey)
            
            // Also remove from the in-memory dictionary
            apiKeys.removeValue(forKey: providerId.uuidString)
            
            // Save settings to update the user object
            saveSettings()
        } catch {
            print("Error deleting API key from Keychain: \(error.localizedDescription)")
        }
    }
    
    /// Import settings from a file
    func importSettings(from url: URL) {
        Task {
            do {
                try await storageService.importSettings(from: url)
                loadSettings()
            } catch {
                print("Error importing settings: \(error.localizedDescription)")
            }
        }
    }
    
    /// Export settings to a file
    func exportSettings(to url: URL) {
        Task {
            do {
                try await storageService.exportSettings(to: url)
            } catch {
                print("Error exporting settings: \(error.localizedDescription)")
            }
        }
    }
}
