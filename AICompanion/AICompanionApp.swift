//
//  AICompanionApp.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

@main
struct AICompanionApp: App {
    // Initialize the persistence controller
    private let persistenceController = PersistenceController.shared
    
    // Initialize managers
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var sidebarViewModel = SidebarViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var documentManager = DocumentManager.shared
    @StateObject private var pluginManager = PluginManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var updateManager = UpdateManager.shared
    @StateObject private var animationManager = AnimationManager.shared
    @StateObject private var feedbackManager = FeedbackManager.shared
    @StateObject private var dragDropManager = DragDropManager.shared
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Initialize advanced AI capabilities
    private let functionCallingManager = FunctionCallingManager.shared
    private let toolUseManager = ToolUseManager.shared
    private let aiMemoryManager = AIMemoryManager.shared
    private let multiModalManager = MultiModalManager.shared
    
    // Initialize performance optimizations
    private let backgroundTaskManager = BackgroundTaskManager.shared
    private let cacheManager = CacheManager.shared
    
    init() {
        // Set up app appearance
        let appearance = NSAppearance(named: .aqua)
        NSApp.appearance = appearance
        
        // Register defaults
        registerDefaults()
        
        // Set up periodic auto-save
        setupPeriodicAutoSave()
        
        // Initialize document processing capabilities
        initializeDocumentProcessing()
        
        // Initialize advanced AI capabilities
        initializeAdvancedAICapabilities()
        
        // Initialize performance optimizations
        initializePerformanceOptimizations()
    }
    
    /// Set up periodic auto-save for Core Data
    private func setupPeriodicAutoSave() {
        // Create a timer that saves data every 60 seconds
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task {
                await MainActor.run {
                    _ = self.persistenceController.save()
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingManager.hasCompletedOnboarding {
                    MainView()
                        .environmentObject(chatViewModel)
                        .environmentObject(sidebarViewModel)
                        .environmentObject(settingsViewModel)
                        .environmentObject(documentManager)
                        .environmentObject(pluginManager)
                        .environmentObject(themeManager)
                        .environmentObject(updateManager)
                        .environmentObject(animationManager)
                        .environmentObject(feedbackManager)
                        .environmentObject(dragDropManager)
                        .environmentObject(accessibilityManager)
                        .environmentObject(localizationManager)
                        .frame(minWidth: 900, minHeight: 600)
                        .onAppear {
                            // Connect view models
                            sidebarViewModel.setChatViewModel(chatViewModel)
                            
                            // Apply initial settings
                            applyInitialSettings()
                        }
                        .onOpenURL { url in
                            // Handle deep links for authentication
                            Task {
                                await AuthService.shared.processDeepLink(url: url)
                            }
                        }
                } else {
                    OnboardingView()
                        .environmentObject(onboardingManager)
                        .environmentObject(animationManager)
                        .environmentObject(themeManager)
                        .environmentObject(feedbackManager)
                        .environmentObject(accessibilityManager)
                        .environmentObject(localizationManager)
                        .frame(width: 800, height: 600)
                }
            }
            .preferredColorScheme(themeManager.useSystemAppearance ? nil : (themeManager.currentTheme.isDark ? .dark : .light))
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // File menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    chatViewModel.startNewChat()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Divider()
                
                Button("Export Chat") {
                    chatViewModel.exportChat()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(chatViewModel.currentConversation == nil || chatViewModel.messages.isEmpty)
                
                Divider()
                
                Menu("Import") {
                    Button("Import Document") {
                        documentManager.showImportDocumentDialog()
                    }
                    .keyboardShortcut("i", modifiers: .command)
                    
                    Button("Import Plugin") {
                        // Show plugin import dialog
                        showPluginImportDialog()
                    }
                }
            }
            
            // Edit menu commands
            CommandGroup(replacing: .pasteboard) {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    if let selectedText = NSPasteboard.general.string(forType: .string) {
                        NSPasteboard.general.setString(selectedText, forType: .string)
                    }
                }
                .keyboardShortcut("c", modifiers: .command)
                
                Button("Paste") {
                    if let clipboardContent = NSPasteboard.general.string(forType: .string) {
                        // Handle paste operation
                        print("Pasting: \(clipboardContent)")
                    }
                }
                .keyboardShortcut("v", modifiers: .command)
                
                Divider()
                
                Button("Select All") {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
            }
            
            // View menu commands
            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    sidebarViewModel.toggleSidebar()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Increase Font Size") {
                    settingsViewModel.fontSize += 1
                }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(settingsViewModel.fontSize >= 24)
                
                Button("Decrease Font Size") {
                    settingsViewModel.fontSize -= 1
                }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(settingsViewModel.fontSize <= 12)
                
                Divider()
                
                Menu("Theme") {
                    ForEach(themeManager.availableThemes) { theme in
                        Button(theme.name) {
                            themeManager.currentTheme = theme
                        }
                    }
                    
                    Divider()
                    
                    Toggle("Use System Appearance", isOn: $themeManager.useSystemAppearance)
                }
            }
            
            // Chat menu commands
            CommandMenu("Chat") {
                Button("Send Message") {
                    // This is handled by the text field's onSubmit
                }
                .keyboardShortcut(.return, modifiers: .command)
                
                Button("Clear Current Chat") {
                    chatViewModel.clearCurrentChat()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(chatViewModel.currentConversation == nil || chatViewModel.messages.isEmpty)
                
                Button("Regenerate Response") {
                    chatViewModel.regenerateLastResponse()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(chatViewModel.currentConversation == nil || chatViewModel.messages.isEmpty || chatViewModel.isProcessing)
                
                Button("Stop Generation") {
                    chatViewModel.stopGeneration()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .disabled(!chatViewModel.isProcessing)
                
                Divider()
                
                Button("Start Voice Input") {
                    startVoiceInput()
                }
                .keyboardShortcut("m", modifiers: .command)
                .disabled(!multiModalManager.isSpeechRecognitionAvailable || multiModalManager.isRecording)
                
                Button("Stop Voice Input") {
                    stopVoiceInput()
                }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(!multiModalManager.isRecording)
            }
            
            // Plugins menu
            CommandMenu("Plugins") {
                ForEach(Array(pluginManager.availablePlugins), id: \.id) { plugin in
                    Toggle(plugin.name, isOn: Binding(
                        get: { pluginManager.enabledPlugins.contains { $0.id == plugin.id } },
                        set: { isEnabled in
                            if isEnabled {
                                pluginManager.enablePlugin(withID: plugin.id)
                            } else {
                                pluginManager.disablePlugin(withID: plugin.id)
                            }
                        }
                    ))
                }
                
                Divider()
                
                Button("Manage Plugins...") {
                    // Show plugin management view
                    settingsViewModel.selectedTab = .plugins
                    settingsViewModel.showSettings = true
                }
            }
            
            // AI Companion menu
            CommandMenu("AI Companion") {
                Button("Settings") {
                    settingsViewModel.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Divider()
                
                Button("Check for Updates") {
                    updateManager.checkForUpdates()
                }
                
                Divider()
                
                Button("Reset Onboarding") {
                    onboardingManager.resetOnboarding()
                }
                
                Divider()
                
                Button("About AI Companion") {
                    // Show about dialog
                }
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsViewModel)
                .environmentObject(themeManager)
                .environmentObject(pluginManager)
                .environmentObject(updateManager)
                .environmentObject(animationManager)
                .environmentObject(feedbackManager)
                .environmentObject(accessibilityManager)
                .environmentObject(localizationManager)
                .environmentObject(dragDropManager)
                .frame(width: 700, height: 500)
        }
    }
    
    /// Register default values for user defaults
    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            // General settings
            "isDarkMode": false,
            "fontSize": 14,
            "showTimestamps": true,
            "saveChatHistory": true,
            "maxConversationHistory": 50,
            "showUserAvatars": true,
            "showAIAvatars": true,
            "messageSpacing": 1.0,
            "enableAnalytics": false,
            "useSystemAppearance": true,
            "checkForUpdatesAutomatically": true,
            "hasCompletedOnboarding": false,
            
            // AI capabilities
            "enableVoiceInput": true,
            "enableVoiceOutput": true,
            "enablePlugins": true,
            "enableFunctionCalling": true,
            "enableToolUse": true,
            "enableMemory": true,
            "enableMultiModal": true,
            
            // Performance metrics
            "memoryCacheHits": 0,
            "memoryCacheMisses": 0,
            "diskCacheHits": 0,
            "diskCacheMisses": 0,
            
            // Animation settings
            "animationsEnabled": true,
            "animationSpeed": 1.0,
            "reduceMotion": false,
            
            // Feedback settings
            "hapticFeedbackEnabled": true,
            "soundEffectsEnabled": true,
            "soundVolume": 0.5,
            
            // Drag and drop settings
            "dragDropEnabled": true,
            "showDragDropVisualFeedback": true,
            
            // Accessibility settings
            "useLargerText": false,
            "useHighContrast": false,
            "reduceTransparency": false,
            "enableVoiceOverDescriptions": false,
            "fontSizeMultiplier": 1.0,
            
            // Localization settings
            "useSystemLanguage": true,
            "languageCode": "en"
        ])
    }
    
    /// Apply initial settings from user defaults
    private func applyInitialSettings() {
        // Apply theme settings
        if themeManager.useSystemAppearance {
            NSApp.appearance = nil // Use system appearance
        } else if themeManager.currentTheme.isDark {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        
        // Set up app termination handling
        NSApplication.shared.setActivationPolicy(.regular)
        
        // Register for app termination notification
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [self] _ in
            // Save all data before termination
            _ = persistenceController.save()
            chatViewModel.saveCurrentConversation()
            
            // Clean up resources
            backgroundTaskManager.cancelAllTasks()
        }
    }
    
    /// Initialize document processing capabilities
    private func initializeDocumentProcessing() {
        // Update Core Data model to include document entities
        persistenceController.container.addDocumentEntities()
        
        // Register for document-related notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DocumentAdded"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let document = notification.object as? Document {
                self?.chatViewModel.addDocumentReference(document)
            }
        }
        
        // Register for conversation changes to load referenced documents
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ConversationChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let conversationId = notification.object as? UUID {
                Task {
                    await self?.chatViewModel.loadReferencedDocuments(for: conversationId)
                }
            }
        }
    }
    
    /// Initialize advanced AI capabilities
    private func initializeAdvancedAICapabilities() {
        // Set up function calling
        if UserDefaults.standard.bool(forKey: "enableFunctionCalling") {
            // Function calling is initialized by the FunctionCallingManager singleton
        }
        
        // Set up tool use
        if UserDefaults.standard.bool(forKey: "enableToolUse") {
            // Tool use is initialized by the ToolUseManager singleton
        }
        
        // Set up memory
        if UserDefaults.standard.bool(forKey: "enableMemory") {
            // Memory is initialized by the AIMemoryManager singleton
            
            // Set up periodic memory pruning
            backgroundTaskManager.executePeriodicTask(interval: 24 * 60 * 60, name: "Memory Pruning") {
                // Prune memories older than 30 days
                try await self.aiMemoryManager.pruneOldMemories(olderThan: Date().addingTimeInterval(-30 * 24 * 60 * 60))
            }
        }
        
        // Set up multi-modal capabilities
        if UserDefaults.standard.bool(forKey: "enableMultiModal") {
            // Multi-modal capabilities are initialized by the MultiModalManager singleton
        }
    }
    
    /// Initialize performance optimizations
    private func initializePerformanceOptimizations() {
        // Set up background task manager
        // Already initialized as a singleton
        
        // Set up cache manager
        // Already initialized as a singleton
        
        // Set up periodic cache cleanup
        backgroundTaskManager.executePeriodicTask(interval: 24 * 60 * 60, name: "Cache Cleanup") {
            // Clear expired cache items older than 7 days
            self.cacheManager.clearExpiredItems(olderThan: Date().addingTimeInterval(-7 * 24 * 60 * 60))
        }
    }
    
    /// Show plugin import dialog
    private func showPluginImportDialog() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import Plugin"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["aiplugin"]
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                Task {
                    do {
                        try await pluginManager.installPlugin(from: url)
                    } catch {
                        // Handle error
                        print("Failed to install plugin: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Start voice input
    private func startVoiceInput() {
        Task {
            do {
                let recognitionStream = try await multiModalManager.startSpeechRecognition()
                
                for try await text in recognitionStream {
                    // Update the chat input field with the recognized text
                    await MainActor.run {
                        chatViewModel.inputText = text
                    }
                }
                
                // When recognition is complete, send the message
                if !chatViewModel.inputText.isEmpty {
                    await MainActor.run {
                        chatViewModel.sendMessage(chatViewModel.inputText)
                    }
                }
            } catch {
                print("Speech recognition error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Stop voice input
    private func stopVoiceInput() {
        multiModalManager.stopSpeechRecognition()
    }
}
