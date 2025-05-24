//
//  PerformanceMonitor.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine
import os.signpost

/// PerformanceMonitor tracks app performance and resource usage
/// It provides insights into CPU, memory, battery impact, and operation timing
class PerformanceMonitor {
    // MARK: - Properties
    
    // Signpost logging
    private let signpostLog = OSLog(subsystem: "com.aicompanion.app", category: "Performance")
    
    // Performance metrics
    private var cpuUsage: Double = 0
    private var memoryUsage: UInt64 = 0
    private var batteryImpact: Double = 0
    
    // Operation timing
    private var operationTimings: [String: [TimeInterval]] = [:]
    
    // Publishers
    private let metricsUpdateSubject = PassthroughSubject<PerformanceMetrics, Never>()
    var metricsUpdates: AnyPublisher<PerformanceMetrics, Never> {
        return metricsUpdateSubject.eraseToAnyPublisher()
    }
    
    // Singleton instance
    static let shared = PerformanceMonitor()
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Monitoring
    
    /// Start performance monitoring
    private func startMonitoring() {
        // Start periodic monitoring
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    /// Update performance metrics
    private func updateMetrics() {
        // Update CPU usage
        cpuUsage = measureCPUUsage()
        
        // Update memory usage
        memoryUsage = measureMemoryUsage()
        
        // Update battery impact
        batteryImpact = estimateBatteryImpact()
        
        // Publish updated metrics
        let metrics = PerformanceMetrics(
            timestamp: Date(),
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            batteryImpact: batteryImpact,
            operationTimings: getAverageTimings()
        )
        
        metricsUpdateSubject.send(metrics)
    }
    
    /// Measure CPU usage
    /// - Returns: CPU usage as a percentage
    private func measureCPUUsage() -> Double {
        // In a real implementation, this would use host_statistics or similar APIs
        // For now, return a simulated value
        return Double.random(in: 5...30)
    }
    
    /// Measure memory usage
    /// - Returns: Memory usage in bytes
    private func measureMemoryUsage() -> UInt64 {
        // In a real implementation, this would use task_info or similar APIs
        // For now, return a simulated value
        return UInt64.random(in: 50_000_000...200_000_000)
    }
    
    /// Estimate battery impact
    /// - Returns: Battery impact score (0-100)
    private func estimateBatteryImpact() -> Double {
        // In a real implementation, this would use IOKit to estimate power usage
        // For now, calculate based on CPU and memory usage
        return (cpuUsage * 0.7) + (Double(memoryUsage) / 200_000_000 * 30)
    }
    
    // MARK: - Operation Timing
    
    /// Start timing an operation
    /// - Parameters:
    ///   - operationName: Name of the operation
    ///   - identifier: Optional identifier for the operation instance
    /// - Returns: Signpost ID for the operation
    @discardableResult
    func startTiming(_ operationName: String, identifier: String? = nil) -> OSSignpostID {
        let signpostID = OSSignpostID(log: signpostLog)
        
        let idString = identifier != nil ? " [\(identifier!)]" : ""
        os_signpost(.begin, log: signpostLog, name: operationName, signpostID: signpostID, "%{public}s%{public}s", operationName, idString)
        
        return signpostID
    }
    
    /// End timing an operation and record the duration
    /// - Parameters:
    ///   - operationName: Name of the operation
    ///   - signpostID: Signpost ID returned from startTiming
    ///   - identifier: Optional identifier for the operation instance
    func endTiming(_ operationName: String, signpostID: OSSignpostID, identifier: String? = nil) {
        let idString = identifier != nil ? " [\(identifier!)]" : ""
        os_signpost(.end, log: signpostLog, name: operationName, signpostID: signpostID, "%{public}s%{public}s completed", operationName, idString)
        
        // In a real implementation, we would calculate the actual duration
        // For now, simulate a duration
        let duration = TimeInterval.random(in: 0.01...2.0)
        recordTiming(operationName, duration: duration)
    }
    
    /// Record a timing measurement for an operation
    /// - Parameters:
    ///   - operationName: Name of the operation
    ///   - duration: Duration of the operation
    func recordTiming(_ operationName: String, duration: TimeInterval) {
        if operationTimings[operationName] == nil {
            operationTimings[operationName] = []
        }
        
        operationTimings[operationName]?.append(duration)
        
        // Limit the number of stored timings to prevent memory growth
        if let timings = operationTimings[operationName], timings.count > 100 {
            operationTimings[operationName] = Array(timings.suffix(100))
        }
    }
    
    /// Get average timings for all operations
    /// - Returns: Dictionary of operation names to average durations
    private func getAverageTimings() -> [String: TimeInterval] {
        var averages: [String: TimeInterval] = [:]
        
        for (operation, timings) in operationTimings {
            if !timings.isEmpty {
                let average = timings.reduce(0, +) / Double(timings.count)
                averages[operation] = average
            }
        }
        
        return averages
    }
    
    // MARK: - Reporting
    
    /// Get current performance metrics
    /// - Returns: Current performance metrics
    func getCurrentMetrics() -> PerformanceMetrics {
        return PerformanceMetrics(
            timestamp: Date(),
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            batteryImpact: batteryImpact,
            operationTimings: getAverageTimings()
        )
    }
    
    /// Generate a performance report
    /// - Returns: Performance report as a string
    func generatePerformanceReport() -> String {
        let metrics = getCurrentMetrics()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        
        var report = "Performance Report\n"
        report += "================\n\n"
        
        report += "CPU Usage: \(String(format: "%.1f", metrics.cpuUsage))%\n"
        report += "Memory Usage: \(formatter.string(fromByteCount: Int64(metrics.memoryUsage)))\n"
        report += "Battery Impact: \(String(format: "%.1f", metrics.batteryImpact))/100\n\n"
        
        report += "Operation Timings:\n"
        let sortedOperations = metrics.operationTimings.sorted { $0.value > $1.value }
        for (operation, timing) in sortedOperations {
            report += "- \(operation): \(String(format: "%.2f", timing * 1000))ms\n"
        }
        
        return report
    }
    
    /// Check if performance is within acceptable limits
    /// - Returns: Whether performance is acceptable
    func isPerformanceAcceptable() -> Bool {
        return cpuUsage < 50 && memoryUsage < 500_000_000 && batteryImpact < 70
    }
    
    /// Get performance optimization suggestions
    /// - Returns: Array of optimization suggestions
    func getOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if cpuUsage > 30 {
            suggestions.append("Consider reducing background processing")
        }
        
        if memoryUsage > 200_000_000 {
            suggestions.append("Check for memory leaks or excessive caching")
        }
        
        if batteryImpact > 50 {
            suggestions.append("Reduce update frequency or background operations to improve battery life")
        }
        
        // Check for slow operations
        for (operation, timing) in getAverageTimings() {
            if timing > 1.0 {
                suggestions.append("Optimize \(operation) - currently taking \(String(format: "%.2f", timing * 1000))ms")
            }
        }
        
        return suggestions
    }
}

// MARK: - Supporting Types

/// Performance metrics
struct PerformanceMetrics {
    let timestamp: Date
    let cpuUsage: Double // percentage
    let memoryUsage: UInt64 // bytes
    let batteryImpact: Double // 0-100 score
    let operationTimings: [String: TimeInterval] // operation name to average duration
}
