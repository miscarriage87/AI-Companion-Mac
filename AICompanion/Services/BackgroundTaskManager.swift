//
//  BackgroundTaskManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import os.log

/// Manager for handling background tasks
class BackgroundTaskManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = BackgroundTaskManager()
    
    /// Queue for executing background tasks
    private let backgroundQueue = DispatchQueue(label: "com.aicompanion.backgroundQueue", qos: .background, attributes: .concurrent)
    
    /// Operation queue for managing task priorities
    private let operationQueue = OperationQueue()
    
    /// Active background tasks
    @Published private(set) var activeTasks: [UUID: TaskInfo] = [:]
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.aicompanion", category: "BackgroundTaskManager")
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Configure operation queue
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 4
    }
    
    /// Execute a task in the background
    func executeTask<T>(priority: TaskPriority = .background, name: String = "Background Task", operation: @escaping () async throws -> T) -> Task<T, Error> {
        let taskId = UUID()
        
        // Create task info
        let taskInfo = TaskInfo(id: taskId, name: name, startTime: Date(), status: .running)
        
        // Add to active tasks
        DispatchQueue.main.async {
            self.activeTasks[taskId] = taskInfo
        }
        
        // Log task start
        logger.debug("Starting background task: \(name) [\(taskId.uuidString)]")
        
        // Create and execute the task
        let task = Task(priority: priority) {
            do {
                // Execute the operation
                let result = try await operation()
                
                // Update task info
                DispatchQueue.main.async {
                    self.activeTasks[taskId]?.status = .completed
                    self.activeTasks[taskId]?.endTime = Date()
                }
                
                // Log task completion
                logger.debug("Completed background task: \(name) [\(taskId.uuidString)]")
                
                // Remove task after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.activeTasks.removeValue(forKey: taskId)
                }
                
                return result
            } catch {
                // Update task info
                DispatchQueue.main.async {
                    self.activeTasks[taskId]?.status = .failed
                    self.activeTasks[taskId]?.endTime = Date()
                    self.activeTasks[taskId]?.error = error.localizedDescription
                }
                
                // Log task failure
                logger.error("Failed background task: \(name) [\(taskId.uuidString)]: \(error.localizedDescription)")
                
                // Remove task after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.activeTasks.removeValue(forKey: taskId)
                }
                
                throw error
            }
        }
        
        // Store task cancellation handler
        DispatchQueue.main.async {
            self.activeTasks[taskId]?.cancellationHandler = { [weak task] in
                task?.cancel()
            }
        }
        
        return task
    }
    
    /// Execute a task on the background queue
    func executeOnBackgroundQueue<T>(qos: DispatchQoS.QoSClass = .background, operation: @escaping () throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async(qos: qos) {
                do {
                    let result = try operation()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Execute a task on the operation queue
    func executeOnOperationQueue<T>(qos: QualityOfService = .background, operation: @escaping () throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let blockOperation = BlockOperation {
                do {
                    let result = try operation()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            blockOperation.qualityOfService = qos
            operationQueue.addOperation(blockOperation)
        }
    }
    
    /// Cancel a specific task
    func cancelTask(id: UUID) {
        guard let taskInfo = activeTasks[id] else {
            return
        }
        
        // Call cancellation handler
        taskInfo.cancellationHandler?()
        
        // Update task info
        DispatchQueue.main.async {
            self.activeTasks[id]?.status = .cancelled
            self.activeTasks[id]?.endTime = Date()
        }
        
        // Log task cancellation
        logger.debug("Cancelled background task: \(taskInfo.name) [\(id.uuidString)]")
        
        // Remove task after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.activeTasks.removeValue(forKey: id)
        }
    }
    
    /// Cancel all active tasks
    func cancelAllTasks() {
        for (id, taskInfo) in activeTasks {
            // Call cancellation handler
            taskInfo.cancellationHandler?()
            
            // Update task info
            DispatchQueue.main.async {
                self.activeTasks[id]?.status = .cancelled
                self.activeTasks[id]?.endTime = Date()
            }
            
            // Log task cancellation
            logger.debug("Cancelled background task: \(taskInfo.name) [\(id.uuidString)]")
        }
        
        // Remove all tasks after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.activeTasks.removeAll()
        }
    }
    
    /// Get task info for a specific task
    func getTaskInfo(id: UUID) -> TaskInfo? {
        return activeTasks[id]
    }
    
    /// Get all active tasks
    func getAllTasks() -> [TaskInfo] {
        return Array(activeTasks.values)
    }
    
    /// Get tasks by status
    func getTasks(withStatus status: TaskStatus) -> [TaskInfo] {
        return activeTasks.values.filter { $0.status == status }
    }
    
    /// Execute a periodic task
    func executePeriodicTask(interval: TimeInterval, name: String = "Periodic Task", operation: @escaping () async throws -> Void) -> Task<Void, Error> {
        return executeTask(name: name) {
            while !Task.isCancelled {
                do {
                    try await operation()
                } catch {
                    self.logger.error("Error in periodic task \(name): \(error.localizedDescription)")
                }
                
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    /// Execute a delayed task
    func executeDelayedTask<T>(delay: TimeInterval, name: String = "Delayed Task", operation: @escaping () async throws -> T) -> Task<T, Error> {
        return executeTask(name: name) {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            return try await operation()
        }
    }
    
    /// Execute a task with a timeout
    func executeWithTimeout<T>(timeout: TimeInterval, name: String = "Timeout Task", operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the actual task
            group.addTask {
                return try await operation()
            }
            
            // Add a timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TaskError.timeout(name: name, timeout: timeout)
            }
            
            // Return the first completed task or throw an error
            guard let result = try await group.next() else {
                throw TaskError.unknown
            }
            
            // Cancel any remaining tasks
            group.cancelAll()
            
            return result
        }
    }
}

/// Information about a background task
class TaskInfo: Identifiable, ObservableObject {
    /// Unique identifier for the task
    let id: UUID
    
    /// Name of the task
    let name: String
    
    /// Time when the task started
    let startTime: Date
    
    /// Time when the task ended (if completed, failed, or cancelled)
    @Published var endTime: Date?
    
    /// Status of the task
    @Published var status: TaskStatus
    
    /// Error message if the task failed
    @Published var error: String?
    
    /// Progress of the task (0-1)
    @Published var progress: Double = 0
    
    /// Cancellation handler for the task
    var cancellationHandler: (() -> Void)?
    
    init(id: UUID, name: String, startTime: Date, status: TaskStatus = .running) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.status = status
    }
    
    /// Duration of the task in seconds
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
}

/// Status of a background task
enum TaskStatus: String, Codable {
    case running
    case completed
    case failed
    case cancelled
}

/// Errors that can occur with tasks
enum TaskError: Error, LocalizedError {
    case timeout(name: String, timeout: TimeInterval)
    case cancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .timeout(let name, let timeout):
            return "Task \(name) timed out after \(timeout) seconds"
        case .cancelled:
            return "Task was cancelled"
        case .unknown:
            return "Unknown task error"
        }
    }
}
