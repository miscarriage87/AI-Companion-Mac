
//
//  FeedbackManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import AppKit
import SwiftUI
import Combine

/// Manager for handling haptic feedback and sound effects
class FeedbackManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = FeedbackManager()
    
    /// Haptic feedback patterns
    enum HapticPattern {
        case success
        case warning
        case error
        case selection
        case light
        case medium
        case heavy
        case generic
        case alignment
        
        /// Get the NSHapticFeedbackManager pattern for this type
        var pattern: NSHapticFeedbackManager.FeedbackPattern {
            switch self {
            case .success:
                return .levelChange
            case .warning:
                return .alignment
            case .error:
                return .alignment
            case .selection:
                return .generic
            case .light:
                return .generic
            case .medium:
                return .generic
            case .heavy:
                return .generic
            case .generic:
                return .generic
            case .alignment:
                return .alignment
            }
        }
    }
    
    /// Sound effect types
    enum SoundEffect: String {
        case messageSent = "message-sent"
        case messageReceived = "message-received"
        case error = "error"
        case success = "success"
        case notification = "notification"
        case click = "click"
        case toggle = "toggle"
        
        /// Get the sound file name for this effect
        var fileName: String {
            return rawValue
        }
    }
    
    /// Whether haptic feedback is enabled
    @Published var hapticFeedbackEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        }
    }
    
    /// Whether sound effects are enabled
    @Published var soundEffectsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
        }
    }
    
    /// Sound effect volume (0.0 to 1.0)
    @Published var soundVolume: Float = 0.5 {
        didSet {
            UserDefaults.standard.set(soundVolume, forKey: "soundVolume")
        }
    }
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Sound players for each sound effect
    private var soundPlayers: [SoundEffect: NSSound] = [:]
    
    private init() {
        // Load user preferences
        hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        soundEffectsEnabled = UserDefaults.standard.bool(forKey: "soundEffectsEnabled")
        
        let storedVolume = UserDefaults.standard.float(forKey: "soundVolume")
        soundVolume = storedVolume > 0 ? storedVolume : 0.5
        
        // Preload sound effects
        preloadSoundEffects()
    }
    
    /// Preload sound effects for better performance
    private func preloadSoundEffects() {
        for effect in SoundEffect.allCases {
            if let sound = NSSound(named: effect.fileName) {
                sound.volume = soundVolume
                soundPlayers[effect] = sound
            } else if let soundURL = Bundle.main.url(forResource: effect.fileName, withExtension: "wav") {
                if let sound = NSSound(contentsOf: soundURL, byReference: true) {
                    sound.volume = soundVolume
                    soundPlayers[effect] = sound
                }
            }
        }
    }
    
    /// Perform haptic feedback with the specified pattern
    func performHapticFeedback(_ pattern: HapticPattern) {
        guard hapticFeedbackEnabled else { return }
        
        // Check if the device supports haptic feedback
        if NSHapticFeedbackManager.defaultPerformer.performanceTime != .default {
            NSHapticFeedbackManager.defaultPerformer.perform(pattern.pattern, performanceTime: .now)
        }
    }
    
    /// Play a sound effect
    func playSound(_ effect: SoundEffect) {
        guard soundEffectsEnabled else { return }
        
        if let sound = soundPlayers[effect] {
            sound.volume = soundVolume
            sound.play()
        } else {
            // Try to load the sound if it wasn't preloaded
            if let sound = NSSound(named: effect.fileName) {
                sound.volume = soundVolume
                soundPlayers[effect] = sound
                sound.play()
            }
        }
    }
    
    /// Update the volume for all sound effects
    func updateSoundVolume() {
        for (_, sound) in soundPlayers {
            sound.volume = soundVolume
        }
    }
}

// MARK: - SoundEffect Extension
extension FeedbackManager.SoundEffect: CaseIterable {}

// MARK: - View Extensions for Feedback

extension View {
    /// Add haptic feedback to a button or interactive element
    func withHapticFeedback(_ pattern: FeedbackManager.HapticPattern) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            FeedbackManager.shared.performHapticFeedback(pattern)
        })
    }
    
    /// Add sound effect to a button or interactive element
    func withSoundEffect(_ effect: FeedbackManager.SoundEffect) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            FeedbackManager.shared.playSound(effect)
        })
    }
    
    /// Add both haptic feedback and sound effect to a button or interactive element
    func withFeedback(haptic: FeedbackManager.HapticPattern, sound: FeedbackManager.SoundEffect) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            FeedbackManager.shared.performHapticFeedback(haptic)
            FeedbackManager.shared.playSound(sound)
        })
    }
}
