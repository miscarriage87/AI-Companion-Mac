//
//  ErrorTracker.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine
import os.log

/// ErrorTracker monitors, logs, and reports errors in the application
/// It provides centralized error handling and user-friendly error messages
class ErrorTracker {
    // MARK: - Properties
    
    // Logger
    private let logger = Logger(subsystem: "com.aicompanion.app", category: "Errors")
    
    // Error history
    private var errorHistory: [TrackedError] = []
    
    // Publishers
    private let errorSubject = PassthroughSubject<TrackedError, Never>()
    var errorPublisher: AnyPublisher<TrackedError, Never> {
        return errorSubject.eraseToAnyPublisher()
    }
    
    // Singleton instance
    static let shared = ErrorTracker()
    
    // MARK: - Initialization
    
    private init() {
        // Load error history from persistent storage
        loadErrorHistory()
    }
    
    // MARK: - Error Tracking
    
    /// Track an error
    /// - Parameters:
    ///   - error: The error to track
    ///   - source: Source of the error
    ///   - severity: Error severity
    ///   - userInfo: Additional information about the error
    func trackError(_ error: Error, source: ErrorSource, severity: ErrorSeverity, userInfo: [String: Any] = [:]) {
        // Create tracked error
        let trackedError = TrackedError(
            id: UUID(),
            timestamp: Date(),
            error: error,
            source: source,
            severity: severity,
            userInfo: userInfo,
            stackTrace: Thread.callStackSymbols
        )
        
        // Log the error
        logError(trackedError)
        
        // Store in history
        errorHistory.append(trackedError)
        
        // Save error history
        saveErrorHistory()
        
        // Publish error
        errorSubject.send(trackedError)
        
        // Handle based on severity
        handleError(trackedError)
    }
    
    /// Log an error to the system log
    /// - Parameter trackedError: The error to log
    private func logError(_ trackedError: TrackedError) {
        let errorMessage = "[\(trackedError.source.rawValue)] \(trackedError.error.localizedDescription)"
        
        switch trackedError.severity {
        case .critical:
            logger.critical("\(errorMessage, privacy: .public)")
        case .error:
            logger.error("\(errorMessage, privacy: .public)")
        case .warning:
            logger.warning("\(errorMessage, privacy: .public)")
        case .info:
            logger.info("\(errorMessage, privacy: .public)")
        }
        
        // Log additional info
        if !trackedError.userInfo.isEmpty {
            logger.debug("Error details: \(String(describing: trackedError.userInfo), privacy: .private)")
        }
    }
    
    /// Handle an error based on its severity
    /// - Parameter trackedError: The error to handle
    private func handleError(_ trackedError: TrackedError) {
        switch trackedError.severity {
        case .critical:
            // For critical errors, we might want to show an alert and/or restart the affected component
            // In a real app, this would display an alert to the user
            print("CRITICAL ERROR: \(trackedError.error.localizedDescription)")
            
        case .error:
            // For regular errors, show a notification
            print("ERROR: \(trackedError.error.localizedDescription)")
            
        case .warning:
            // For warnings, log but don't necessarily notify the user
            print("WARNING: \(trackedError.error.localizedDescription)")
            
        case .info:
            // Informational errors are just logged
            break
        }
    }
    
    // MARK: - Error History
    
    /// Load error history from persistent storage
    private func loadErrorHistory() {
        // In a real implementation, this would load from UserDefaults or a database
        // For now, we'll start with an empty history
        errorHistory = []
    }
    
    /// Save error history to persistent storage
    private func saveErrorHistory() {
        // In a real implementation, this would save to UserDefaults or a database
        // For now, we'll just limit the history size
        if errorHistory.count > 100 {
            errorHistory = Array(errorHistory.suffix(100))
        }
    }
    
    /// Get recent errors
    /// - Parameter limit: Maximum number of errors to return
    /// - Returns: Array of recent errors
    func getRecentErrors(limit: Int = 10) -> [TrackedError] {
        return Array(errorHistory.suffix(min(limit, errorHistory.count)))
    }
    
    /// Get errors by severity
    /// - Parameter severity: Error severity to filter by
    /// - Returns: Array of errors with the specified severity
    func getErrors(bySeverity severity: ErrorSeverity) -> [TrackedError] {
        return errorHistory.filter { $0.severity == severity }
    }
    
    /// Get errors by source
    /// - Parameter source: Error source to filter by
    /// - Returns: Array of errors from the specified source
    func getErrors(bySource source: ErrorSource) -> [TrackedError] {
        return errorHistory.filter { $0.source == source }
    }
    
    // MARK: - Error Reporting
    
    /// Generate an error report
    /// - Returns: Error report as a string
    func generateErrorReport() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        var report = "Error Report\n"
        report += "===========\n\n"
        
        // Group errors by severity
        let criticalErrors = getErrors(bySeverity: .critical)
        let regularErrors = getErrors(bySeverity: .error)
        let warnings = getErrors(bySeverity: .warning)
        
        // Add critical errors
        report += "Critical Errors (\(criticalErrors.count)):\n"
        for error in criticalErrors.suffix(5) {
            report += "- [\(dateFormatter.string(from: error.timestamp))] \(error.error.localizedDescription)\n"
            report += "  Source: \(error.source.rawValue)\n"
        }
        report += "\n"
        
        // Add regular errors
        report += "Errors (\(regularErrors.count)):\n"
        for error in regularErrors.suffix(5) {
            report += "- [\(dateFormatter.string(from: error.timestamp))] \(error.error.localizedDescription)\n"
            report += "  Source: \(error.source.rawValue)\n"
        }
        report += "\n"
        
        // Add warnings
        report += "Warnings (\(warnings.count)):\n"
        for warning in warnings.suffix(5) {
            report += "- [\(dateFormatter.string(from: warning.timestamp))] \(warning.error.localizedDescription)\n"
            report += "  Source: \(warning.source.rawValue)\n"
        }
        
        return report
    }
    
    /// Submit error report to the developer
    /// - Returns: Success status
    func submitErrorReport() -> Bool {
        // In a real implementation, this would send the report to a server
        // For now, we'll just simulate success
        print("Error report submitted")
        return true
    }
    
    // MARK: - User-Friendly Messages
    
    /// Get a user-friendly message for an error
    /// - Parameter error: The error to get a message for
    /// - Returns: User-friendly error message
    func getUserFriendlyMessage(for error: Error) -> String {
        // Check if it's our custom error type
        if let appError = error as? AppError {
            return appError.userFriendlyMessage
        }
        
        // For system errors, provide generic but helpful messages
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSURLErrorDomain:
            return "There was a problem connecting to the network. Please check your internet connection and try again."
            
        case NSCocoaErrorDomain:
            if nsError.code == NSFileNoSuchFileError {
                return "A required file could not be found. Please reinstall the application if this problem persists."
            } else {
                return "There was a problem with the application. Please try again later."
            }
            
        default:
            return "An unexpected error occurred. Please try again later."
        }
    }
}

// MARK: - Supporting Types

/// Error severity levels
enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
}

/// Error sources
enum ErrorSource: String {
    case network = "Network"
    case database = "Database"
    case fileSystem = "File System"
    case userInterface = "UI"
    case aiModel = "AI Model"
    case calendar = "Calendar"
    case location = "Location"
    case ar = "Augmented Reality"
    case collaboration = "Collaboration"
    case unknown = "Unknown"
}

/// Tracked error
struct TrackedError {
    let id: UUID
    let timestamp: Date
    let error: Error
    let source: ErrorSource
    let severity: ErrorSeverity
    let userInfo: [String: Any]
    let stackTrace: [String]
}

/// Custom application error
enum AppError: Error {
    case networkUnavailable
    case authenticationFailed
    case dataCorrupted
    case permissionDenied(feature: String)
    case aiModelUnavailable
    case calendarAccessDenied
    case locationAccessDenied
    case arUnavailable
    case collaborationFailed
    
    var userFriendlyMessage: String {
        switch self {
        case .networkUnavailable:
            return "Unable to connect to the network. Please check your internet connection and try again."
            
        case .authenticationFailed:
            return "Authentication failed. Please sign in again."
            
        case .dataCorrupted:
            return "Some data appears to be corrupted. Please restart the application."
            
        case .permissionDenied(let feature):
            return "The app doesn't have permission to access \(feature). Please update permissions in System Settings."
            
        case .aiModelUnavailable:
            return "The AI model is currently unavailable. Please try again later."
            
        case .calendarAccessDenied:
            return "Calendar access is required for this feature. Please grant calendar access in System Settings."
            
        case .locationAccessDenied:
            return "Location access is required for this feature. Please grant location access in System Settings."
            
        case .arUnavailable:
            return "Augmented Reality features are not available on this device or require camera access."
            
        case .collaborationFailed:
            return "Unable to connect to collaboration session. Please check your network and try again."
        }
    }
}

// MARK: - Extensions

extension ErrorTracker {
    /// Track a network error
    /// - Parameters:
    ///   - error: The network error
    ///   - endpoint: API endpoint that failed
    ///   - statusCode: HTTP status code if available
    func trackNetworkError(_ error: Error, endpoint: String, statusCode: Int? = nil) {
        var userInfo: [String: Any] = ["endpoint": endpoint]
        if let statusCode = statusCode {
            userInfo["statusCode"] = statusCode
        }
        
        trackError(error, source: .network, severity: .error, userInfo: userInfo)
    }
    
    /// Track a calendar error
    /// - Parameters:
    ///   - error: The calendar error
    ///   - operation: Calendar operation that failed
    func trackCalendarError(_ error: Error, operation: String) {
        trackError(error, source: .calendar, severity: .warning, userInfo: ["operation": operation])
    }
    
    /// Track an AR error
    /// - Parameters:
    ///   - error: The AR error
    ///   - feature: AR feature that failed
    func trackARError(_ error: Error, feature: String) {
        trackError(error, source: .ar, severity: .warning, userInfo: ["feature": feature])
    }
    
    /// Track a collaboration error
    /// - Parameters:
    ///   - error: The collaboration error
    ///   - sessionID: Collaboration session ID if available
    func trackCollaborationError(_ error: Error, sessionID: UUID? = nil) {
        var userInfo: [String: Any] = [:]
        if let sessionID = sessionID {
            userInfo["sessionID"] = sessionID.uuidString
        }
        
        trackError(error, source: .collaboration, severity: .error, userInfo: userInfo)
    }
}
