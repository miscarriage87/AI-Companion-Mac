
//
//  LocalizationManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Combine

/// Manager for handling application localization
class LocalizationManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = LocalizationManager()
    
    /// Available languages
    @Published private(set) var availableLanguages: [Language] = []
    
    /// Current language
    @Published var currentLanguage: Language {
        didSet {
            if currentLanguage.code != oldValue.code {
                setLanguage(currentLanguage.code)
            }
        }
    }
    
    /// Whether to use system language
    @Published var useSystemLanguage: Bool = true {
        didSet {
            UserDefaults.standard.set(useSystemLanguage, forKey: "useSystemLanguage")
            if useSystemLanguage {
                loadSystemLanguage()
            }
        }
    }
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize available languages
        availableLanguages = [
            Language(code: "en", name: "English", localizedName: "English"),
            Language(code: "es", name: "Spanish", localizedName: "Español"),
            Language(code: "fr", name: "French", localizedName: "Français"),
            Language(code: "de", name: "German", localizedName: "Deutsch"),
            Language(code: "it", name: "Italian", localizedName: "Italiano"),
            Language(code: "ja", name: "Japanese", localizedName: "日本語"),
            Language(code: "ko", name: "Korean", localizedName: "한국어"),
            Language(code: "zh-Hans", name: "Chinese (Simplified)", localizedName: "简体中文"),
            Language(code: "zh-Hant", name: "Chinese (Traditional)", localizedName: "繁體中文"),
            Language(code: "ru", name: "Russian", localizedName: "Русский"),
            Language(code: "pt", name: "Portuguese", localizedName: "Português"),
            Language(code: "ar", name: "Arabic", localizedName: "العربية")
        ]
        
        // Load user preferences
        useSystemLanguage = UserDefaults.standard.bool(forKey: "useSystemLanguage")
        
        // Set initial language
        if useSystemLanguage {
            currentLanguage = systemLanguage
        } else if let languageCode = UserDefaults.standard.string(forKey: "languageCode"),
                  let language = availableLanguages.first(where: { $0.code == languageCode }) {
            currentLanguage = language
        } else {
            currentLanguage = availableLanguages.first!
        }
        
        // Subscribe to system language changes
        NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .sink { [weak self] _ in
                if self?.useSystemLanguage == true {
                    self?.loadSystemLanguage()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Get the system language
    private var systemLanguage: Language {
        let preferredLanguages = Locale.preferredLanguages
        if let preferredLanguageCode = preferredLanguages.first,
           let language = availableLanguages.first(where: { $0.code == preferredLanguageCode }) {
            return language
        } else if let languageCode = Locale.current.languageCode,
                  let language = availableLanguages.first(where: { $0.code == languageCode }) {
            return language
        } else {
            return availableLanguages.first!
        }
    }
    
    /// Load the system language
    private func loadSystemLanguage() {
        let newLanguage = systemLanguage
        if newLanguage.code != currentLanguage.code {
            currentLanguage = newLanguage
        }
    }
    
    /// Set the application language
    private func setLanguage(_ languageCode: String) {
        // Save the selected language code
        UserDefaults.standard.set(languageCode, forKey: "languageCode")
        
        // Update the app's language
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Post notification for language change
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: languageCode)
    }
    
    /// Get localized string for a key
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    /// Get localized string for a key with arguments
    func localizedString(for key: String, with arguments: CVarArg..., comment: String = "") -> String {
        let format = NSLocalizedString(key, comment: comment)
        return String(format: format, arguments: arguments)
    }
}

/// Represents a language
struct Language: Identifiable, Equatable {
    /// Language code (e.g., "en", "es")
    let code: String
    
    /// English name of the language
    let name: String
    
    /// Localized name of the language (in its own language)
    let localizedName: String
    
    /// Unique identifier
    var id: String { code }
    
    static func == (lhs: Language, rhs: Language) -> Bool {
        return lhs.code == rhs.code
    }
}

// MARK: - View Extensions for Localization

extension View {
    /// Apply localization to a view
    func localized() -> some View {
        self.environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.code))
    }
}

// MARK: - String Extension for Localization

extension String {
    /// Get localized version of a string
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    /// Get localized version of a string with arguments
    func localized(with arguments: CVarArg...) -> String {
        return LocalizationManager.shared.localizedString(for: self, with: arguments)
    }
}
