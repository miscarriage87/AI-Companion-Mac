//
//  AICompanionApp.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import SwiftUI
import Combine

@main
struct AICompanionApp: App {
    // Core managers and services
    @StateObject private var userPreferencesManager = UserPreferencesManager()
    @StateObject private var contextManager = ContextManager()
    @StateObject private var userBehaviorAnalyzer: UserBehaviorAnalyzer
    @StateObject private var personalizationManager: PersonalizationManager
    @StateObject private var smartScheduler: SmartScheduler
    @StateObject private var taskPrioritizer: TaskPrioritizer
    @StateObject private var arCompanion = ARCompanion()
    @StateObject private var collaborationManager = CollaborationManager()
    
    // UI state
    @State private var selectedTab = 0
    @State private var showARView = false
    @State private var showCollaborationView = false
    
    // Initialize dependencies
    init() {
        // Create instances with proper dependency injection
        let userPrefs = UserPreferencesManager()
        let context = ContextManager()
        
        let behaviorAnalyzer = UserBehaviorAnalyzer(userPreferencesManager: userPrefs)
        let personalization = PersonalizationManager(
            userPreferencesManager: userPrefs,
            userBehaviorAnalyzer: behaviorAnalyzer
        )
        
        let scheduler = SmartScheduler(
            userPreferencesManager: userPrefs,
            contextManager: context
        )
        
        let prioritizer = TaskPrioritizer(
            userPreferencesManager: userPrefs,
            contextManager: context
        )
        
        // Assign to state objects
        _userPreferencesManager = StateObject(wrappedValue: userPrefs)
        _contextManager = StateObject(wrappedValue: context)
        _userBehaviorAnalyzer = StateObject(wrappedValue: behaviorAnalyzer)
        _personalizationManager = StateObject(wrappedValue: personalization)
        _smartScheduler = StateObject(wrappedValue: scheduler)
        _taskPrioritizer = StateObject(wrappedValue: prioritizer)
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                // Main chat interface
                ChatView()
                    .environmentObject(userPreferencesManager)
                    .environmentObject(contextManager)
                    .environmentObject(personalizationManager)
                    .tabItem {
                        Label("Chat", systemImage: "bubble.left.fill")
                    }
                    .tag(0)
                
                // Productivity features
                ProductivityView()
                    .environmentObject(smartScheduler)
                    .environmentObject(taskPrioritizer)
                    .environmentObject(contextManager)
                    .tabItem {
                        Label("Productivity", systemImage: "calendar")
                    }
                    .tag(1)
                
                // AR features
                ARFeaturesView()
                    .environmentObject(arCompanion)
                    .environmentObject(contextManager)
                    .tabItem {
                        Label("Spatial", systemImage: "arkit")
                    }
                    .tag(2)
                
                // Collaboration features
                CollaborationView()
                    .environmentObject(collaborationManager)
                    .tabItem {
                        Label("Collaborate", systemImage: "person.3.fill")
                    }
                    .tag(3)
                
                // Settings
                SettingsView()
                    .environmentObject(userPreferencesManager)
                    .environmentObject(personalizationManager)
                    .environmentObject(userBehaviorAnalyzer)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
            .onAppear {
                // Apply personalized UI settings
                applyPersonalizedUI()
            }
            .onChange(of: selectedTab) { newValue in
                // Record tab selection as user interaction
                recordTabSelection(newValue)
            }
        }
    }
    
    // Apply personalized UI settings from the personalization manager
    private func applyPersonalizedUI() {
        let settings = personalizationManager.getPersonalizedUISettings()
        
        // Apply color scheme
        if let colorScheme = settings["colorScheme"] as? String {
            // In a real app, this would set the app's color scheme
            print("Setting color scheme to: \(colorScheme)")
        }
        
        // Apply font size
        if let fontSize = settings["fontSize"] as? String {
            // In a real app, this would set the app's font size
            print("Setting font size to: \(fontSize)")
        }
        
        // Apply other UI settings as needed
    }
    
    // Record tab selection as a user interaction
    private func recordTabSelection(_ tab: Int) {
        let tabNames = ["chat", "productivity", "spatial", "collaborate", "settings"]
        if tab < tabNames.count {
            let interaction = UserInteraction(
                id: UUID(),
                timestamp: Date(),
                type: .command,
                feature: tabNames[tab],
                metadata: [:]
            )
            userBehaviorAnalyzer.recordInteraction(interaction)
        }
    }
}

// MARK: - View Placeholders

// These would be implemented in separate files in a real app

struct ChatView: View {
    @EnvironmentObject var userPreferencesManager: UserPreferencesManager
    @EnvironmentObject var contextManager: ContextManager
    @EnvironmentObject var personalizationManager: PersonalizationManager
    
    var body: some View {
        Text("Chat Interface")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProductivityView: View {
    @EnvironmentObject var smartScheduler: SmartScheduler
    @EnvironmentObject var taskPrioritizer: TaskPrioritizer
    @EnvironmentObject var contextManager: ContextManager
    
    var body: some View {
        Text("Productivity Features")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ARFeaturesView: View {
    @EnvironmentObject var arCompanion: ARCompanion
    @EnvironmentObject var contextManager: ContextManager
    
    var body: some View {
        Text("Spatial Computing Features")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CollaborationView: View {
    @EnvironmentObject var collaborationManager: CollaborationManager
    
    var body: some View {
        Text("Collaboration Features")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsView: View {
    @EnvironmentObject var userPreferencesManager: UserPreferencesManager
    @EnvironmentObject var personalizationManager: PersonalizationManager
    @EnvironmentObject var userBehaviorAnalyzer: UserBehaviorAnalyzer
    
    var body: some View {
        Text("Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
