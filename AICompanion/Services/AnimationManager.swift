
//
//  AnimationManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI
import Combine

/// Manager for handling animations throughout the application
class AnimationManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = AnimationManager()
    
    /// Animation presets for common animations
    enum AnimationPreset {
        case messageAppear
        case messageDisappear
        case typingIndicator
        case buttonPress
        case viewTransition
        case slideIn
        case slideOut
        case fadeIn
        case fadeOut
        case bounce
        case pulse
        case shake
        
        /// Get the animation for this preset
        var animation: Animation {
            switch self {
            case .messageAppear:
                return .spring(response: 0.4, dampingFraction: 0.7)
            case .messageDisappear:
                return .easeOut(duration: 0.2)
            case .typingIndicator:
                return .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
            case .buttonPress:
                return .spring(response: 0.3, dampingFraction: 0.6)
            case .viewTransition:
                return .easeInOut(duration: 0.3)
            case .slideIn:
                return .spring(response: 0.5, dampingFraction: 0.8)
            case .slideOut:
                return .easeOut(duration: 0.3)
            case .fadeIn:
                return .easeIn(duration: 0.2)
            case .fadeOut:
                return .easeOut(duration: 0.2)
            case .bounce:
                return .spring(response: 0.4, dampingFraction: 0.6)
            case .pulse:
                return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            case .shake:
                return .spring(response: 0.2, dampingFraction: 0.5)
            }
        }
    }
    
    /// Animation durations for timing
    enum Duration {
        case veryShort
        case short
        case medium
        case long
        case veryLong
        
        /// Get the duration in seconds
        var seconds: Double {
            switch self {
            case .veryShort: return 0.1
            case .short: return 0.25
            case .medium: return 0.5
            case .long: return 0.8
            case .veryLong: return 1.5
            }
        }
    }
    
    /// Animation curves
    enum Curve {
        case linear
        case easeIn
        case easeOut
        case easeInOut
        case spring(response: Double, dampingFraction: Double)
        
        /// Get the animation for this curve
        var animation: Animation {
            switch self {
            case .linear:
                return .linear
            case .easeIn:
                return .easeIn
            case .easeOut:
                return .easeOut
            case .easeInOut:
                return .easeInOut
            case .spring(let response, let dampingFraction):
                return .spring(response: response, dampingFraction: dampingFraction)
            }
        }
    }
    
    /// User preferences for animations
    @Published var animationsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(animationsEnabled, forKey: "animationsEnabled")
        }
    }
    
    /// Animation speed multiplier (1.0 is normal speed)
    @Published var animationSpeed: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(animationSpeed, forKey: "animationSpeed")
        }
    }
    
    /// Whether to reduce motion for accessibility
    @Published var reduceMotion: Bool = false {
        didSet {
            UserDefaults.standard.set(reduceMotion, forKey: "reduceMotion")
        }
    }
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load user preferences
        animationsEnabled = UserDefaults.standard.bool(forKey: "animationsEnabled")
        animationSpeed = UserDefaults.standard.double(forKey: "animationSpeed")
        if animationSpeed == 0 {
            animationSpeed = 1.0 // Default value if not set
        }
        reduceMotion = UserDefaults.standard.bool(forKey: "reduceMotion")
        
        // Subscribe to accessibility notifications
        NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateAccessibilitySettings()
            }
            .store(in: &cancellables)
        
        // Initialize with system accessibility settings
        updateAccessibilitySettings()
    }
    
    /// Update settings based on system accessibility preferences
    private func updateAccessibilitySettings() {
        let reduceMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if reduceMotionEnabled != reduceMotion {
            reduceMotion = reduceMotionEnabled
        }
    }
    
    /// Get an animation based on preset, adjusted for user preferences
    func animation(for preset: AnimationPreset) -> Animation? {
        guard animationsEnabled else { return nil }
        
        if reduceMotion {
            // Use simplified animations when reduce motion is enabled
            switch preset {
            case .messageAppear, .fadeIn:
                return .easeIn(duration: 0.1 / animationSpeed)
            case .messageDisappear, .fadeOut:
                return .easeOut(duration: 0.1 / animationSpeed)
            case .viewTransition, .slideIn, .slideOut:
                return .easeInOut(duration: 0.2 / animationSpeed)
            case .typingIndicator, .pulse:
                return nil // No animation for repeating animations
            default:
                return .easeInOut(duration: 0.2 / animationSpeed)
            }
        } else {
            // Use full animations
            return preset.animation.speed(animationSpeed)
        }
    }
    
    /// Create a custom animation with the specified duration and curve
    func customAnimation(duration: Duration, curve: Curve) -> Animation? {
        guard animationsEnabled else { return nil }
        
        let adjustedDuration = duration.seconds / animationSpeed
        
        if reduceMotion {
            // Simplified animations for reduced motion
            return .easeInOut(duration: min(adjustedDuration, 0.2))
        } else {
            // Full animation with specified curve
            return curve.animation.speed(animationSpeed)
        }
    }
}

// MARK: - View Extensions for Animations

extension View {
    /// Apply a message appearance animation
    func messageAppearAnimation() -> some View {
        let animation = AnimationManager.shared.animation(for: .messageAppear)
        return animation != nil ? self.animation(animation) : self
    }
    
    /// Apply a slide-in animation from the specified edge
    func slideInAnimation(from edge: Edge) -> some View {
        let animation = AnimationManager.shared.animation(for: .slideIn)
        
        return self.modifier(SlideInModifier(edge: edge, animation: animation))
    }
    
    /// Apply a fade-in animation
    func fadeInAnimation() -> some View {
        let animation = AnimationManager.shared.animation(for: .fadeIn)
        
        return self.modifier(FadeInModifier(animation: animation))
    }
    
    /// Apply a bounce animation
    func bounceAnimation() -> some View {
        let animation = AnimationManager.shared.animation(for: .bounce)
        
        return self.modifier(BounceModifier(animation: animation))
    }
    
    /// Apply a pulse animation
    func pulseAnimation() -> some View {
        let animation = AnimationManager.shared.animation(for: .pulse)
        
        return self.modifier(PulseModifier(animation: animation))
    }
    
    /// Apply a shake animation
    func shakeAnimation(isShaking: Bool) -> some View {
        let animation = AnimationManager.shared.animation(for: .shake)
        
        return self.modifier(ShakeModifier(isShaking: isShaking, animation: animation))
    }
}

// MARK: - Animation Modifiers

/// Modifier for slide-in animation
struct SlideInModifier: ViewModifier {
    let edge: Edge
    let animation: Animation?
    @State private var isShown = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset.width, y: offset.height)
            .opacity(isShown ? 1 : 0)
            .onAppear {
                withAnimation(animation) {
                    isShown = true
                }
            }
    }
    
    private var offset: CGSize {
        if isShown {
            return .zero
        }
        
        switch edge {
        case .top:
            return CGSize(width: 0, height: -20)
        case .bottom:
            return CGSize(width: 0, height: 20)
        case .leading:
            return CGSize(width: -20, height: 0)
        case .trailing:
            return CGSize(width: 20, height: 0)
        }
    }
}

/// Modifier for fade-in animation
struct FadeInModifier: ViewModifier {
    let animation: Animation?
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(animation) {
                    opacity = 1
                }
            }
    }
}

/// Modifier for bounce animation
struct BounceModifier: ViewModifier {
    let animation: Animation?
    @State private var scale: CGFloat = 0.8
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(animation) {
                    scale = 1.0
                }
            }
    }
}

/// Modifier for pulse animation
struct PulseModifier: ViewModifier {
    let animation: Animation?
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                if let animation = animation {
                    withAnimation(animation) {
                        scale = 1.05
                    }
                }
            }
    }
}

/// Modifier for shake animation
struct ShakeModifier: ViewModifier {
    let isShaking: Bool
    let animation: Animation?
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: isShaking) { newValue in
                if newValue {
                    withAnimation(animation) {
                        offset = 5
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(animation) {
                            offset = -5
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(animation) {
                                offset = 3
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(animation) {
                                    offset = -3
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(animation) {
                                        offset = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }
}
