
import Foundation
import Combine

/// Manager class for handling voice command detection and execution
class VoiceCommandManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Indicates if a command was detected
    @Published var commandDetected = false
    
    /// The detected command
    @Published var detectedCommand: VoiceCommand?
    
    /// The detected command parameters
    @Published var commandParameters: [String: String] = [:]
    
    // MARK: - Private Properties
    
    /// The registered commands
    private var commands: [VoiceCommand] = []
    
    /// The default commands
    private var defaultCommands: [VoiceCommand] = []
    
    // MARK: - Initialization
    
    init() {
        registerDefaultCommands()
    }
    
    // MARK: - Public Methods
    
    /// Register a new command
    /// - Parameter command: The command to register
    func registerCommand(_ command: VoiceCommand) {
        commands.append(command)
    }
    
    /// Register multiple commands
    /// - Parameter commands: The commands to register
    func registerCommands(_ commands: [VoiceCommand]) {
        self.commands.append(contentsOf: commands)
    }
    
    /// Unregister a command
    /// - Parameter command: The command to unregister
    func unregisterCommand(_ command: VoiceCommand) {
        commands.removeAll { $0.id == command.id }
    }
    
    /// Unregister all commands
    func unregisterAllCommands() {
        commands.removeAll()
        registerDefaultCommands()
    }
    
    /// Process text for command detection
    /// - Parameter text: The text to process
    /// - Returns: True if a command was detected, false otherwise
    @discardableResult
    func processText(_ text: String) -> Bool {
        // Reset state
        commandDetected = false
        detectedCommand = nil
        commandParameters.removeAll()
        
        // Normalize text
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for commands
        for command in commands + defaultCommands {
            if let match = matchCommand(command, in: normalizedText) {
                commandDetected = true
                detectedCommand = command
                commandParameters = match
                return true
            }
        }
        
        return false
    }
    
    /// Execute the detected command
    /// - Parameter context: The context for command execution
    /// - Returns: True if the command was executed successfully, false otherwise
    func executeCommand(with context: Any? = nil) -> Bool {
        guard let command = detectedCommand else {
            return false
        }
        
        return command.execute(with: commandParameters, context: context)
    }
    
    // MARK: - Private Methods
    
    /// Register default commands
    private func registerDefaultCommands() {
        defaultCommands = [
            VoiceCommand(
                id: "send_message",
                patterns: [
                    "send (.*)",
                    "send message (.*)",
                    "send this (.*)"
                ],
                execute: { parameters, context in
                    // Implementation will be provided by the ChatViewModel
                    return true
                }
            ),
            VoiceCommand(
                id: "clear_chat",
                patterns: [
                    "clear chat",
                    "clear conversation",
                    "clear messages",
                    "start new chat",
                    "start new conversation"
                ],
                execute: { parameters, context in
                    // Implementation will be provided by the ChatViewModel
                    return true
                }
            ),
            VoiceCommand(
                id: "stop_listening",
                patterns: [
                    "stop listening",
                    "stop recording",
                    "stop voice input"
                ],
                execute: { parameters, context in
                    // Implementation will be provided by the ChatViewModel
                    return true
                }
            ),
            VoiceCommand(
                id: "read_response",
                patterns: [
                    "read response",
                    "read message",
                    "read last message",
                    "read last response"
                ],
                execute: { parameters, context in
                    // Implementation will be provided by the ChatViewModel
                    return true
                }
            )
        ]
    }
    
    /// Match a command in the given text
    /// - Parameters:
    ///   - command: The command to match
    ///   - text: The text to match against
    /// - Returns: The matched parameters if a match was found, nil otherwise
    private func matchCommand(_ command: VoiceCommand, in text: String) -> [String: String]? {
        for pattern in command.patterns {
            // Create regex pattern
            let regexPattern = "^\\s*\(pattern)\\s*$"
            
            do {
                // Create regex
                let regex = try NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive])
                
                // Match regex
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    // Extract parameters
                    var parameters: [String: String] = [:]
                    
                    // Add captured groups as parameters
                    for i in 1..<match.numberOfRanges {
                        if let range = Range(match.range(at: i), in: text) {
                            parameters["param\(i)"] = String(text[range])
                        }
                    }
                    
                    return parameters
                }
            } catch {
                print("Error creating regex: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
}

/// Voice command struct
struct VoiceCommand: Identifiable, Equatable {
    /// The unique identifier for the command
    let id: String
    
    /// The patterns to match for the command
    let patterns: [String]
    
    /// The action to execute when the command is detected
    let execute: ([String: String], Any?) -> Bool
    
    /// Equatable implementation
    static func == (lhs: VoiceCommand, rhs: VoiceCommand) -> Bool {
        return lhs.id == rhs.id
    }
}
