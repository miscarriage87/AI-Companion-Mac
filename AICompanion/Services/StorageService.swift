//
//  StorageService.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import CoreData
import Combine

/// Service for handling data persistence
class StorageService {
    /// Shared instance of the persistence controller
    private let persistenceController = PersistenceController.shared
    
    /// User defaults for settings
    private let userDefaults = UserDefaults.standard
    
    /// Timer for periodic auto-saving
    private var autoSaveTimer: Timer?
    
    /// Notification center for observing app lifecycle events
    private let notificationCenter = NotificationCenter.default
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Current user
    private var currentUser: User?
    
    /// In-memory cache of conversations
    private var conversationsCache: [UUID: Conversation] = [:]
    
    /// In-memory cache of providers
    private var providersCache: [UUID: AIProvider] = [:]
    
    /// Constants for UserDefaults keys
    private struct Keys {
        static let username = "username"
        static let email = "email"
        static let isDarkMode = "isDarkMode"
        static let defaultAIProviderId = "defaultAIProviderId"
        static let fontSize = "fontSize"
        static let showTimestamps = "showTimestamps"
        static let saveChatHistory = "saveChatHistory"
        static let maxConversationHistory = "maxConversationHistory"
        static let showUserAvatars = "showUserAvatars"
        static let showAIAvatars = "showAIAvatars"
        static let messageSpacing = "messageSpacing"
        static let apiKeys = "apiKeys"
        static let userId = "userId"
        static let appVersion = "appVersion"
        static let lastMigrationVersion = "lastMigrationVersion"
    }
    
    init() {
        // Set up auto-save timer (every 30 seconds)
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performAutoSave()
        }
        
        // Register for app lifecycle notifications
        setupNotifications()
        
        // Load the current user
        loadCurrentUser()
        
        // Initialize with sample data if needed
        initializeWithSampleDataIfNeeded()
        
        // Perform data migration if needed
        performDataMigrationIfNeeded()
    }
    
    deinit {
        // Invalidate the auto-save timer
        autoSaveTimer?.invalidate()
        
        // Remove notification observers
        notificationCenter.removeObserver(self)
    }
    
    /// Set up notifications for app lifecycle events
    private func setupNotifications() {
        // Save data when app will terminate
        notificationCenter.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveAllData()
        }
        
        // Save data when app will resign active
        notificationCenter.addObserver(
            forName: NSApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveAllData()
        }
    }
    
    /// Perform auto-save of data
    private func performAutoSave() {
        persistenceController.save()
    }
    
    /// Save all data
    private func saveAllData() {
        persistenceController.save()
    }
    
    /// Load the current user
    private func loadCurrentUser() {
        // Check if we have a user ID in UserDefaults
        if let userIdString = userDefaults.string(forKey: Keys.userId),
           let userId = UUID(uuidString: userIdString) {
            // Try to load the user from UserDefaults
            currentUser = loadUserFromUserDefaults(userId: userId)
        }
        
        // If we don't have a user, create a default one
        if currentUser == nil {
            let defaultUser = createDefaultUser()
            currentUser = defaultUser
            saveUserToUserDefaults(defaultUser)
        }
    }
    
    /// Create a default user
    private func createDefaultUser() -> User {
        let userId = UUID()
        
        // Save the user ID to UserDefaults
        userDefaults.set(userId.uuidString, forKey: Keys.userId)
        
        return User(
            id: userId,
            username: "User",
            email: "user@example.com",
            preferences: UserPreferences(
                isDarkMode: false,
                defaultAIProviderId: nil,
                fontSize: 14,
                showTimestamps: true,
                saveChatHistory: true,
                maxConversationHistory: 50,
                showUserAvatars: true,
                showAIAvatars: true,
                messageSpacing: 1.0
            ),
            apiKeys: [:]
        )
    }
    
    /// Initialize with sample data if needed
    private func initializeWithSampleDataIfNeeded() {
        // Check if we have any conversations
        let existingConversations = loadConversations()
        if existingConversations.isEmpty {
            // Save sample conversations
            for conversation in SampleData.getSampleConversations() {
                saveConversation(conversation)
            }
        }
        
        // Check if we have any providers
        let existingProviders = loadAIProviders()
        if existingProviders.isEmpty {
            // Save sample providers
            for provider in SampleData.getSampleAIProviders() {
                saveAIProvider(provider)
            }
        }
    }
    
    /// Perform data migration if needed
    private func performDataMigrationIfNeeded() {
        // Get the current app version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        // Get the last migration version
        let lastMigrationVersion = userDefaults.string(forKey: Keys.lastMigrationVersion) ?? "0.0"
        
        // Check if we need to migrate
        if lastMigrationVersion != currentVersion {
            // Perform migration based on version
            migrateData(fromVersion: lastMigrationVersion, toVersion: currentVersion)
            
            // Update the last migration version
            userDefaults.set(currentVersion, forKey: Keys.lastMigrationVersion)
        }
    }
    
    /// Migrate data from one version to another
    private func migrateData(fromVersion: String, toVersion: String) {
        // For now, we don't have any specific migrations to perform
        print("Migrating data from version \(fromVersion) to \(toVersion)")
    }
    
    // MARK: - User Methods
    
    /// Load the user from storage
    func loadUser() -> User? {
        return currentUser
    }
    
    /// Load a user from UserDefaults
    private func loadUserFromUserDefaults(userId: UUID) -> User? {
        // Get user data from UserDefaults
        let username = userDefaults.string(forKey: Keys.username) ?? "User"
        let email = userDefaults.string(forKey: Keys.email) ?? "user@example.com"
        
        // Get preferences
        let isDarkMode = userDefaults.bool(forKey: Keys.isDarkMode)
        let fontSize = userDefaults.integer(forKey: Keys.fontSize)
        let showTimestamps = userDefaults.bool(forKey: Keys.showTimestamps)
        let saveChatHistory = userDefaults.bool(forKey: Keys.saveChatHistory)
        let maxConversationHistory = userDefaults.integer(forKey: Keys.maxConversationHistory)
        let showUserAvatars = userDefaults.bool(forKey: Keys.showUserAvatars)
        let showAIAvatars = userDefaults.bool(forKey: Keys.showAIAvatars)
        let messageSpacing = userDefaults.double(forKey: Keys.messageSpacing)
        
        // Get default AI provider ID
        var defaultAIProviderId: UUID? = nil
        if let providerIdString = userDefaults.string(forKey: Keys.defaultAIProviderId),
           let providerId = UUID(uuidString: providerIdString) {
            defaultAIProviderId = providerId
        }
        
        // Get API keys
        let apiKeys = userDefaults.dictionary(forKey: Keys.apiKeys) as? [String: String] ?? [:]
        
        // Create preferences
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
        
        // Create user
        return User(
            id: userId,
            username: username,
            email: email,
            preferences: preferences,
            apiKeys: apiKeys
        )
    }
    
    /// Save the user to storage
    func saveUser(_ user: User) {
        // Update the current user
        currentUser = user
        
        // Save to UserDefaults
        saveUserToUserDefaults(user)
    }
    
    /// Save a user to UserDefaults
    private func saveUserToUserDefaults(_ user: User) {
        // Save user ID
        userDefaults.set(user.id.uuidString, forKey: Keys.userId)
        
        // Save user data
        userDefaults.set(user.username, forKey: Keys.username)
        userDefaults.set(user.email, forKey: Keys.email)
        
        // Save preferences
        userDefaults.set(user.preferences.isDarkMode, forKey: Keys.isDarkMode)
        userDefaults.set(user.preferences.fontSize, forKey: Keys.fontSize)
        userDefaults.set(user.preferences.showTimestamps, forKey: Keys.showTimestamps)
        userDefaults.set(user.preferences.saveChatHistory, forKey: Keys.saveChatHistory)
        userDefaults.set(user.preferences.maxConversationHistory, forKey: Keys.maxConversationHistory)
        userDefaults.set(user.preferences.showUserAvatars, forKey: Keys.showUserAvatars)
        userDefaults.set(user.preferences.showAIAvatars, forKey: Keys.showAIAvatars)
        userDefaults.set(user.preferences.messageSpacing, forKey: Keys.messageSpacing)
        
        // Save default AI provider ID
        if let providerId = user.preferences.defaultAIProviderId {
            userDefaults.set(providerId.uuidString, forKey: Keys.defaultAIProviderId)
        } else {
            userDefaults.removeObject(forKey: Keys.defaultAIProviderId)
        }
        
        // Save API keys
        userDefaults.set(user.apiKeys, forKey: Keys.apiKeys)
        
        // Synchronize UserDefaults
        userDefaults.synchronize()
    }
    
    // MARK: - Conversation Methods
    
    /// Load all conversations from storage
    func loadConversations() -> [Conversation] {
        // If we have a populated cache, use it
        if !conversationsCache.isEmpty {
            return Array(conversationsCache.values).sorted(by: { $0.updatedAt > $1.updatedAt })
        }
        
        // Fetch conversations from Core Data
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDConversation> = CDConversation.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdConversations = try context.fetch(fetchRequest)
            
            // Convert to domain models and cache
            let conversations = cdConversations.map { cdConversation in
                let conversation = cdConversation.toDomainModel()
                conversationsCache[conversation.id] = conversation
                return conversation
            }
            
            return conversations
        } catch {
            print("Error loading conversations: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Load a specific conversation from storage
    func loadConversation(_ id: UUID) -> Conversation? {
        // Check cache first
        if let cachedConversation = conversationsCache[id] {
            return cachedConversation
        }
        
        // Fetch from Core Data
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDConversation> = CDConversation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let cdConversation = results.first {
                let conversation = cdConversation.toDomainModel()
                conversationsCache[id] = conversation
                return conversation
            }
            return nil
        } catch {
            print("Error loading conversation \(id): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Load the most recent conversation from storage
    func loadRecentConversation() -> Conversation? {
        let conversations = loadConversations()
        return conversations.first
    }
    
    /// Save a conversation to storage
    func saveConversation(_ conversation: Conversation) {
        // Update cache
        conversationsCache[conversation.id] = conversation
        
        // Save to Core Data
        let context = persistenceController.container.viewContext
        
        // Check if the conversation already exists
        let fetchRequest: NSFetchRequest<CDConversation> = CDConversation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingConversation = results.first {
                // Update existing conversation
                existingConversation.title = conversation.title
                existingConversation.updatedAt = conversation.updatedAt
                
                // Get the provider
                let providerFetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
                providerFetchRequest.predicate = NSPredicate(format: "id == %@", conversation.aiProviderId as CVarArg)
                providerFetchRequest.fetchLimit = 1
                
                if let provider = try context.fetch(providerFetchRequest).first {
                    existingConversation.provider = provider
                }
                
                // Update messages
                let existingMessages = existingConversation.messages.allObjects as? [CDMessage] ?? []
                let existingMessageIds = Set(existingMessages.map { $0.id })
                
                // Add new messages
                for message in conversation.messages {
                    if !existingMessageIds.contains(message.id) {
                        let cdMessage = CDMessage(context: context)
                        cdMessage.id = message.id
                        cdMessage.content = message.content
                        cdMessage.timestamp = message.timestamp
                        cdMessage.isFromUser = message.isFromUser
                        cdMessage.conversation = existingConversation
                        
                        // Set provider if available
                        if let providerId = message.aiProviderId {
                            let providerFetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
                            providerFetchRequest.predicate = NSPredicate(format: "id == %@", providerId as CVarArg)
                            providerFetchRequest.fetchLimit = 1
                            
                            if let provider = try context.fetch(providerFetchRequest).first {
                                cdMessage.provider = provider
                            }
                        }
                    }
                }
            } else {
                // Create new conversation
                let cdConversation = CDConversation(context: context)
                cdConversation.id = conversation.id
                cdConversation.title = conversation.title
                cdConversation.createdAt = conversation.createdAt
                cdConversation.updatedAt = conversation.updatedAt
                
                // Get the provider
                let providerFetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
                providerFetchRequest.predicate = NSPredicate(format: "id == %@", conversation.aiProviderId as CVarArg)
                providerFetchRequest.fetchLimit = 1
                
                if let provider = try context.fetch(providerFetchRequest).first {
                    cdConversation.provider = provider
                } else {
                    // If provider doesn't exist, create a default one
                    let cdProvider = CDProvider(context: context)
                    cdProvider.id = conversation.aiProviderId
                    cdProvider.name = "Unknown Provider"
                    cdProvider.providerDescription = "Provider not found"
                    cdProvider.apiBaseURL = "https://api.example.com"
                    cdProvider.requiresAPIKey = true
                    cdProvider.maxContextLength = 4096
                    cdProvider.isEnabled = true
                    
                    cdConversation.provider = cdProvider
                }
                
                // Add messages
                for message in conversation.messages {
                    let cdMessage = CDMessage(context: context)
                    cdMessage.id = message.id
                    cdMessage.content = message.content
                    cdMessage.timestamp = message.timestamp
                    cdMessage.isFromUser = message.isFromUser
                    cdMessage.conversation = cdConversation
                    
                    // Set provider if available
                    if let providerId = message.aiProviderId {
                        let providerFetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
                        providerFetchRequest.predicate = NSPredicate(format: "id == %@", providerId as CVarArg)
                        providerFetchRequest.fetchLimit = 1
                        
                        if let provider = try context.fetch(providerFetchRequest).first {
                            cdMessage.provider = provider
                        }
                    }
                }
            }
            
            // Save context
            try context.save()
        } catch {
            print("Error saving conversation \(conversation.id): \(error.localizedDescription)")
        }
    }
    
    /// Delete a conversation from storage
    func deleteConversation(_ id: UUID) {
        // Remove from cache
        conversationsCache.removeValue(forKey: id)
        
        // Delete from Core Data
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDConversation> = CDConversation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let conversation = results.first {
                context.delete(conversation)
                try context.save()
            }
        } catch {
            print("Error deleting conversation \(id): \(error.localizedDescription)")
        }
    }
    
    // MARK: - AI Provider Methods
    
    /// Load all AI providers from storage
    func loadAIProviders() -> [AIProvider] {
        // If we have a populated cache, use it
        if !providersCache.isEmpty {
            return Array(providersCache.values)
        }
        
        // Fetch providers from Core Data
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
        
        do {
            let cdProviders = try context.fetch(fetchRequest)
            
            // Convert to domain models and cache
            let providers = cdProviders.map { cdProvider in
                let provider = cdProvider.toDomainModel()
                providersCache[provider.id] = provider
                return provider
            }
            
            return providers
        } catch {
            print("Error loading AI providers: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Load a specific AI provider from storage
    func loadAIProvider(id: UUID) -> AIProvider? {
        // Check cache first
        if let cachedProvider = providersCache[id] {
            return cachedProvider
        }
        
        // Fetch from Core Data
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let cdProvider = results.first {
                let provider = cdProvider.toDomainModel()
                providersCache[id] = provider
                return provider
            }
            return nil
        } catch {
            print("Error loading AI provider \(id): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Save an AI provider to storage
    func saveAIProvider(_ provider: AIProvider) {
        // Update cache
        providersCache[provider.id] = provider
        
        // Save to Core Data
        let context = persistenceController.container.viewContext
        
        // Check if the provider already exists
        let fetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", provider.id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingProvider = results.first {
                // Update existing provider
                existingProvider.name = provider.name
                existingProvider.providerDescription = provider.description
                existingProvider.apiBaseURL = provider.apiBaseURL.absoluteString
                existingProvider.requiresAPIKey = provider.requiresAPIKey
                existingProvider.maxContextLength = Int32(provider.maxContextLength)
                existingProvider.isEnabled = provider.isEnabled
                
                // Update models
                let existingModels = existingProvider.models?.allObjects as? [CDModel] ?? []
                let existingModelIds = Set(existingModels.map { $0.id })
                
                // Add new models
                for model in provider.availableModels {
                    if !existingModelIds.contains(model.id) {
                        let cdModel = CDModel(context: context)
                        cdModel.id = model.id
                        cdModel.modelId = model.modelId
                        cdModel.displayName = model.displayName
                        cdModel.modelDescription = model.description
                        cdModel.maxContextLength = Int32(model.maxContextLength)
                        cdModel.supportsStreaming = model.supportsStreaming
                        cdModel.costPerInputToken = model.costPerInputToken
                        cdModel.costPerOutputToken = model.costPerOutputToken
                        cdModel.provider = existingProvider
                    }
                }
            } else {
                // Create new provider
                let cdProvider = CDProvider(context: context)
                cdProvider.id = provider.id
                cdProvider.name = provider.name
                cdProvider.providerDescription = provider.description
                cdProvider.apiBaseURL = provider.apiBaseURL.absoluteString
                cdProvider.requiresAPIKey = provider.requiresAPIKey
                cdProvider.maxContextLength = Int32(provider.maxContextLength)
                cdProvider.isEnabled = provider.isEnabled
                
                // Add models
                for model in provider.availableModels {
                    let cdModel = CDModel(context: context)
                    cdModel.id = model.id
                    cdModel.modelId = model.modelId
                    cdModel.displayName = model.displayName
                    cdModel.modelDescription = model.description
                    cdModel.maxContextLength = Int32(model.maxContextLength)
                    cdModel.supportsStreaming = model.supportsStreaming
                    cdModel.costPerInputToken = model.costPerInputToken
                    cdModel.costPerOutputToken = model.costPerOutputToken
                    cdModel.provider = cdProvider
                }
            }
            
            // Save context
            try context.save()
        } catch {
            print("Error saving AI provider \(provider.id): \(error.localizedDescription)")
        }
    }
    
    /// Delete an AI provider from storage
    func deleteAIProvider(_ id: UUID) {
        // Remove from cache
        providersCache.removeValue(forKey: id)
        
        // Delete from Core Data
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProvider> = CDProvider.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let provider = results.first {
                context.delete(provider)
                try context.save()
            }
        } catch {
            print("Error deleting AI provider \(id): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Export/Import Methods
    
    /// Export a conversation to a file
    func exportConversation(_ conversation: Conversation) async throws {
        // Create a formatted string of the conversation
        var exportText = "# \(conversation.title)\n"
        exportText += "Date: \(formatDate(conversation.createdAt))\n\n"
        
        for message in conversation.messages {
            let sender = message.isFromUser ? "User" : "AI"
            exportText += "## \(sender) - \(formatDate(message.timestamp))\n"
            exportText += message.content + "\n\n"
        }
        
        // Get the desktop directory
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileName = "Conversation-\(conversation.title.replacingOccurrences(of: " ", with: "-"))-\(Date().timeIntervalSince1970).md"
        let fileURL = desktopURL.appendingPathComponent(fileName)
        
        // Write the file
        try exportText.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    /// Export all user data
    func exportAllData() async throws {
        // Get the desktop directory
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let exportDirName = "AICompanion-Export-\(Date().timeIntervalSince1970)"
        let exportDirURL = desktopURL.appendingPathComponent(exportDirName, isDirectory: true)
        
        // Create export directory
        try FileManager.default.createDirectory(at: exportDirURL, withIntermediateDirectories: true)
        
        // Export user preferences
        if let user = loadUser() {
            let userJSON = try JSONEncoder().encode(user)
            try userJSON.write(to: exportDirURL.appendingPathComponent("user.json"))
        }
        
        // Export conversations
        let conversations = loadConversations()
        let conversationsJSON = try JSONEncoder().encode(conversations)
        try conversationsJSON.write(to: exportDirURL.appendingPathComponent("conversations.json"))
        
        // Export providers
        let providers = loadAIProviders()
        let providersJSON = try JSONEncoder().encode(providers)
        try providersJSON.write(to: exportDirURL.appendingPathComponent("providers.json"))
    }
    
    /// Clear all user data
    func clearAllData() async throws {
        // Clear Core Data
        persistenceController.reset()
        
        // Clear caches
        conversationsCache.removeAll()
        providersCache.removeAll()
        
        // Reset user preferences (but keep user ID)
        if let userId = currentUser?.id {
            let defaultUser = User(
                id: userId,
                username: "User",
                email: "user@example.com",
                preferences: UserPreferences(),
                apiKeys: [:]
            )
            saveUser(defaultUser)
        }
    }
    
    /// Import settings from a file
    func importSettings(from url: URL) async throws {
        let data = try Data(contentsOf: url)
        let user = try JSONDecoder().decode(User.self, from: data)
        saveUser(user)
    }
    
    /// Export settings to a file
    func exportSettings(to url: URL) async throws {
        guard let user = loadUser() else {
            throw NSError(domain: "AICompanion", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        let data = try JSONEncoder().encode(user)
        try data.write(to: url)
    }
    
    // MARK: - Helper Methods
    
    /// Format a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
