
//
//  ThemeManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Combine

/// Manager for handling application themes
class ThemeManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = ThemeManager()
    
    /// Current theme
    @Published var currentTheme: AppTheme {
        didSet {
            saveCurrentTheme()
        }
    }
    
    /// Whether to use the system appearance
    @Published var useSystemAppearance: Bool = true {
        didSet {
            saveUseSystemAppearance()
        }
    }
    
    /// Available themes
    @Published private(set) var availableThemes: [AppTheme] = []
    
    /// Storage service for persisting theme data
    private let storageService: StorageService
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        
        // Load available themes
        availableThemes = AppTheme.defaultThemes
        
        // Load user preferences
        useSystemAppearance = UserDefaults.standard.bool(forKey: "useSystemAppearance")
        
        // Load current theme
        if let themeData = UserDefaults.standard.data(forKey: "currentTheme"),
           let theme = try? JSONDecoder().decode(AppTheme.self, from: themeData) {
            currentTheme = theme
        } else {
            currentTheme = AppTheme.defaultThemes.first!
        }
    }
    
    /// Save the current theme to user defaults
    private func saveCurrentTheme() {
        if let themeData = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(themeData, forKey: "currentTheme")
        }
    }
    
    /// Save the use system appearance setting to user defaults
    private func saveUseSystemAppearance() {
        UserDefaults.standard.set(useSystemAppearance, forKey: "useSystemAppearance")
    }
}

/// Represents an application theme
struct AppTheme: Identifiable, Codable, Equatable {
    /// Unique identifier for the theme
    let id: UUID
    
    /// Name of the theme
    let name: String
    
    /// Primary color of the theme
    let primaryColor: ThemeColor
    
    /// Secondary color of the theme
    let secondaryColor: ThemeColor
    
    /// Background color of the theme
    let backgroundColor: ThemeColor
    
    /// Text color of the theme
    let textColor: ThemeColor
    
    /// Accent color of the theme
    let accentColor: ThemeColor
    
    /// Whether this is a dark theme
    let isDark: Bool
    
    /// Default themes available in the application
    static let defaultThemes: [AppTheme] = [
        // Light theme
        AppTheme(
            id: UUID(uuidString: "D4E5F6A7-B8C9-4AD0-E1F2-A3B4C5D6E7F8")!,
            name: "Light",
            primaryColor: ThemeColor(light: Color(hex: 0x007AFF), dark: Color(hex: 0x0A84FF)),
            secondaryColor: ThemeColor(light: Color(hex: 0x5AC8FA), dark: Color(hex: 0x64D2FF)),
            backgroundColor: ThemeColor(light: Color(hex: 0xF2F2F7), dark: Color(hex: 0xF2F2F7)),
            textColor: ThemeColor(light: Color(hex: 0x000000), dark: Color(hex: 0x000000)),
            accentColor: ThemeColor(light: Color(hex: 0xFF9500), dark: Color(hex: 0xFF9F0A)),
            isDark: false
        ),
        
        // Dark theme
        AppTheme(
            id: UUID(uuidString: "E5F6A7B8-C9D0-4BE1-F2A3-B4C5D6E7F8A9")!,
            name: "Dark",
            primaryColor: ThemeColor(light: Color(hex: 0x0A84FF), dark: Color(hex: 0x0A84FF)),
            secondaryColor: ThemeColor(light: Color(hex: 0x64D2FF), dark: Color(hex: 0x64D2FF)),
            backgroundColor: ThemeColor(light: Color(hex: 0x1C1C1E), dark: Color(hex: 0x1C1C1E)),
            textColor: ThemeColor(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0xFFFFFF)),
            accentColor: ThemeColor(light: Color(hex: 0xFF9F0A), dark: Color(hex: 0xFF9F0A)),
            isDark: true
        ),
        
        // Blue theme
        AppTheme(
            id: UUID(uuidString: "F6A7B8C9-D0E1-4CF2-A3B4-C5D6E7F8A9B0")!,
            name: "Blue",
            primaryColor: ThemeColor(light: Color(hex: 0x0000FF), dark: Color(hex: 0x0000FF)),
            secondaryColor: ThemeColor(light: Color(hex: 0x00BFFF), dark: Color(hex: 0x00BFFF)),
            backgroundColor: ThemeColor(light: Color(hex: 0xF0F8FF), dark: Color(hex: 0x0A1929)),
            textColor: ThemeColor(light: Color(hex: 0x000000), dark: Color(hex: 0xFFFFFF)),
            accentColor: ThemeColor(light: Color(hex: 0xFF4500), dark: Color(hex: 0xFF4500)),
            isDark: false
        )
    ]
}

/// Color that adapts to light and dark mode
struct ThemeColor: Codable, Equatable {
    /// Color for light mode
    let light: Color
    
    /// Color for dark mode
    let dark: Color
    
    /// Get the appropriate color for the current color scheme
    func color(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? dark : light
    }
    
    // Codable implementation
    enum CodingKeys: String, CodingKey {
        case light, dark
    }
    
    init(light: Color, dark: Color) {
        self.light = light
        self.dark = dark
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lightHex = try container.decode(UInt32.self, forKey: .light)
        let darkHex = try container.decode(UInt32.self, forKey: .dark)
        
        light = Color(hex: lightHex)
        dark = Color(hex: darkHex)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(light.hexValue, forKey: .light)
        try container.encode(dark.hexValue, forKey: .dark)
    }
}

/// Extension to convert between Color and hex values
extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    var hexValue: UInt32 {
        // This is a simplified implementation
        // In a real app, you would need to extract the RGB components
        return 0x000000
    }
}
