
//
//  OnboardingView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// Onboarding view for new users
struct OnboardingView: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    
    var body: some View {
        VStack {
            // Header
            Text(onboardingManager.currentStep.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text(onboardingManager.currentStep.description)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            
            // Content
            Spacer()
            
            switch onboardingManager.currentStep {
            case .welcome:
                WelcomeStepView()
            case .features:
                FeaturesStepView()
            case .aiProviders:
                AIProvidersStepView()
            case .privacy:
                PrivacyStepView()
            case .complete:
                CompleteStepView()
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if onboardingManager.currentStep != .welcome {
                    Button("Back") {
                        withAnimation {
                            onboardingManager.previousStep()
                        }
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }
                
                Spacer()
                
                Button(onboardingManager.currentStep == .complete ? "Get Started" : "Next") {
                    withAnimation {
                        onboardingManager.nextStep()
                    }
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 800, height: 600)
    }
}

/// Welcome step view
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Welcome to AI Companion")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your personal AI assistant for macOS")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("AI Companion helps you with tasks, answers questions, and assists with your work using advanced AI technology.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.top, 20)
        }
    }
}

/// Features step view
struct FeaturesStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            FeatureRow(icon: "message.fill", title: "Chat with AI", description: "Have natural conversations with advanced AI models")
            FeatureRow(icon: "mic.fill", title: "Voice Interaction", description: "Speak to your AI companion and hear responses")
            FeatureRow(icon: "doc.fill", title: "Document Processing", description: "Analyze and extract information from documents")
            FeatureRow(icon: "puzzlepiece.fill", title: "Plugins & Extensions", description: "Extend functionality with custom plugins")
        }
        .padding(.horizontal, 40)
    }
}

/// Feature row view
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.accentColor)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

/// AI providers step view
struct AIProvidersStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your AI Provider")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("AI Companion works with multiple AI providers. You can choose which one to use or switch between them at any time.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            
            VStack(spacing: 16) {
                ProviderRow(name: "OpenAI", description: "Powered by GPT models", isSelected: true)
                ProviderRow(name: "Anthropic", description: "Powered by Claude models", isSelected: false)
                ProviderRow(name: "Local Models", description: "Run AI locally on your Mac", isSelected: false)
                ProviderRow(name: "Custom Provider", description: "Connect to your own AI service", isSelected: false)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 40)
    }
}

/// Provider row view
struct ProviderRow: View {
    let name: String
    let description: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

/// Privacy step view
struct PrivacyStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Privacy & Security")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("AI Companion is designed with your privacy in mind. Here's how we protect your data:")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            
            VStack(alignment: .leading, spacing: 16) {
                PrivacyPoint(icon: "lock.fill", text: "Your conversations are encrypted")
                PrivacyPoint(icon: "icloud.slash", text: "Local processing options available")
                PrivacyPoint(icon: "hand.raised.fill", text: "You control what data is shared")
                PrivacyPoint(icon: "trash.fill", text: "Delete your data at any time")
            }
            .padding(.top, 20)
        }
    }
}

/// Privacy point view
struct PrivacyPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

/// Complete step view
struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You're ready to start using AI Companion")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Click 'Get Started' to begin your AI journey. You can access settings and help at any time from the menu bar.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.top, 20)
        }
    }
}
