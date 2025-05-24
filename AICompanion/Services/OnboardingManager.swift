
//
//  OnboardingManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Combine

/// Manager for handling application onboarding
class OnboardingManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = OnboardingManager()
    
    /// Whether onboarding has been completed
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            saveOnboardingStatus()
        }
    }
    
    /// Current onboarding step
    @Published var currentStep: OnboardingStep = .welcome
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load onboarding status
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    /// Save the onboarding status to user defaults
    private func saveOnboardingStatus() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
    }
    
    /// Reset onboarding status
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = .welcome
    }
    
    /// Advance to the next onboarding step
    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .features
        case .features:
            currentStep = .aiProviders
        case .aiProviders:
            currentStep = .privacy
        case .privacy:
            currentStep = .complete
        case .complete:
            hasCompletedOnboarding = true
        }
    }
    
    /// Go back to the previous onboarding step
    func previousStep() {
        switch currentStep {
        case .welcome:
            break // Already at first step
        case .features:
            currentStep = .welcome
        case .aiProviders:
            currentStep = .features
        case .privacy:
            currentStep = .aiProviders
        case .complete:
            currentStep = .privacy
        }
    }
}

/// Onboarding steps
enum OnboardingStep {
    case welcome
    case features
    case aiProviders
    case privacy
    case complete
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to AI Companion"
        case .features:
            return "Discover Features"
        case .aiProviders:
            return "AI Providers"
        case .privacy:
            return "Privacy & Security"
        case .complete:
            return "You're All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Your personal AI assistant for macOS. Let's get started!"
        case .features:
            return "Explore the powerful features of AI Companion."
        case .aiProviders:
            return "Choose from multiple AI providers or add your own."
        case .privacy:
            return "Learn about how we protect your data and privacy."
        case .complete:
            return "You're ready to start using AI Companion!"
        }
    }
}
