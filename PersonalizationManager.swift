
//
//  PersonalizationManager.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine
import CoreML

/// PersonalizationManager customizes AI responses based on user preferences and behavior
/// It adapts the companion's communication style, content, and suggestions to match user needs
class PersonalizationManager {
    // MARK: - Properties
    
    private let userPreferencesManager: UserPreferencesManager
    private let userBehaviorAnalyzer: UserBehaviorAnalyzer
    private var cancellables = Set<AnyCancellable>()
    
    // Personalization model
    private var personalizationModel: MLModel?
    
    // Response templates
    private var responseTemplates: [ResponseTemplate] = []
    
    // MARK: - Initialization
    
    init(userPreferencesManager: UserPreferencesManager, userBehaviorAnalyzer: UserBehaviorAnalyzer) {
        self.userPreferencesManager = userPreferencesManager
        self.userBehaviorAnalyzer = userBehaviorAnalyzer
        loadPersonalizationModel()
        loadResponseTemplates()
    }
    
    // MARK: - Setup
    
    private func loadPersonalizationModel() {
        // In a real implementation, this would load a CoreML model
        // For now, we'll use rule-based personalization
        print("Personalization model initialized")
    }
    
    private func loadResponseTemplates() {
        // Load response templates for different styles and contexts
        responseTemplates = [
            // Concise style templates
            ResponseTemplate(
                style: .concise,
                context: .factualQuestion,
                template: "{answer}"
            ),
            ResponseTemplate(
                style: .concise,
                context: .taskCompletion,
                template: "Done. {result}"
            ),
            
            // Detailed style templates
            ResponseTemplate(
                style: .detailed,
                context: .factualQuestion,
                template: "Here's what I found about {topic}:\n\n{answer}\n\nWould you like more information on any specific aspect?"
            ),
            ResponseTemplate(
                style: .detailed,
                context: .taskCompletion,
                template: "I've completed the task. Here are the details:\n\n{result}\n\nIs there anything else you'd like me to explain or modify?"
            ),
            
            // Conversational style templates
            ResponseTemplate(
                style: .conversational,
                context: .factualQuestion,
                template: "I think you'll find this interesting! {answer} Does that help with what you wanted to know?"
            ),
            ResponseTemplate(
                style: .conversational,
                context: .taskCompletion,
                template: "Great news! I've finished that for you. {result} How does that look?"
            ),
            
            // Technical style templates
            ResponseTemplate(
                style: .technical,
                context: .factualQuestion,
                template: "Analysis complete. Results: {answer}\nMethodology: {methodology}\nConfidence: {confidence}%"
            ),
            ResponseTemplate(
                style: .technical,
                context: .taskCompletion,
                template: "Task execution complete.\nInput parameters: {parameters}\nOutput: {result}\nExecution time: {executionTime}ms"
            )
        ]
    }
    
    // MARK: - Response Personalization
    
    /// Personalize a response based on user preferences and context
    /// - Parameters:
    ///   - content: The raw content to personalize
    ///   - context: The context of the response
    ///   - metadata: Additional metadata for personalization
    /// - Returns: Personalized response
    func personalizeResponse(content: String, context: ResponseContext, metadata: [String: Any] = [:]) -> String {
        // Get user's preferred response style
        let preferredStyle = determinePreferredStyle(for: context)
        
        // Find appropriate template
        let template = findBestTemplate(style: preferredStyle, context: context)
        
        // Apply template with content and metadata
        var personalizedResponse = applyTemplate(template, content: content, metadata: metadata)
        
        // Add personalized greeting if appropriate
        if context == .greeting {
            personalizedResponse = addPersonalizedGreeting() + personalizedResponse
        }
        
        // Add personalized suggestions if appropriate
        if shouldAddSuggestions(for: context) {
            personalizedResponse += addPersonalizedSuggestions(for: context)
        }
        
        return personalizedResponse
    }
    
    /// Determine the preferred response style for the current context
    /// - Parameter context: The response context
    /// - Returns: Preferred response style
    private func determinePreferredStyle(for context: ResponseContext) -> ResponseStyle {
        // Check if user has explicitly set a preference
        if let explicitStyle = userPreferencesManager.getPreferredResponseStyle() {
            return explicitStyle
        }
        
        // Otherwise, predict based on behavior
        return userBehaviorAnalyzer.predictPreferredResponseStyle()
    }
    
    /// Find the best template for the given style and context
    /// - Parameters:
    ///   - style: Response style
    ///   - context: Response context
    /// - Returns: Best matching template
    private func findBestTemplate(style: ResponseStyle, context: ResponseContext) -> ResponseTemplate {
        // Try to find exact match
        if let exactMatch = responseTemplates.first(where: { $0.style == style && $0.context == context }) {
            return exactMatch
        }
        
        // Try to find style match with generic context
        if let styleMatch = responseTemplates.first(where: { $0.style == style }) {
            return styleMatch
        }
        
        // Default to conversational style
        return ResponseTemplate(
            style: .conversational,
            context: .generic,
            template: "{answer}"
        )
    }
    
    /// Apply template with content and metadata
    /// - Parameters:
    ///   - template: The template to apply
    ///   - content: The main content
    ///   - metadata: Additional metadata
    /// - Returns: Formatted response
    private func applyTemplate(_ template: ResponseTemplate, content: String, metadata: [String: Any]) -> String {
        var result = template.template
        
        // Replace {answer} or {result} with content
        result = result.replacingOccurrences(of: "{answer}", with: content)
        result = result.replacingOccurrences(of: "{result}", with: content)
        
        // Replace other placeholders with metadata
        for (key, value) in metadata {
            result = result.replacingOccurrences(of: "{\(key)}", with: "\(value)")
        }
        
        return result
    }
    
    /// Add a personalized greeting based on user preferences and time of day
    /// - Returns: Personalized greeting
    private func addPersonalizedGreeting() -> String {
        let userName = userPreferencesManager.getUserName() ?? ""
        let hour = Calendar.current.component(.hour, from: Date())
        
        var greeting = ""
        
        // Time-based greeting
        if hour >= 5 && hour < 12 {
            greeting = "Good morning"
        } else if hour >= 12 && hour < 18 {
            greeting = "Good afternoon"
        } else {
            greeting = "Good evening"
        }
        
        // Add user name if available
        if !userName.isEmpty {
            greeting += ", \(userName)"
        }
        
        return greeting + "! "
    }
    
    /// Determine if suggestions should be added to the response
    /// - Parameter context: The response context
    /// - Returns: Whether to add suggestions
    private func shouldAddSuggestions(for context: ResponseContext) -> Bool {
        // Add suggestions for certain contexts
        return [.factualQuestion, .taskCompletion, .greeting].contains(context)
    }
    
    /// Add personalized suggestions based on user behavior and context
    /// - Parameter context: The response context
    /// - Returns: Suggestion text
    private func addPersonalizedSuggestions(for context: ResponseContext) -> String {
        // Get top features from user behavior
        let topFeatures = userPreferencesManager.getTopFeatures()
        
        // Generate suggestions based on context and top features
        var suggestions: [String] = []
        
        switch context {
        case .factualQuestion:
            if topFeatures.contains("calendar") {
                suggestions.append("Would you like me to add this to your calendar?")
            }
            if topFeatures.contains("notes") {
                suggestions.append("I can save this information to your notes if you'd like.")
            }
            
        case .taskCompletion:
            if topFeatures.contains("reminder") {
                suggestions.append("Would you like me to set a reminder for follow-up?")
            }
            
        case .greeting:
            // Suggest based on time of day and user patterns
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 9 && hour < 11 {
                suggestions.append("Would you like to see your morning summary?")
            } else if hour >= 17 && hour < 19 {
                suggestions.append("Would you like to review your day or plan for tomorrow?")
            }
            
            // Suggest based on predicted next action
            if let predictedAction = userBehaviorAnalyzer.predictNextAction(currentFeature: "greeting") {
                if predictedAction.confidence > 0.7 {
                    suggestions.append("Would you like to \(actionToSuggestion(predictedAction.feature))?")
                }
            }
            
        default:
            break
        }
        
        if suggestions.isEmpty {
            return ""
        }
        
        // Return formatted suggestions
        return "\n\n" + suggestions.joined(separator: "\n")
    }
    
    /// Convert an action name to a user-friendly suggestion
    /// - Parameter action: The action name
    /// - Returns: User-friendly suggestion
    private func actionToSuggestion(_ action: String) -> String {
        switch action {
        case "calendar":
            return "check your calendar"
        case "weather":
            return "see the weather forecast"
        case "news":
            return "catch up on the latest news"
        case "email":
            return "check your emails"
        case "tasks":
            return "review your tasks"
        default:
            return "use \(action)"
        }
    }
    
    // MARK: - UI Personalization
    
    /// Get personalized UI settings based on user preferences and behavior
    /// - Returns: Dictionary of UI settings
    func getPersonalizedUISettings() -> [String: Any] {
        var settings: [String: Any] = [:]
        
        // Color scheme preference
        settings["colorScheme"] = userPreferencesManager.getPreferredColorScheme() ?? "system"
        
        // Font size preference
        settings["fontSize"] = userPreferencesManager.getPreferredFontSize() ?? "medium"
        
        // Layout preference
        settings["layout"] = userPreferencesManager.getPreferredLayout() ?? "standard"
        
        // Feature visibility based on usage
        let topFeatures = userPreferencesManager.getTopFeatures()
        settings["featuredItems"] = topFeatures
        
        // Time-based adaptations
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 20 || hour < 6 {
            // Night mode settings
            settings["reduceBrightness"] = true
            settings["useWarmColors"] = true
        } else {
            settings["reduceBrightness"] = false
            settings["useWarmColors"] = false
        }
        
        return settings
    }
    
    /// Get personalized dashboard items based on user behavior
    /// - Returns: Array of dashboard items
    func getPersonalizedDashboardItems() -> [DashboardItem] {
        var items: [DashboardItem] = []
        
        // Add items based on top features
        let topFeatures = userPreferencesManager.getTopFeatures()
        
        if topFeatures.contains("calendar") {
            items.append(DashboardItem(
                id: "calendar",
                title: "Calendar",
                priority: topFeatures.firstIndex(of: "calendar") ?? 999
            ))
        }
        
        if topFeatures.contains("tasks") {
            items.append(DashboardItem(
                id: "tasks",
                title: "Tasks",
                priority: topFeatures.firstIndex(of: "tasks") ?? 999
            ))
        }
        
        if topFeatures.contains("weather") {
            items.append(DashboardItem(
                id: "weather",
                title: "Weather",
                priority: topFeatures.firstIndex(of: "weather") ?? 999
            ))
        }
        
        if topFeatures.contains("news") {
            items.append(DashboardItem(
                id: "news",
                title: "News",
                priority: topFeatures.firstIndex(of: "news") ?? 999
            ))
        }
        
        // Add time-relevant items
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        
        if hour >= 7 && hour < 10 {
            // Morning items
            items.append(DashboardItem(
                id: "morningBriefing",
                title: "Morning Briefing",
                priority: 0
            ))
        } else if hour >= 17 && hour < 20 {
            // Evening items
            items.append(DashboardItem(
                id: "eveningSummary",
                title: "Evening Summary",
                priority: 0
            ))
        }
        
        // Weekend vs. weekday items
        if weekday == 1 || weekday == 7 {
            // Weekend items
            items.append(DashboardItem(
                id: "leisure",
                title: "Leisure Suggestions",
                priority: 5
            ))
        } else {
            // Weekday items
            items.append(DashboardItem(
                id: "productivity",
                title: "Productivity Tips",
                priority: 5
            ))
        }
        
        // Sort by priority
        return items.sorted { $0.priority < $1.priority }
    }
    
    // MARK: - Model Fine-tuning
    
    /// Fine-tune the personalization model based on user feedback
    /// - Parameter feedback: User feedback on personalization
    func learnFromFeedback(_ feedback: PersonalizationFeedback) {
        // In a real implementation, this would update the CoreML model
        // For now, we'll update preferences based on feedback
        
        // Update style preference if feedback includes style rating
        if let styleRating = feedback.styleRating, styleRating > 3 {
            userPreferencesManager.setPreferredResponseStyle(feedback.style)
        }
        
        // Update UI preferences if feedback includes UI rating
        if let uiRating = feedback.uiRating, uiRating > 3 {
            if let colorScheme = feedback.colorScheme {
                userPreferencesManager.setPreferredColorScheme(colorScheme)
            }
            
            if let fontSize = feedback.fontSize {
                userPreferencesManager.setPreferredFontSize(fontSize)
            }
            
            if let layout = feedback.layout {
                userPreferencesManager.setPreferredLayout(layout)
            }
        }
        
        // Log feedback for future analysis
        print("Personalization feedback received: \(feedback)")
    }
}

// MARK: - Supporting Types

/// Response context types
enum ResponseContext {
    case greeting
    case factualQuestion
    case taskCompletion
    case error
    case suggestion
    case generic
}

/// Template for response formatting
struct ResponseTemplate {
    let style: ResponseStyle
    let context: ResponseContext
    let template: String
}

/// Dashboard item for personalized UI
struct DashboardItem {
    let id: String
    let title: String
    let priority: Int
}

/// Feedback on personalization
struct PersonalizationFeedback {
    let style: ResponseStyle
    let styleRating: Int?
    let uiRating: Int?
    let colorScheme: String?
    let fontSize: String?
    let layout: String?
    let comments: String?
}
