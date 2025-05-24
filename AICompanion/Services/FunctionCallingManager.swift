//
//  FunctionCallingManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import SwiftUI

/// Manager for handling AI function calling capabilities
class FunctionCallingManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = FunctionCallingManager()
    
    /// Available functions that can be called by the AI
    @Published private(set) var availableFunctions: [AIFunction] = []
    
    /// AI service for interacting with AI providers
    private let aiService: AIService
    
    /// Storage service for persisting function data
    private let storageService: StorageService
    
    /// Background task manager for function operations
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(aiService: AIService = AIService(), storageService: StorageService = StorageService()) {
        self.aiService = aiService
        self.storageService = storageService
        
        // Register default functions
        registerDefaultFunctions()
    }
    
    /// Register default functions available to the AI
    private func registerDefaultFunctions() {
        // System functions
        registerSystemFunctions()
        
        // Utility functions
        registerUtilityFunctions()
        
        // User interface functions
        registerUIFunctions()
    }
    
    /// Register system functions
    private func registerSystemFunctions() {
        // Get current date and time
        let getCurrentDateTime = AIFunction(
            name: "get_current_date_time",
            description: "Get the current date and time",
            parameters: [],
            execute: { _ in
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .full
                dateFormatter.timeStyle = .full
                return ["date_time": dateFormatter.string(from: Date())]
            }
        )
        
        // Get system information
        let getSystemInfo = AIFunction(
            name: "get_system_info",
            description: "Get information about the system",
            parameters: [],
            execute: { _ in
                let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
                let processorCount = ProcessInfo.processInfo.processorCount
                let physicalMemory = ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024) // Convert to GB
                
                return [
                    "os_version": osVersion,
                    "processor_count": processorCount,
                    "physical_memory_gb": physicalMemory
                ]
            }
        )
        
        // Register system functions
        availableFunctions.append(getCurrentDateTime)
        availableFunctions.append(getSystemInfo)
    }
    
    /// Register utility functions
    private func registerUtilityFunctions() {
        // Generate random number
        let generateRandomNumber = AIFunction(
            name: "generate_random_number",
            description: "Generate a random number within a specified range",
            parameters: [
                AIFunctionParameter(
                    name: "min",
                    description: "Minimum value (inclusive)",
                    type: .number,
                    required: true
                ),
                AIFunctionParameter(
                    name: "max",
                    description: "Maximum value (inclusive)",
                    type: .number,
                    required: true
                )
            ],
            execute: { parameters in
                guard let min = parameters["min"] as? Double,
                      let max = parameters["max"] as? Double else {
                    throw FunctionError.invalidParameters("Min and max parameters are required")
                }
                
                let randomValue = Double.random(in: min...max)
                return ["random_value": randomValue]
            }
        )
        
        // Format text
        let formatText = AIFunction(
            name: "format_text",
            description: "Format text according to specified options",
            parameters: [
                AIFunctionParameter(
                    name: "text",
                    description: "Text to format",
                    type: .string,
                    required: true
                ),
                AIFunctionParameter(
                    name: "format",
                    description: "Format to apply",
                    type: .string,
                    required: true,
                    enumValues: ["uppercase", "lowercase", "titlecase", "trim"]
                )
            ],
            execute: { parameters in
                guard let text = parameters["text"] as? String,
                      let format = parameters["format"] as? String else {
                    throw FunctionError.invalidParameters("Text and format parameters are required")
                }
                
                var formattedText: String
                
                switch format {
                case "uppercase":
                    formattedText = text.uppercased()
                case "lowercase":
                    formattedText = text.lowercased()
                case "titlecase":
                    formattedText = text.capitalized
                case "trim":
                    formattedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                default:
                    throw FunctionError.invalidParameters("Invalid format: \(format)")
                }
                
                return ["formatted_text": formattedText]
            }
        )
        
        // Register utility functions
        availableFunctions.append(generateRandomNumber)
        availableFunctions.append(formatText)
    }
    
    /// Register user interface functions
    private func registerUIFunctions() {
        // Show notification
        let showNotification = AIFunction(
            name: "show_notification",
            description: "Show a notification to the user",
            parameters: [
                AIFunctionParameter(
                    name: "title",
                    description: "Title of the notification",
                    type: .string,
                    required: true
                ),
                AIFunctionParameter(
                    name: "message",
                    description: "Message to display in the notification",
                    type: .string,
                    required: true
                ),
                AIFunctionParameter(
                    name: "type",
                    description: "Type of notification",
                    type: .string,
                    required: false,
                    enumValues: ["info", "warning", "error"]
                )
            ],
            execute: { parameters in
                guard let title = parameters["title"] as? String,
                      let message = parameters["message"] as? String else {
                    throw FunctionError.invalidParameters("Title and message parameters are required")
                }
                
                let type = parameters["type"] as? String ?? "info"
                
                // In a real implementation, this would show a notification
                // For this example, we'll just log it
                print("Notification (\(type)): \(title) - \(message)")
                
                return ["success": true]
            }
        )
        
        // Register UI functions
        availableFunctions.append(showNotification)
    }
    
    /// Register a custom function
    func registerFunction(_ function: AIFunction) {
        // Check if a function with the same name already exists
        if let index = availableFunctions.firstIndex(where: { $0.name == function.name }) {
            // Replace the existing function
            availableFunctions[index] = function
        } else {
            // Add the new function
            availableFunctions.append(function)
        }
    }
    
    /// Unregister a function
    func unregisterFunction(named name: String) {
        if let index = availableFunctions.firstIndex(where: { $0.name == name }) {
            availableFunctions.remove(at: index)
        }
    }
    
    /// Get a function by name
    func getFunction(named name: String) -> AIFunction? {
        return availableFunctions.first { $0.name == name }
    }
    
    /// Execute a function by name
    func executeFunction(named name: String, parameters: [String: Any]) async throws -> Any {
        guard let function = getFunction(named: name) else {
            throw FunctionError.functionNotFound(name)
        }
        
        guard let execute = function.execute else {
            throw FunctionError.executionNotImplemented(name)
        }
        
        return try await execute(parameters)
    }
    
    /// Get function definitions for AI API calls
    func getFunctionDefinitions() -> [[String: Any]] {
        return availableFunctions.map { function in
            var definition: [String: Any] = [
                "name": function.name,
                "description": function.description
            ]
            
            // Add parameters if any
            if !function.parameters.isEmpty {
                var parametersObject: [String: Any] = [
                    "type": "object"
                ]
                
                var properties: [String: Any] = [:]
                var required: [String] = []
                
                for parameter in function.parameters {
                    var propertyObject: [String: Any] = [
                        "type": parameter.type.rawValue,
                        "description": parameter.description
                    ]
                    
                    // Add enum values if any
                    if let enumValues = parameter.enumValues {
                        propertyObject["enum"] = enumValues
                    }
                    
                    properties[parameter.name] = propertyObject
                    
                    if parameter.required {
                        required.append(parameter.name)
                    }
                }
                
                parametersObject["properties"] = properties
                
                if !required.isEmpty {
                    parametersObject["required"] = required
                }
                
                definition["parameters"] = parametersObject
            }
            
            return definition
        }
    }
    
    /// Errors that can occur with functions
    enum FunctionError: Error, LocalizedError {
        case functionNotFound(String)
        case invalidParameters(String)
        case executionFailed(String)
        case executionNotImplemented(String)
        
        var errorDescription: String? {
            switch self {
            case .functionNotFound(let name):
                return "Function not found: \(name)"
            case .invalidParameters(let message):
                return "Invalid parameters: \(message)"
            case .executionFailed(let message):
                return "Function execution failed: \(message)"
            case .executionNotImplemented(let name):
                return "Function execution not implemented: \(name)"
            }
        }
    }
}

/// Represents a function that can be called by the AI
struct AIFunction: Identifiable, Codable {
    /// Unique identifier for the function
    let id: UUID
    
    /// Name of the function used in API calls
    let name: String
    
    /// Description of what the function does
    let description: String
    
    /// Parameters required by the function
    let parameters: [AIFunctionParameter]
    
    /// Function to execute when called
    var execute: (([String: Any]) async throws -> Any)?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, parameters
    }
    
    init(id: UUID = UUID(), name: String, description: String, parameters: [AIFunctionParameter], execute: (([String: Any]) async throws -> Any)? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.parameters = parameters
        self.execute = execute
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        parameters = try container.decode([AIFunctionParameter].self, forKey: .parameters)
        execute = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(parameters, forKey: .parameters)
    }
}

/// Represents a parameter for an AI function
struct AIFunctionParameter: Identifiable, Codable {
    /// Unique identifier for the parameter
    let id: UUID
    
    /// Name of the parameter
    let name: String
    
    /// Description of the parameter
    let description: String
    
    /// Type of the parameter (string, number, boolean, etc.)
    let type: AIFunctionParameterType
    
    /// Whether the parameter is required
    let required: Bool
    
    /// Possible enum values for the parameter (if applicable)
    let enumValues: [String]?
    
    init(id: UUID = UUID(), name: String, description: String, type: AIFunctionParameterType, required: Bool = true, enumValues: [String]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.required = required
        self.enumValues = enumValues
    }
}

/// Types of parameters for AI functions
enum AIFunctionParameterType: String, Codable {
    case string
    case number
    case boolean
    case object
    case array
}
