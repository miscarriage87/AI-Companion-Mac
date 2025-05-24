
//
//  AccessibilityManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Combine

/// Manager for handling application accessibility
class AccessibilityManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = AccessibilityManager()
    
    /// Whether to use larger text
    @Published var useLargerText: Bool = false {
        didSet {
            UserDefaults.standard.set(useLargerText, forKey: "useLargerText")
        }
    }
    
    /// Whether to use high contrast
    @Published var useHighContrast: Bool = false {
        didSet {
            UserDefaults.standard.set(useHighContrast, forKey: "useHighContrast")
        }
    }
    
    /// Whether to reduce motion
    @Published var reduceMotion: Bool = false {
        didSet {
            UserDefaults.standard.set(reduceMotion, forKey: "reduceMotion")
        }
    }
    
    /// Whether to reduce transparency
    @Published var reduceTransparency: Bool = false {
        didSet {
            UserDefaults.standard.set(reduceTransparency, forKey: "reduceTransparency")
        }
    }
    
    /// Whether to enable VoiceOver descriptions
    @Published var enableVoiceOverDescriptions: Bool = false {
        didSet {
            UserDefaults.standard.set(enableVoiceOverDescriptions, forKey: "enableVoiceOverDescriptions")
        }
    }
    
    /// Font size multiplier
    @Published var fontSizeMultiplier: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(fontSizeMultiplier, forKey: "fontSizeMultiplier")
        }
    }
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load user preferences
        useLargerText = UserDefaults.standard.bool(forKey: "useLargerText")
        useHighContrast = UserDefaults.standard.bool(forKey: "useHighContrast")
        reduceMotion = UserDefaults.standard.bool(forKey: "reduceMotion")
        reduceTransparency = UserDefaults.standard.bool(forKey: "reduceTransparency")
        enableVoiceOverDescriptions = UserDefaults.standard.bool(forKey: "enableVoiceOverDescriptions")
        
        let storedFontSizeMultiplier = UserDefaults.standard.double(forKey: "fontSizeMultiplier")
        fontSizeMultiplier = storedFontSizeMultiplier > 0 ? storedFontSizeMultiplier : 1.0
        
        // Subscribe to accessibility notifications
        NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateFromSystemSettings()
            }
            .store(in: &cancellables)
        
        // Initialize with system accessibility settings
        updateFromSystemSettings()
    }
    
    /// Update settings based on system accessibility preferences
    private func updateFromSystemSettings() {
        let workspace = NSWorkspace.shared
        
        // Update reduce motion setting
        let systemReduceMotion = workspace.accessibilityDisplayShouldReduceMotion
        if systemReduceMotion != reduceMotion {
            reduceMotion = systemReduceMotion
        }
        
        // Update reduce transparency setting
        let systemReduceTransparency = workspace.accessibilityDisplayShouldReduceTransparency
        if systemReduceTransparency != reduceTransparency {
            reduceTransparency = systemReduceTransparency
        }
        
        // Update high contrast setting
        let systemHighContrast = workspace.accessibilityDisplayShouldIncreaseContrast
        if systemHighContrast != useHighContrast {
            useHighContrast = systemHighContrast
        }
        
        // Check if VoiceOver is running
        let voiceOverRunning = NSWorkspace.shared.isVoiceOverEnabled
        if voiceOverRunning && !enableVoiceOverDescriptions {
            enableVoiceOverDescriptions = true
        }
    }
    
    /// Get the adjusted font size based on accessibility settings
    func adjustedFontSize(_ size: CGFloat) -> CGFloat {
        return size * CGFloat(fontSizeMultiplier) * (useLargerText ? 1.3 : 1.0)
    }
    
    /// Get the adjusted color based on accessibility settings
    func adjustedColor(_ color: Color) -> Color {
        if useHighContrast {
            // Increase contrast by making dark colors darker and light colors lighter
            return color
        } else {
            return color
        }
    }
    
    /// Get the adjusted animation duration based on accessibility settings
    func adjustedAnimationDuration(_ duration: Double) -> Double {
        if reduceMotion {
            return min(duration * 0.5, 0.1) // Significantly reduce animation time
        } else {
            return duration
        }
    }
    
    /// Check if VoiceOver is currently running
    var isVoiceOverRunning: Bool {
        return NSWorkspace.shared.isVoiceOverEnabled
    }
}

// MARK: - NSWorkspace Extension for Accessibility

extension NSWorkspace {
    /// Check if VoiceOver is enabled
    var isVoiceOverEnabled: Bool {
        // This is a simplified check and may not be 100% accurate
        // A more accurate check would involve using the Accessibility API
        return CFPreferencesCopyAppValue("voiceOverOnOffKey" as CFString, "com.apple.universalaccess" as CFString) as? Bool ?? false
    }
}

// MARK: - View Extensions for Accessibility

extension View {
    /// Apply accessibility adjustments to a view
    func withAccessibility() -> some View {
        let manager = AccessibilityManager.shared
        
        return self
            .environment(\.accessibilityEnabled, manager.enableVoiceOverDescriptions || manager.isVoiceOverRunning)
            .environment(\.accessibilityReduceMotion, manager.reduceMotion)
            .environment(\.accessibilityReduceTransparency, manager.reduceTransparency)
            .environment(\.accessibilityInvertColors, manager.useHighContrast)
    }
    
    /// Add detailed accessibility label for VoiceOver
    func accessibilityLabel(_ label: String, detailed: Bool = false) -> some View {
        if detailed && !AccessibilityManager.shared.enableVoiceOverDescriptions {
            return self
        } else {
            return self.accessibilityLabel(Text(label))
        }
    }
    
    /// Add detailed accessibility hint for VoiceOver
    func accessibilityHint(_ hint: String, detailed: Bool = false) -> some View {
        if detailed && !AccessibilityManager.shared.enableVoiceOverDescriptions {
            return self
        } else {
            return self.accessibilityHint(Text(hint))
        }
    }
    
    /// Adjust font size based on accessibility settings
    func accessibilityAdjustedFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        let adjustedSize = AccessibilityManager.shared.adjustedFontSize(size)
        return self.font(.system(size: adjustedSize, weight: weight))
    }
}
