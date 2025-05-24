//
//  ToolUseManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import SwiftUI

/// Manager for handling AI tool use capabilities
class ToolUseManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = ToolUseManager()
    
    /// Available tools that can be used by the AI
    @Published private(set) var availableTools: [AITool] = []
    
    /// Function calling manager for executing functions
    private let functionCallingManager: FunctionCallingManager
    
    /// Plugin manager for accessing plugin tools
    private let pluginManager: PluginManager
    
    /// Storage service for persisting tool data
    private let storageService: StorageService
    
    /// Background task manager for tool operations
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(functionCallingManager: FunctionCallingManager = FunctionCallingManager.shared, 
         pluginManager: PluginManager = PluginManager.shared,
         storageService: StorageService = StorageService()) {
        self.functionCallingManager = functionCallingManager
        self.pluginManager = pluginManager
        self.storageService = storageService
        
        // Register default tools
        registerDefaultTools()
        
        // Listen for plugin changes
        setupPluginObservers()
    }
    
    /// Set up observers for plugin changes
    private func setupPluginObservers() {
        // When enabled plugins change, update available tools
        pluginManager.$enabledPlugins
            .sink { [weak self] plugins in
                self?.updateToolsFromPlugins(plugins)
            }
            .store(in: &cancellables)
    }
    
    /// Update tools from plugins
    private func updateToolsFromPlugins(_ plugins: [any PluginProtocol]) {
        // Get all tools from plugins
        let pluginTools = plugins.flatMap { $0.tools }
        
        // Filter out existing plugin tools
        let existingPluginTools = availableTools.filter { tool in
            return tool.source == .plugin
        }
        
        // Remove existing plugin tools
        for tool in existingPluginTools {
            if let index = availableTools.firstIndex(where: { $0.id == tool.id }) {
                availableTools.remove(at: index)
            }
        }
        
        // Add new plugin tools
        availableTools.append(contentsOf: pluginTools)
    }
    
    /// Register default tools available to the AI
    private func registerDefaultTools() {
        // System tools
        registerSystemTools()
        
        // Web tools
        registerWebTools()
        
        // File tools
        registerFileTools()
        
        // Get tools from plugins
        let pluginTools = pluginManager.enabledPlugins.flatMap { $0.tools }
        availableTools.append(contentsOf: pluginTools)
    }
    
    /// Register system tools
    private func registerSystemTools() {
        // Execute shell command
        let executeShellCommand = AITool(
            name: "execute_shell_command",
            description: "Execute a shell command on the system",
            parameters: [
                AIToolParameter(
                    name: "command",
                    description: "The shell command to execute",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "timeout",
                    description: "Timeout in seconds",
                    type: .number,
                    required: false
                )
            ],
            execute: { parameters in
                guard let command = parameters["command"] as? String else {
                    throw ToolError.invalidParameters("Command parameter is required")
                }
                
                let timeout = parameters["timeout"] as? Double ?? 30.0
                
                // Create a process
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = ["-c", command]
                
                // Set up pipes for output
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                // Execute the command
                try process.run()
                
                // Wait for the process to complete with timeout
                let group = DispatchGroup()
                group.enter()
                
                let timer = DispatchSource.makeTimerSource()
                timer.schedule(deadline: .now() + timeout)
                timer.setEventHandler {
                    if process.isRunning {
                        process.terminate()
                    }
                }
                timer.resume()
                
                DispatchQueue.global().async {
                    process.waitUntilExit()
                    timer.cancel()
                    group.leave()
                }
                
                let result = group.wait(timeout: .now() + timeout)
                
                if result == .timedOut {
                    process.terminate()
                    throw ToolError.executionTimeout("Command execution timed out after \(timeout) seconds")
                }
                
                // Get the output
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""
                
                return [
                    "exit_code": process.terminationStatus,
                    "output": output,
                    "error": error
                ]
            },
            source: .system
        )
        
        // Get environment variable
        let getEnvironmentVariable = AITool(
            name: "get_environment_variable",
            description: "Get the value of an environment variable",
            parameters: [
                AIToolParameter(
                    name: "name",
                    description: "Name of the environment variable",
                    type: .string,
                    required: true
                )
            ],
            execute: { parameters in
                guard let name = parameters["name"] as? String else {
                    throw ToolError.invalidParameters("Name parameter is required")
                }
                
                let value = ProcessInfo.processInfo.environment[name]
                
                return [
                    "name": name,
                    "value": value as Any
                ]
            },
            source: .system
        )
        
        // Register system tools
        availableTools.append(executeShellCommand)
        availableTools.append(getEnvironmentVariable)
    }
    
    /// Register web tools
    private func registerWebTools() {
        // Fetch URL
        let fetchURL = AITool(
            name: "fetch_url",
            description: "Fetch content from a URL",
            parameters: [
                AIToolParameter(
                    name: "url",
                    description: "URL to fetch",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "method",
                    description: "HTTP method to use",
                    type: .string,
                    required: false,
                    enumValues: ["GET", "POST", "PUT", "DELETE"]
                ),
                AIToolParameter(
                    name: "headers",
                    description: "HTTP headers to include",
                    type: .object,
                    required: false
                ),
                AIToolParameter(
                    name: "body",
                    description: "Request body for POST/PUT requests",
                    type: .string,
                    required: false
                )
            ],
            execute: { parameters in
                guard let urlString = parameters["url"] as? String,
                      let url = URL(string: urlString) else {
                    throw ToolError.invalidParameters("Valid URL parameter is required")
                }
                
                let method = parameters["method"] as? String ?? "GET"
                let headers = parameters["headers"] as? [String: String] ?? [:]
                let body = parameters["body"] as? String
                
                // Create the request
                var request = URLRequest(url: url)
                request.httpMethod = method
                
                // Add headers
                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                // Add body if provided
                if let body = body {
                    request.httpBody = body.data(using: .utf8)
                }
                
                // Perform the request
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Parse the response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ToolError.executionFailed("Invalid response")
                }
                
                // Try to parse as JSON
                var responseBody: Any
                do {
                    responseBody = try JSONSerialization.jsonObject(with: data)
                } catch {
                    // If not JSON, convert to string
                    responseBody = String(data: data, encoding: .utf8) ?? ""
                }
                
                return [
                    "status_code": httpResponse.statusCode,
                    "headers": httpResponse.allHeaderFields,
                    "body": responseBody
                ]
            },
            source: .system
        )
        
        // Register web tools
        availableTools.append(fetchURL)
    }
    
    /// Register file tools
    private func registerFileTools() {
        // Read file
        let readFile = AITool(
            name: "read_file",
            description: "Read the contents of a file",
            parameters: [
                AIToolParameter(
                    name: "path",
                    description: "Path to the file",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "encoding",
                    description: "File encoding",
                    type: .string,
                    required: false,
                    enumValues: ["utf8", "ascii", "iso8859"]
                )
            ],
            execute: { parameters in
                guard let path = parameters["path"] as? String else {
                    throw ToolError.invalidParameters("Path parameter is required")
                }
                
                let encoding = parameters["encoding"] as? String ?? "utf8"
                
                // Determine the string encoding
                let stringEncoding: String.Encoding
                switch encoding {
                case "ascii":
                    stringEncoding = .ascii
                case "iso8859":
                    stringEncoding = .isoLatin1
                default:
                    stringEncoding = .utf8
                }
                
                // Read the file
                let fileURL = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: fileURL)
                
                guard let content = String(data: data, encoding: stringEncoding) else {
                    throw ToolError.executionFailed("Failed to decode file with specified encoding")
                }
                
                return [
                    "content": content
                ]
            },
            source: .system
        )
        
        // Write file
        let writeFile = AITool(
            name: "write_file",
            description: "Write content to a file",
            parameters: [
                AIToolParameter(
                    name: "path",
                    description: "Path to the file",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "content",
                    description: "Content to write",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "append",
                    description: "Whether to append to the file",
                    type: .boolean,
                    required: false
                ),
                AIToolParameter(
                    name: "encoding",
                    description: "File encoding",
                    type: .string,
                    required: false,
                    enumValues: ["utf8", "ascii", "iso8859"]
                )
            ],
            execute: { parameters in
                guard let path = parameters["path"] as? String,
                      let content = parameters["content"] as? String else {
                    throw ToolError.invalidParameters("Path and content parameters are required")
                }
                
                let append = parameters["append"] as? Bool ?? false
                let encoding = parameters["encoding"] as? String ?? "utf8"
                
                // Determine the string encoding
                let stringEncoding: String.Encoding
                switch encoding {
                case "ascii":
                    stringEncoding = .ascii
                case "iso8859":
                    stringEncoding = .isoLatin1
                default:
                    stringEncoding = .utf8
                }
                
                // Write the file
                let fileURL = URL(fileURLWithPath: path)
                
                if append, FileManager.default.fileExists(atPath: path) {
                    // Append to existing file
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    
                    if let data = content.data(using: stringEncoding) {
                        fileHandle.write(data)
                    }
                    
                    fileHandle.closeFile()
                } else {
                    // Create or overwrite file
                    try content.write(to: fileURL, atomically: true, encoding: stringEncoding)
                }
                
                return [
                    "success": true
                ]
            },
            source: .system
        )
        
        // Register file tools
        availableTools.append(readFile)
        availableTools.append(writeFile)
    }
    
    /// Register a custom tool
    func registerTool(_ tool: AITool) {
        // Check if a tool with the same name already exists
        if let index = availableTools.firstIndex(where: { $0.name == tool.name }) {
            // Replace the existing tool
            availableTools[index] = tool
        } else {
            // Add the new tool
            availableTools.append(tool)
        }
    }
    
    /// Unregister a tool
    func unregisterTool(named name: String) {
        if let index = availableTools.firstIndex(where: { $0.name == name }) {
            availableTools.remove(at: index)
        }
    }
    
    /// Get a tool by name
    func getTool(named name: String) -> AITool? {
        return availableTools.first { $0.name == name }
    }
    
    /// Execute a tool by name
    func executeTool(named name: String, parameters: [String: Any]) async throws -> Any {
        guard let tool = getTool(named: name) else {
            throw ToolError.toolNotFound(name)
        }
        
        guard let execute = tool.execute else {
            throw ToolError.executionNotImplemented(name)
        }
        
        return try await execute(parameters)
    }
    
    /// Get tool definitions for AI API calls
    func getToolDefinitions() -> [[String: Any]] {
        return availableTools.map { tool in
            var definition: [String: Any] = [
                "type": "function",
                "function": [
                    "name": tool.name,
                    "description": tool.description
                ]
            ]
            
            // Add parameters if any
            if !tool.parameters.isEmpty {
                var parametersObject: [String: Any] = [
                    "type": "object"
                ]
                
                var properties: [String: Any] = [:]
                var required: [String] = []
                
                for parameter in tool.parameters {
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
                
                var functionObject = definition["function"] as! [String: Any]
                functionObject["parameters"] = parametersObject
                definition["function"] = functionObject
            }
            
            return definition
        }
    }
    
    /// Process a tool call from the AI
    func processToolCall(_ toolCall: [String: Any]) async throws -> Any {
        guard let type = toolCall["type"] as? String,
              type == "function",
              let function = toolCall["function"] as? [String: Any],
              let name = function["name"] as? String,
              let arguments = function["arguments"] as? String else {
            throw ToolError.invalidToolCall("Invalid tool call format")
        }
        
        // Parse the arguments as JSON
        let parametersData = arguments.data(using: .utf8) ?? Data()
        let parameters = try JSONSerialization.jsonObject(with: parametersData) as? [String: Any] ?? [:]
        
        // Execute the tool
        return try await executeTool(named: name, parameters: parameters)
    }
    
    /// Errors that can occur with tools
    enum ToolError: Error, LocalizedError {
        case toolNotFound(String)
        case invalidParameters(String)
        case executionFailed(String)
        case executionTimeout(String)
        case executionNotImplemented(String)
        case invalidToolCall(String)
        
        var errorDescription: String? {
            switch self {
            case .toolNotFound(let name):
                return "Tool not found: \(name)"
            case .invalidParameters(let message):
                return "Invalid parameters: \(message)"
            case .executionFailed(let message):
                return "Tool execution failed: \(message)"
            case .executionTimeout(let message):
                return "Tool execution timed out: \(message)"
            case .executionNotImplemented(let name):
                return "Tool execution not implemented: \(name)"
            case .invalidToolCall(let message):
                return "Invalid tool call: \(message)"
            }
        }
    }
}

/// Represents a tool that can be used by the AI
struct AITool: Identifiable, Codable {
    /// Unique identifier for the tool
    let id: UUID
    
    /// Name of the tool used in API calls
    let name: String
    
    /// Description of what the tool does
    let description: String
    
    /// Parameters required by the tool
    let parameters: [AIToolParameter]
    
    /// Function to execute when the tool is used
    var execute: (([String: Any]) async throws -> Any)?
    
    /// Source of the tool
    let source: AIToolSource
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, parameters, source
    }
    
    init(id: UUID = UUID(), name: String, description: String, parameters: [AIToolParameter], execute: (([String: Any]) async throws -> Any)? = nil, source: AIToolSource = .plugin) {
        self.id = id
        self.name = name
        self.description = description
        self.parameters = parameters
        self.execute = execute
        self.source = source
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        parameters = try container.decode([AIToolParameter].self, forKey: .parameters)
        source = try container.decode(AIToolSource.self, forKey: .source)
        execute = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(source, forKey: .source)
    }
}

/// Represents a parameter for an AI tool
struct AIToolParameter: Identifiable, Codable {
    /// Unique identifier for the parameter
    let id: UUID
    
    /// Name of the parameter
    let name: String
    
    /// Description of the parameter
    let description: String
    
    /// Type of the parameter (string, number, boolean, etc.)
    let type: AIToolParameterType
    
    /// Whether the parameter is required
    let required: Bool
    
    /// Possible enum values for the parameter (if applicable)
    let enumValues: [String]?
    
    init(id: UUID = UUID(), name: String, description: String, type: AIToolParameterType, required: Bool = true, enumValues: [String]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.required = required
        self.enumValues = enumValues
    }
}

/// Types of parameters for AI tools
enum AIToolParameterType: String, Codable {
    case string
    case number
    case boolean
    case object
    case array
}

/// Source of an AI tool
enum AIToolSource: String, Codable {
    case system
    case plugin
    case user
}
