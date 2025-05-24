//
//  PluginManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import SwiftUI

/// Manager for handling plugins
class PluginManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = PluginManager()
    
    /// Available plugins
    @Published private(set) var availablePlugins: [any PluginProtocol] = []
    
    /// Enabled plugins
    @Published private(set) var enabledPlugins: [any PluginProtocol] = []
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Whether to show the error alert
    @Published var showError: Bool = false
    
    /// Storage service for persisting plugin data
    private let storageService: StorageService
    
    /// Background task manager for plugin operations
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Plugin directory URL
    private let pluginDirectoryURL: URL
    
    /// Current app version
    private let appVersion: String
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        
        // Get app version
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        // Set up plugin directory
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = applicationSupport.appendingPathComponent("AICompanion")
        self.pluginDirectoryURL = appDirectory.appendingPathComponent("Plugins")
        
        // Create plugin directory if it doesn't exist
        try? FileManager.default.createDirectory(at: pluginDirectoryURL, withIntermediateDirectories: true)
        
        // Load enabled plugin IDs from user defaults
        loadEnabledPluginSettings()
        
        // Load built-in plugins
        loadBuiltInPlugins()
        
        // Load user plugins
        loadUserPlugins()
    }
    
    /// Load enabled plugin settings from user defaults
    private func loadEnabledPluginSettings() {
        let enabledPluginIDs = UserDefaults.standard.stringArray(forKey: "enabledPluginIDs") ?? []
        
        // Convert string IDs to UUIDs
        let enabledUUIDs = enabledPluginIDs.compactMap { UUID(uuidString: $0) }
        
        // Filter available plugins to get enabled ones
        enabledPlugins = availablePlugins.filter { enabledUUIDs.contains($0.id) }
    }
    
    /// Save enabled plugin settings to user defaults
    private func saveEnabledPluginSettings() {
        let enabledPluginIDs = enabledPlugins.map { $0.id.uuidString }
        UserDefaults.standard.set(enabledPluginIDs, forKey: "enabledPluginIDs")
    }
    
    /// Load built-in plugins
    private func loadBuiltInPlugins() {
        // Create instances of built-in plugins
        let builtInPlugins: [any PluginProtocol] = [
            WeatherPlugin(),
            CalculatorPlugin(),
            WebSearchPlugin()
        ]
        
        // Initialize each plugin
        for plugin in builtInPlugins {
            backgroundTaskManager.executeTask {
                do {
                    try await plugin.initialize()
                    
                    // Add to available plugins
                    DispatchQueue.main.async {
                        self.availablePlugins.append(plugin)
                        
                        // Check if this plugin should be enabled by default
                        if self.shouldEnableByDefault(plugin) {
                            self.enabledPlugins.append(plugin)
                            self.saveEnabledPluginSettings()
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to initialize plugin \(plugin.name): \(error.localizedDescription)"
                        self.showError = true
                    }
                }
                
                return true
            }
        }
    }
    
    /// Load user plugins from the plugin directory
    private func loadUserPlugins() {
        // In a real implementation, this would dynamically load plugin bundles
        // For this example, we'll just simulate it
        
        // Get all plugin bundle URLs
        let pluginBundleURLs = (try? FileManager.default.contentsOfDirectory(at: pluginDirectoryURL, includingPropertiesForKeys: nil)) ?? []
        
        // Load each plugin bundle
        for bundleURL in pluginBundleURLs {
            // In a real implementation, this would load the bundle and instantiate the plugin
            // For this example, we'll just log it
            print("Would load plugin bundle at: \(bundleURL.path)")
        }
    }
    
    /// Check if a plugin should be enabled by default
    private func shouldEnableByDefault(_ plugin: any PluginProtocol) -> Bool {
        // In a real implementation, this would check plugin metadata or user preferences
        // For this example, we'll enable all built-in plugins by default
        return true
    }
    
    /// Enable a plugin
    func enablePlugin(withID id: UUID) {
        guard let plugin = availablePlugins.first(where: { $0.id == id }),
              !enabledPlugins.contains(where: { $0.id == id }) else {
            return
        }
        
        // Check compatibility
        if !plugin.isCompatible(withAppVersion: appVersion) {
            errorMessage = "Plugin \(plugin.name) is not compatible with this version of the app"
            showError = true
            return
        }
        
        // Initialize the plugin if needed
        backgroundTaskManager.executeTask {
            do {
                try await plugin.initialize()
                
                // Add to enabled plugins
                DispatchQueue.main.async {
                    self.enabledPlugins.append(plugin)
                    self.saveEnabledPluginSettings()
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to initialize plugin \(plugin.name): \(error.localizedDescription)"
                    self.showError = true
                }
            }
            
            return true
        }
    }
    
    /// Disable a plugin
    func disablePlugin(withID id: UUID) {
        guard let index = enabledPlugins.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let plugin = enabledPlugins[index]
        
        // Clean up the plugin
        backgroundTaskManager.executeTask {
            await plugin.cleanup()
            
            // Remove from enabled plugins
            DispatchQueue.main.async {
                self.enabledPlugins.remove(at: index)
                self.saveEnabledPluginSettings()
            }
            
            return true
        }
    }
    
    /// Install a plugin from a URL
    func installPlugin(from url: URL) async throws {
        // In a real implementation, this would download and install the plugin
        // For this example, we'll just simulate it
        
        // Generate a unique filename
        let filename = url.lastPathComponent
        let destinationURL = pluginDirectoryURL.appendingPathComponent(filename)
        
        // Download the plugin
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Save the plugin to disk
        try data.write(to: destinationURL)
        
        // Load the plugin
        // In a real implementation, this would load the bundle and instantiate the plugin
        
        // Refresh the plugin list
        loadUserPlugins()
    }
    
    /// Uninstall a plugin
    func uninstallPlugin(withID id: UUID) async throws {
        // Disable the plugin first
        disablePlugin(withID: id)
        
        // Find the plugin
        guard let plugin = availablePlugins.first(where: { $0.id == id }) else {
            return
        }
        
        // Remove the plugin from available plugins
        if let index = availablePlugins.firstIndex(where: { $0.id == id }) {
            availablePlugins.remove(at: index)
        }
        
        // In a real implementation, this would remove the plugin bundle
        // For this example, we'll just simulate it
        
        // Find the plugin bundle URL
        let pluginBundleURLs = (try? FileManager.default.contentsOfDirectory(at: pluginDirectoryURL, includingPropertiesForKeys: nil)) ?? []
        
        // Find the bundle for this plugin
        // In a real implementation, this would match the bundle identifier with the plugin ID
        // For this example, we'll just log it
        print("Would uninstall plugin: \(plugin.name)")
    }
    
    /// Get all tools from enabled plugins
    func getAllTools() -> [AITool] {
        return enabledPlugins.flatMap { $0.tools }
    }
    
    /// Get a plugin by ID
    func getPlugin(withID id: UUID) -> (any PluginProtocol)? {
        return availablePlugins.first { $0.id == id }
    }
    
    /// Get plugins by category
    func getPlugins(inCategory category: PluginCategory) -> [any PluginProtocol] {
        return availablePlugins.filter { $0.category == category }
    }
}
