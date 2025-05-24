
//
//  OnboardingFeatureView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// Enhanced onboarding feature view with animations
struct OnboardingFeatureView: View {
    @EnvironmentObject private var animationManager: AnimationManager
    
    var body: some View {
        VStack(spacing: 30) {
            FeatureRowAnimated(
                icon: "message.fill",
                title: "Chat with AI".localized,
                description: "Have natural conversations with advanced AI models".localized,
                delay: 0.1
            )
            
            FeatureRowAnimated(
                icon: "mic.fill",
                title: "Voice Interaction".localized,
                description: "Speak to your AI companion and hear responses".localized,
                delay: 0.3
            )
            
            FeatureRowAnimated(
                icon: "doc.fill",
                title: "Document Processing".localized,
                description: "Analyze and extract information from documents".localized,
                delay: 0.5
            )
            
            FeatureRowAnimated(
                icon: "puzzlepiece.fill",
                title: "Plugins & Extensions".localized,
                description: "Extend functionality with custom plugins".localized,
                delay: 0.7
            )
            
            FeatureRowAnimated(
                icon: "hand.raised.fill",
                title: "Privacy Controls".localized,
                description: "You control what data is shared and stored".localized,
                delay: 0.9
            )
        }
        .padding(.horizontal, 40)
    }
}

/// Animated feature row for onboarding
struct FeatureRowAnimated: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    @State private var isVisible = false
    @EnvironmentObject private var animationManager: AnimationManager
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
            }
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .opacity(isVisible ? 1.0 : 0.0)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .offset(x: isVisible ? 0 : 20)
            .opacity(isVisible ? 1.0 : 0.0)
            
            Spacer()
        }
        .onAppear {
            let animation = animationManager.animation(for: .slideIn)
            
            withAnimation(animation?.delay(delay)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

/// Enhanced onboarding welcome view with animations
struct OnboardingWelcomeView: View {
    @State private var isVisible = false
    @EnvironmentObject private var animationManager: AnimationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .scaleEffect(isVisible ? 1.0 : 0.1)
                .opacity(isVisible ? 1.0 : 0.0)
            
            Text("Welcome to AI Companion".localized)
                .font(.title)
                .fontWeight(.bold)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 20)
            
            Text("Your personal AI assistant for macOS".localized)
                .font(.headline)
                .foregroundColor(.secondary)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 10)
            
            Text("AI Companion helps you with tasks, answers questions, and assists with your work using advanced AI technology.".localized)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.top, 20)
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            let animation = animationManager.animation(for: .fadeIn)
            
            withAnimation(animation) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to AI Companion. Your personal AI assistant for macOS. AI Companion helps you with tasks, answers questions, and assists with your work using advanced AI technology.")
    }
}

/// Enhanced onboarding complete view with animations
struct OnboardingCompleteView: View {
    @State private var isVisible = false
    @State private var pulseScale = 1.0
    @EnvironmentObject private var animationManager: AnimationManager
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(isVisible ? 1.0 : 0.1)
                    .opacity(isVisible ? 1.0 : 0.0)
            }
            
            Text("You're All Set!".localized)
                .font(.title)
                .fontWeight(.bold)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 20)
            
            Text("You're ready to start using AI Companion".localized)
                .font(.headline)
                .foregroundColor(.secondary)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 10)
            
            Text("Click 'Get Started' to begin your AI journey. You can access settings and help at any time from the menu bar.".localized)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.top, 20)
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            let fadeAnimation = animationManager.animation(for: .fadeIn)
            let pulseAnimation = animationManager.animation(for: .pulse)
            
            withAnimation(fadeAnimation) {
                isVisible = true
            }
            
            withAnimation(pulseAnimation) {
                pulseScale = 1.1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You're All Set! You're ready to start using AI Companion. Click 'Get Started' to begin your AI journey. You can access settings and help at any time from the menu bar.")
    }
}

// Preview for SwiftUI canvas
struct OnboardingFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFeatureView()
            .environmentObject(AnimationManager.shared)
    }
}
