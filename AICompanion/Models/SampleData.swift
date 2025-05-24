//
//  SampleData.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI

/// Provides sample data for the application
struct SampleData {
    /// Get sample conversations
    static func getSampleConversations() -> [Conversation] {
        return [
            // Conversation 1: Introduction
            Conversation(
                id: UUID(uuidString: "A1B2C3D4-E5F6-47A8-B9C0-D1E2F3A4B5C6") ?? UUID(),
                title: "Introduction to AI",
                createdAt: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                updatedAt: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                messages: [
                    Message(
                        id: UUID(),
                        content: "Hello! Can you tell me about artificial intelligence?",
                        timestamp: Date().addingTimeInterval(-86400 * 3 - 300),
                        isFromUser: true
                    ),
                    Message(
                        id: UUID(),
                        content: "Artificial Intelligence (AI) refers to the simulation of human intelligence in machines that are programmed to think and learn like humans. The term can also be applied to any machine that exhibits traits associated with a human mind such as learning and problem-solving.\n\nAI can be categorized as either weak or strong. Weak AI, also known as narrow AI, is designed to perform a narrow task (e.g., facial recognition). Strong AI, also known as artificial general intelligence, is a theoretical form of AI where a machine would have an intelligence equal to humans, with the ability to learn any intellectual task that a human being can.\n\nSome common applications of AI include:\n\n- **Machine Learning**: A subset of AI that enables systems to learn and improve from experience without being explicitly programmed.\n- **Natural Language Processing**: Allows machines to understand and respond to human language.\n- **Computer Vision**: Enables machines to interpret and make decisions based on visual input.\n- **Robotics**: Combines AI with mechanical engineering to create robots that can perform tasks autonomously.\n\nIs there a specific aspect of AI you'd like to explore further?",
                        timestamp: Date().addingTimeInterval(-86400 * 3 - 240),
                        isFromUser: false,
                        aiProviderId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")
                    )
                ],
                aiProviderId: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()
            ),
            
            // Conversation 2: Programming Help
            Conversation(
                id: UUID(uuidString: "B2C3D4E5-F6A7-48B9-C0D1-E2F3A4B5C6D7") ?? UUID(),
                title: "Swift Programming Help",
                createdAt: Date().addingTimeInterval(-86400 * 1.5), // 1.5 days ago
                updatedAt: Date().addingTimeInterval(-86400 * 1.5), // 1.5 days ago
                messages: [
                    Message(
                        id: UUID(),
                        content: "I'm learning Swift. Can you explain how closures work?",
                        timestamp: Date().addingTimeInterval(-86400 * 1.5 - 600),
                        isFromUser: true
                    ),
                    Message(
                        id: UUID(),
                        content: "Closures in Swift are self-contained blocks of functionality that can be passed around and used in your code. They're similar to blocks in C and Objective-C, and to lambdas in other programming languages.\n\nHere's a basic syntax of a closure:\n\n```swift\n{ (parameters) -> return type in\n    statements\n}\n```\n\nFor example, a simple closure that adds two integers might look like this:\n\n```swift\nlet addClosure = { (a: Int, b: Int) -> Int in\n    return a + b\n}\n\n// Call the closure\nlet result = addClosure(5, 3) // result = 8\n```\n\nSwift's closures have several features that make them powerful:\n\n1. **Capturing Values**: Closures can capture and store references to variables and constants from the context in which they're defined.\n\n2. **Trailing Closure Syntax**: If a function's last parameter is a closure, you can use trailing closure syntax.\n\n3. **Shorthand Argument Names**: Swift automatically provides shorthand argument names like $0, $1, etc.\n\n4. **Implicit Returns**: Single-expression closures can implicitly return the result.\n\nHere's an example using these features with the `sorted(by:)` method:\n\n```swift\nlet names = [\"Chris\", \"Alex\", \"Barry\", \"Diana\"]\n\n// Full closure expression\nlet sortedNames1 = names.sorted(by: { (s1: String, s2: String) -> Bool in\n    return s1 < s2\n})\n\n// Inferring type from context\nlet sortedNames2 = names.sorted(by: { s1, s2 in return s1 < s2 })\n\n// Implicit return for single-expression closures\nlet sortedNames3 = names.sorted(by: { s1, s2 in s1 < s2 })\n\n// Shorthand argument names\nlet sortedNames4 = names.sorted(by: { $0 < $1 })\n\n// Operator methods\nlet sortedNames5 = names.sorted(by: <)\n\n// Trailing closure syntax\nlet sortedNames6 = names.sorted { $0 < $1 }\n```\n\nWould you like me to explain any specific aspect of closures in more detail?",
                        timestamp: Date().addingTimeInterval(-86400 * 1.5 - 540),
                        isFromUser: false,
                        aiProviderId: UUID(uuidString: "22222222-2222-2222-2222-222222222222")
                    ),
                    Message(
                        id: UUID(),
                        content: "That's really helpful! How do I use closures with higher-order functions like map and filter?",
                        timestamp: Date().addingTimeInterval(-86400 * 1.5 - 480),
                        isFromUser: true
                    ),
                    Message(
                        id: UUID(),
                        content: "Higher-order functions like `map`, `filter`, and `reduce` are perfect examples of where closures shine in Swift. These functions take closures as arguments and apply them to collections.\n\n### Using `map`\n\n`map` transforms each element in a collection using a closure and returns an array containing the transformed elements.\n\n```swift\nlet numbers = [1, 2, 3, 4, 5]\n\n// Double each number\nlet doubled = numbers.map { $0 * 2 }\n// doubled = [2, 4, 6, 8, 10]\n\n// Convert numbers to strings\nlet strings = numbers.map { String($0) }\n// strings = [\"1\", \"2\", \"3\", \"4\", \"5\"]\n```\n\n### Using `filter`\n\n`filter` returns an array containing only the elements that satisfy a condition in the closure.\n\n```swift\nlet numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\n\n// Get only even numbers\nlet evenNumbers = numbers.filter { $0 % 2 == 0 }\n// evenNumbers = [2, 4, 6, 8, 10]\n\n// Get numbers greater than 5\nlet largeNumbers = numbers.filter { $0 > 5 }\n// largeNumbers = [6, 7, 8, 9, 10]\n```\n\n### Using `reduce`\n\n`reduce` combines all elements in a collection using a closure and returns a single value.\n\n```swift\nlet numbers = [1, 2, 3, 4, 5]\n\n// Sum all numbers\nlet sum = numbers.reduce(0) { $0 + $1 }\n// sum = 15 (0 + 1 + 2 + 3 + 4 + 5)\n\n// Alternative syntax\nlet sum2 = numbers.reduce(0, +)\n// sum2 = 15\n\n// Concatenate strings\nlet words = [\"Swift\", \"is\", \"fun\"]\nlet sentence = words.reduce(\"\") { $0 + ($0.isEmpty ? \"\" : \" \") + $1 }\n// sentence = \"Swift is fun\"\n```\n\n### Chaining Higher-Order Functions\n\nYou can chain these functions together for more complex operations:\n\n```swift\nlet numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\n\n// Get the sum of squares of even numbers\nlet sumOfSquaresOfEvenNumbers = numbers\n    .filter { $0 % 2 == 0 }     // [2, 4, 6, 8, 10]\n    .map { $0 * $0 }            // [4, 16, 36, 64, 100]\n    .reduce(0, +)               // 220\n```\n\n### Using Closures with `compactMap` and `flatMap`\n\n`compactMap` is similar to `map`, but it removes nil values and unwraps optional values:\n\n```swift\nlet possibleNumbers = [\"1\", \"2\", \"three\", \"4\", \"5\"]\n\n// Convert strings to integers, removing any that can't be converted\nlet numbers = possibleNumbers.compactMap { Int($0) }\n// numbers = [1, 2, 4, 5]\n```\n\n`flatMap` is used to flatten nested collections:\n\n```swift\nlet nestedArrays = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]\n\n// Flatten the arrays and double each number\nlet flattenedAndDoubled = nestedArrays.flatMap { $0.map { $0 * 2 } }\n// flattenedAndDoubled = [2, 4, 6, 8, 10, 12, 14, 16, 18]\n```\n\nIs there a specific higher-order function you'd like to explore further?",
                        timestamp: Date().addingTimeInterval(-86400 * 1.5 - 420),
                        isFromUser: false,
                        aiProviderId: UUID(uuidString: "22222222-2222-2222-2222-222222222222")
                    )
                ],
                aiProviderId: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID()
            ),
            
            // Conversation 3: Recent Chat
            Conversation(
                id: UUID(uuidString: "C3D4E5F6-A7B8-49C0-D1E2-F3A4B5C6D7E8") ?? UUID(),
                title: "Project Ideas",
                createdAt: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
                updatedAt: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
                messages: [
                    Message(
                        id: UUID(),
                        content: "I'm looking for some interesting Swift project ideas to improve my skills. Any suggestions?",
                        timestamp: Date().addingTimeInterval(-3600 * 2 - 300),
                        isFromUser: true
                    ),
                    Message(
                        id: UUID(),
                        content: "Here are some interesting Swift project ideas to help you improve your skills:\n\n### Beginner Level Projects\n\n1. **To-Do List App**\n   - Features: Add, edit, delete tasks, set priorities, add due dates\n   - Skills: TableViews, UserDefaults for persistence, date handling\n\n2. **Weather App**\n   - Features: Show current weather and forecast based on location\n   - Skills: API integration, JSON parsing, CoreLocation\n\n3. **Calculator App**\n   - Features: Basic and scientific calculations\n   - Skills: UI design, math operations, responsive layout\n\n### Intermediate Level Projects\n\n4. **Recipe App**\n   - Features: Browse recipes, save favorites, add your own recipes\n   - Skills: Core Data, image handling, search functionality\n\n5. **Podcast Player**\n   - Features: Stream audio, subscribe to feeds, download episodes\n   - Skills: AVFoundation, background processing, RSS parsing\n\n6. **Fitness Tracker**\n   - Features: Track workouts, set goals, view progress\n   - Skills: HealthKit, charts/graphs, notifications\n\n### Advanced Level Projects\n\n7. **Social Media App**\n   - Features: User profiles, posts, comments, likes\n   - Skills: Firebase/backend integration, authentication, real-time updates\n\n8. **Augmented Reality Game**\n   - Features: AR objects, interactive gameplay\n   - Skills: ARKit, SceneKit, game mechanics\n\n9. **Video Editing App**\n   - Features: Trim videos, add filters, combine clips\n   - Skills: AVFoundation, Core Image, media processing\n\n10. **Language Learning App**\n    - Features: Flashcards, quizzes, pronunciation practice\n    - Skills: Speech recognition, animations, gamification\n\n### Project-Based Learning Approach\n\nFor any project you choose, I recommend this approach:\n\n1. **Start small**: Begin with core functionality\n2. **Iterate**: Add features incrementally\n3. **Refactor**: Improve code quality as you learn\n4. **Test**: Implement unit and UI tests\n5. **Share**: Put your code on GitHub for feedback\n\nWhich of these projects sounds most interesting to you?",
                        timestamp: Date().addingTimeInterval(-3600 * 2 - 240),
                        isFromUser: false,
                        aiProviderId: UUID(uuidString: "33333333-3333-3333-3333-333333333333")
                    ),
                    Message(
                        id: UUID(),
                        content: "I like the idea of a podcast player app. What frameworks would I need to learn for that?",
                        timestamp: Date().addingTimeInterval(-3600 * 2 - 180),
                        isFromUser: true
                    ),
                    Message(
                        id: UUID(),
                        content: "A podcast player app is an excellent choice! It's both practical and offers opportunities to learn several important iOS frameworks. Here's what you'll need to learn:\n\n### Core Frameworks\n\n1. **AVFoundation**\n   - This is the primary framework for working with audio-visual media\n   - You'll use it for playing audio streams and downloaded content\n   - Key classes: `AVPlayer`, `AVPlayerItem`, `AVAsset`\n\n2. **URLSession**\n   - For downloading podcast episodes and fetching RSS feeds\n   - Handling background downloads so users can download episodes even when the app isn't active\n   - Managing download tasks and tracking progress\n\n3. **Core Data**\n   - Store podcast subscriptions, episodes, and user preferences\n   - Track listening progress for each episode\n   - Manage downloaded content\n\n### Additional Frameworks\n\n4. **MediaPlayer**\n   - Integrate with the system's media controls (lock screen, control center)\n   - Display artwork and episode information\n   - Handle remote control events\n\n5. **UserNotifications**\n   - Notify users when new episodes are available\n   - Send reminders about partially played episodes\n\n6. **BackgroundTasks**\n   - Refresh podcast feeds in the background\n   - Complete downloads when the app isn't in the foreground\n\n7. **FeedKit** (third-party library)\n   - Parse RSS and Atom feeds (most podcasts use RSS)\n   - Extract episode metadata, descriptions, and media URLs\n\n### UI Components\n\n8. **UIKit** or **SwiftUI**\n   - Build the user interface (SwiftUI if targeting newer iOS versions)\n   - Create custom player controls and animations\n\n9. **Combine** (if using SwiftUI)\n   - Handle asynchronous events and data streams\n   - Update UI based on player state changes\n\n### Project Structure\n\nI recommend organizing your app into these modules:\n\n1. **Feed Parser**: Handles downloading and parsing podcast RSS feeds\n2. **Library Manager**: Manages subscriptions and episode metadata\n3. **Player Engine**: Controls audio playback and handles background audio\n4. **Download Manager**: Handles downloading and storing episodes\n5. **UI Layer**: Presents content and controls to the user\n\n### Learning Path\n\n1. Start by building a simple audio player that can play a single audio file\n2. Add the ability to parse a podcast RSS feed and display episodes\n3. Implement basic playback controls and progress tracking\n4. Add persistence with Core Data\n5. Implement background playback and lock screen controls\n6. Add download functionality\n7. Refine the UI and add more advanced features\n\nWould you like me to provide some sample code for any specific part of this project?",
                        timestamp: Date().addingTimeInterval(-3600 * 2 - 120),
                        isFromUser: false,
                        aiProviderId: UUID(uuidString: "33333333-3333-3333-3333-333333333333")
                    )
                ],
                aiProviderId: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID()
            )
        ]
    }
    
    /// Get sample AI providers
    static func getSampleAIProviders() -> [AIProvider] {
        return [
            AIProvider(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                name: "OpenAI",
                description: "Powerful language models for natural conversation",
                apiBaseURL: URL(string: "https://api.openai.com/v1")!,
                requiresAPIKey: true,
                availableModels: [
                    AIModel(
                        id: UUID(),
                        modelId: "gpt-4",
                        displayName: "GPT-4",
                        description: "Most capable model, best for complex tasks",
                        maxContextLength: 8192,
                        supportsStreaming: true,
                        costPerInputToken: 0.03,
                        costPerOutputToken: 0.06
                    ),
                    AIModel(
                        id: UUID(),
                        modelId: "gpt-3.5-turbo",
                        displayName: "GPT-3.5 Turbo",
                        description: "Fast and efficient for most everyday tasks",
                        maxContextLength: 4096,
                        supportsStreaming: true,
                        costPerInputToken: 0.0015,
                        costPerOutputToken: 0.002
                    )
                ],
                maxContextLength: 8192,
                isEnabled: true
            ),
            
            AIProvider(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
                name: "Anthropic",
                description: "Helpful, harmless, and honest AI assistant",
                apiBaseURL: URL(string: "https://api.anthropic.com/v1")!,
                requiresAPIKey: true,
                availableModels: [
                    AIModel(
                        id: UUID(),
                        modelId: "claude-3-opus",
                        displayName: "Claude 3 Opus",
                        description: "Most powerful model for complex reasoning",
                        maxContextLength: 100000,
                        supportsStreaming: true,
                        costPerInputToken: 0.015,
                        costPerOutputToken: 0.075
                    ),
                    AIModel(
                        id: UUID(),
                        modelId: "claude-3-sonnet",
                        displayName: "Claude 3 Sonnet",
                        description: "Balanced performance and efficiency",
                        maxContextLength: 100000,
                        supportsStreaming: true,
                        costPerInputToken: 0.003,
                        costPerOutputToken: 0.015
                    ),
                    AIModel(
                        id: UUID(),
                        modelId: "claude-3-haiku",
                        displayName: "Claude 3 Haiku",
                        description: "Fast and cost-effective for simple tasks",
                        maxContextLength: 100000,
                        supportsStreaming: true,
                        costPerInputToken: 0.00025,
                        costPerOutputToken: 0.00125
                    )
                ],
                maxContextLength: 100000,
                isEnabled: true
            ),
            
            AIProvider(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
                name: "Local Model",
                description: "Run AI models locally on your Mac",
                apiBaseURL: URL(string: "http://localhost:8080")!,
                requiresAPIKey: false,
                availableModels: [
                    AIModel(
                        id: UUID(),
                        modelId: "llama-3-8b",
                        displayName: "Llama 3 (8B)",
                        description: "Efficient open-source model for local use",
                        maxContextLength: 4096,
                        supportsStreaming: true,
                        costPerInputToken: 0.0,
                        costPerOutputToken: 0.0
                    ),
                    AIModel(
                        id: UUID(),
                        modelId: "mistral-7b",
                        displayName: "Mistral (7B)",
                        description: "Compact but powerful local model",
                        maxContextLength: 8192,
                        supportsStreaming: true,
                        costPerInputToken: 0.0,
                        costPerOutputToken: 0.0
                    )
                ],
                maxContextLength: 8192,
                isEnabled: true
            ),
            
            AIProvider(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
                name: "Google AI",
                description: "Advanced AI models from Google",
                apiBaseURL: URL(string: "https://generativelanguage.googleapis.com/v1")!,
                requiresAPIKey: true,
                availableModels: [
                    AIModel(
                        id: UUID(),
                        modelId: "gemini-pro",
                        displayName: "Gemini Pro",
                        description: "Google's most capable text model",
                        maxContextLength: 32768,
                        supportsStreaming: true,
                        costPerInputToken: 0.0025,
                        costPerOutputToken: 0.0025
                    ),
                    AIModel(
                        id: UUID(),
                        modelId: "gemini-ultra",
                        displayName: "Gemini Ultra",
                        description: "Most advanced model for complex tasks",
                        maxContextLength: 32768,
                        supportsStreaming: true,
                        costPerInputToken: 0.01,
                        costPerOutputToken: 0.03
                    )
                ],
                maxContextLength: 32768,
                isEnabled: false
            )
        ]
    }
}
