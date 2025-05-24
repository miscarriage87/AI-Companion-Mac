
//
//  SettingsView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// Settings panel view for the application
struct SettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var selectedTab = 0
    @State private var showResetConfirmation = false
    @State private var showClearDataConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack {
                ForEach(tabs.indices, id: \.self) { index in
                    TabButton(
                        title: tabs[index].title,
                        systemImage: tabs[index].icon,
                        isSelected: selectedTab == index,
                        action: { selectedTab = index }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider()
                .padding(.top, 12)
            
            // Tab content
            TabView(selection: $selectedTab) {
                generalSettingsView
                    .tag(0)
                
                aiProvidersSettingsView
                    .tag(1)
                
                appearanceSettingsView
                    .tag(2)
                
                advancedSettingsView
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedTab)
        }
        .frame(width: 700, height: 500)
        .alert("Reset All Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settingsViewModel.resetSettings()
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values? This cannot be undone.")
        }
        .alert("Clear All Data", isPresented: $showClearDataConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All Data", role: .destructive) {
                settingsViewModel.clearAllData()
            }
        } message: {
            Text("Are you sure you want to clear all data? This will delete all conversations, settings, and API keys. This cannot be undone.")
        }
    }
    
    // Tab definitions
    private var tabs: [(title: String, icon: String)] {
        [
            ("General", "gear"),
            ("AI Providers", "brain"),
            ("Appearance", "paintbrush"),
            ("Accessibility", "accessibility"),
            ("Animation", "wand.and.stars"),
            ("Advanced", "slider.horizontal.3")
        ]
    }
    
    // General settings tab
    private var generalSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // User profile section
                SettingsSection(title: "User Profile", systemImage: "person.fill") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Username")
                                .frame(width: 100, alignment: .leading)
                            
                            TextField("Enter your name", text: $settingsViewModel.username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Email")
                                .frame(width: 100, alignment: .leading)
                            
                            TextField("Enter your email", text: $settingsViewModel.email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                // Chat settings section
                SettingsSection(title: "Chat Settings", systemImage: "bubble.left.and.bubble.right.fill") {
                    VStack(spacing: 12) {
                        Toggle("Save Chat History", isOn: $settingsViewModel.saveChatHistory)
                            .toggleStyle(SwitchToggleStyle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Maximum Conversations")
                            
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(settingsViewModel.maxConversationHistory) },
                                    set: { settingsViewModel.maxConversationHistory = Int($0) }
                                ), in: 10...100, step: 10)
                                
                                Text("\(settingsViewModel.maxConversationHistory)")
                                    .frame(width: 40)
                            }
                        }
                        
                        Toggle("Show Timestamps", isOn: $settingsViewModel.showTimestamps)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                
                // Keyboard shortcuts section
                SettingsSection(title: "Keyboard Shortcuts", systemImage: "keyboard") {
                    VStack(alignment: .leading, spacing: 8) {
                        KeyboardShortcutRow(action: "New Chat", shortcut: "⌘N")
                        KeyboardShortcutRow(action: "Send Message", shortcut: "⌘↩")
                        KeyboardShortcutRow(action: "Clear Chat", shortcut: "⇧⌘K")
                        KeyboardShortcutRow(action: "Export Chat", shortcut: "⇧⌘E")
                        KeyboardShortcutRow(action: "Settings", shortcut: "⌘,")
                    }
                }
                
                Spacer()
                
                // Reset button
                HStack {
                    Spacer()
                    
                    Button("Reset All Settings") {
                        showResetConfirmation = true
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    // AI Providers settings tab
    private var aiProvidersSettingsView: View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Default provider section
                SettingsSection(title: "Default AI Provider", systemImage: "star.fill") {
                    Picker("Default Provider", selection: $settingsViewModel.defaultAIProviderId) {
                        Text("None").tag(UUID?.none)
                        
                        ForEach(settingsViewModel.aiProviders) { provider in
                            Text(provider.name).tag(Optional(provider.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // API keys section
                SettingsSection(title: "API Keys", systemImage: "key.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter your API keys for each provider")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(settingsViewModel.aiProviders) { provider in
                            if provider.requiresAPIKey {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(provider.name)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        SecureField("API Key", text: Binding(
                                            get: { settingsViewModel.apiKeys[provider.id.uuidString] ?? "" },
                                            set: { settingsViewModel.apiKeys[provider.id.uuidString] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        
                                        Button(action: {
                                            // Validate API key
                                            settingsViewModel.validateAPIKey(for: provider.id)
                                        }) {
                                            Text("Validate")
                                                .frame(width: 80)
                                        }
                                        .disabled(settingsViewModel.apiKeys[provider.id.uuidString]?.isEmpty ?? true)
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                        }
                    }
                }
                
                // Available providers section
                SettingsSection(title: "Available Providers", systemImage: "brain.head.profile") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(settingsViewModel.aiProviders) { provider in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(provider.name)
                                        .fontWeight(.medium)
                                    
                                    Text(provider.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { settingsViewModel.enabledProviders.contains(provider.id) },
                                    set: { isEnabled in
                                        if isEnabled {
                                            settingsViewModel.enabledProviders.insert(provider.id)
                                        } else {
                                            settingsViewModel.enabledProviders.remove(provider.id)
                                        }
                                    }
                                ))
                                .toggleStyle(SwitchToggleStyle())
                                .labelsHidden()
                            }
                            .padding(.vertical, 4)
                            
                            if provider != settingsViewModel.aiProviders.last {
                                Divider()
                            }
                        }
                    }
                }
                
                // Add new provider button
                Button(action: {
                    // Add new provider functionality would go here
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Custom Provider")
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // Appearance settings tab
    private var appearanceSettingsView: View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Theme section
                SettingsSection(title: "Theme", systemImage: "paintpalette") {
                    VStack(spacing: 12) {
                        Toggle("Dark Mode", isOn: $settingsViewModel.isDarkMode)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Divider()
                        
                        ColorPicker("Accent Color", selection: $settingsViewModel.accentColor)
                    }
                }
                
                // Text size section
                SettingsSection(title: "Text Size", systemImage: "textformat.size") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("A")
                                .font(.system(size: 12))
                            
                            Slider(value: Binding(
                                get: { Double(settingsViewModel.fontSize) },
                                set: { settingsViewModel.fontSize = Int($0) }
                            ), in: 12...24, step: 1)
                            
                            Text("A")
                                .font(.system(size: 24))
                        }
                        
                        Text("Font Size: \(settingsViewModel.fontSize)pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("Sample Text")
                            .font(.system(size: CGFloat(settingsViewModel.fontSize)))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                
                // Chat appearance section
                SettingsSection(title: "Chat Appearance", systemImage: "bubble.left.and.bubble.right") {
                    VStack(spacing: 12) {
                        Toggle("Show User Avatars", isOn: $settingsViewModel.showUserAvatars)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Toggle("Show AI Avatars", isOn: $settingsViewModel.showAIAvatars)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Message Spacing")
                            
                            HStack {
                                Text("Compact")
                                    .font(.caption)
                                
                                Slider(value: $settingsViewModel.messageSpacing, in: 0...2, step: 1)
                                
                                Text("Spacious")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // Advanced settings tab
    private var advancedSettingsView: View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Data management section
                SettingsSection(title: "Data Management", systemImage: "externaldrive") {
                    VStack(spacing: 12) {
                        Toggle("Enable Analytics", isOn: $settingsViewModel.enableAnalytics)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Divider()
                        
                        HStack {
                            Button("Export All Data") {
                                settingsViewModel.exportAllData()
                            }
                            
                            Spacer()
                            
                            Button("Clear All Data") {
                                showClearDataConfirmation = true
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                // Developer options section
                SettingsSection(title: "Developer Options", systemImage: "hammer") {
                    VStack(spacing: 12) {
                        Toggle("Debug Mode", isOn: $settingsViewModel.debugMode)
                            .toggleStyle(SwitchToggleStyle())
                        
                        if settingsViewModel.debugMode {
                            Divider()
                            
                            Toggle("Show API Requests", isOn: $settingsViewModel.showAPIRequests)
                                .toggleStyle(SwitchToggleStyle())
                                .padding(.leading, 20)
                            
                            Toggle("Log to Console", isOn: $settingsViewModel.logToConsole)
                                .toggleStyle(SwitchToggleStyle())
                                .padding(.leading, 20)
                        }
                    }
                }
                
                // About section
                SettingsSection(title: "About", systemImage: "info.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Companion")
                            .font(.headline)
                        
                        Text("Version 1.0.0")
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("© 2025 AI Companion Team")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Link("Visit Website", destination: URL(string: "https://example.com")!)
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

/// Settings section view
struct SettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
            }
            
            content
                .padding(.leading, 24)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

/// Tab button view
struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Keyboard shortcut row view
struct KeyboardShortcutRow: View {
    let action: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(action)
            
            Spacer()
            
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsViewModel())
    }
}
