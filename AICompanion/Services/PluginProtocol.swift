//
//  PluginProtocol.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI

/// Protocol that all plugins must conform to
protocol PluginProtocol: AnyObject, Identifiable {
    /// Unique identifier for the plugin
    var id: UUID { get }
    
    /// Name of the plugin
    var name: String { get }
    
    /// Description of what the plugin does
    var description: String { get }
    
    /// Version of the plugin
    var version: String { get }
    
    /// Author of the plugin
    var author: String { get }
    
    /// URL for more information about the plugin
    var websiteURL: URL? { get }
    
    /// Icon to display for the plugin
    var icon: Image { get }
    
    /// Category of the plugin
    var category: PluginCategory { get }
    
    /// Tools provided by the plugin
    var tools: [AITool] { get }
    
    /// Initialize the plugin
    func initialize() async throws
    
    /// Clean up resources when the plugin is unloaded
    func cleanup() async
    
    /// Get the settings view for the plugin
    func settingsView() -> AnyView?
    
    /// Check if the plugin is compatible with the current app version
    func isCompatible(withAppVersion version: String) -> Bool
}

/// Default implementation for optional methods
extension PluginProtocol {
    func settingsView() -> AnyView? {
        return nil
    }
    
    func isCompatible(withAppVersion version: String) -> Bool {
        // By default, assume compatibility
        return true
    }
}

/// Categories for plugins
enum PluginCategory: String, Codable, CaseIterable {
    case productivity
    case development
    case communication
    case utilities
    case entertainment
    case education
    case other
    
    var displayName: String {
        switch self {
        case .productivity:
            return "Productivity"
        case .development:
            return "Development"
        case .communication:
            return "Communication"
        case .utilities:
            return "Utilities"
        case .entertainment:
            return "Entertainment"
        case .education:
            return "Education"
        case .other:
            return "Other"
        }
    }
    
    var icon: Image {
        switch self {
        case .productivity:
            return Image(systemName: "briefcase.fill")
        case .development:
            return Image(systemName: "chevron.left.forwardslash.chevron.right")
        case .communication:
            return Image(systemName: "message.fill")
        case .utilities:
            return Image(systemName: "wrench.fill")
        case .entertainment:
            return Image(systemName: "gamecontroller.fill")
        case .education:
            return Image(systemName: "book.fill")
        case .other:
            return Image(systemName: "ellipsis.circle.fill")
        }
    }
}

/// Errors that can occur with plugins
enum PluginError: Error, LocalizedError {
    case initializationFailed(String)
    case incompatibleVersion(String)
    case missingDependency(String)
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Plugin initialization failed: \(message)"
        case .incompatibleVersion(let message):
            return "Plugin is incompatible with this version: \(message)"
        case .missingDependency(let message):
            return "Plugin is missing a dependency: \(message)"
        case .executionFailed(let message):
            return "Plugin execution failed: \(message)"
        }
    }
}
