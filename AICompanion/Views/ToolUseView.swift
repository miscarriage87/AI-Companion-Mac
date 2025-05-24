
//
//  ToolUseView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for displaying tool interactions
struct ToolUseView: View {
    let toolName: String
    let toolDescription: String
    let parameters: [String: Any]
    let result: Any?
    let status: ToolUseStatus
    let timestamp: Date
    
    @State private var isExpanded = false
    @State private var showParameters = false
    @State private var showResult = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tool use header
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: toolIcon)
                        .foregroundColor(.accentColor)
                    
                    Text(toolName)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Status indicator
                    statusView
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Tool description
                    Text(toolDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                    
                    // Timestamp
                    Text("Used at: \(formatTimestamp(timestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                    
                    Divider()
                    
                    // Parameters section
                    DisclosureGroup(
                        isExpanded: $showParameters,
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(parameters.keys.sorted()), id: \.self) { key in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(key)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(formatParameterValue(parameters[key]))
                                            .font(.body)
                                            .padding(8)
                                            .background(Color(NSColor.textBackgroundColor))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .padding(.leading)
                        },
                        label: {
                            HStack {
                                Text("Parameters")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(parameters.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    // Result section
                    DisclosureGroup(
                        isExpanded: $showResult,
                        content: {
                            if let result = result {
                                Text(formatParameterValue(result))
                                    .font(.body)
                                    .padding(8)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(4)
                            } else {
                                Text("No result available")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        },
                        label: {
                            HStack {
                                Text("Result")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                if status == .inProgress {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            }
                        }
                    )
                    .padding(.vertical, 4)
                }
                .padding(.leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.5), lineWidth: 1)
        )
    }
    
    /// Icon for the tool
    private var toolIcon: String {
        switch toolName.lowercased() {
        case "search", "websearch":
            return "magnifyingglass"
        case "calculator":
            return "calculator"
        case "weather":
            return "cloud.sun"
        case "calendar":
            return "calendar"
        case "email":
            return "envelope"
        case "file":
            return "doc"
        case "image":
            return "photo"
        case "map":
            return "map"
        case "music":
            return "music.note"
        case "video":
            return "video"
        case "browser":
            return "safari"
        default:
            return "wrench.and.screwdriver"
        }
    }
    
    /// Status view based on the current status
    private var statusView: some View {
        switch status {
        case .success:
            return AnyView(
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            )
        case .error:
            return AnyView(
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            )
        case .inProgress:
            return AnyView(
                ProgressView()
                    .scaleEffect(0.7)
            )
        case .pending:
            return AnyView(
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            )
        }
    }
    
    /// Color based on the current status
    private var statusColor: Color {
        switch status {
        case .success:
            return .green
        case .error:
            return .red
        case .inProgress:
            return .blue
        case .pending:
            return .orange
        }
    }
    
    /// Format parameter value as string
    private func formatParameterValue(_ value: Any?) -> String {
        guard let value = value else { return "nil" }
        
        if let stringValue = value as? String {
            return stringValue
        } else if let intValue = value as? Int {
            return String(intValue)
        } else if let doubleValue = value as? Double {
            return String(format: "%.2f", doubleValue)
        } else if let boolValue = value as? Bool {
            return boolValue ? "true" : "false"
        } else if let arrayValue = value as? [Any] {
            let elements = arrayValue.map { formatParameterValue($0) }
            return "[\(elements.joined(separator: ", "))]"
        } else if let dictValue = value as? [String: Any] {
            let elements = dictValue.map { key, value in
                "\"\(key)\": \(formatParameterValue(value))"
            }
            return "{\(elements.joined(separator: ", "))}"
        } else {
            return String(describing: value)
        }
    }
    
    /// Format timestamp
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

/// Status of a tool use
enum ToolUseStatus {
    case pending
    case inProgress
    case success
    case error
}

// Preview for SwiftUI canvas
struct ToolUseView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ToolUseView(
                toolName: "WebSearch",
                toolDescription: "Search the web for information",
                parameters: [
                    "query": "latest AI developments",
                    "limit": 5
                ],
                result: [
                    "results": [
                        "AI breakthrough in protein folding",
                        "New language model achieves human-level performance",
                        "AI-powered drug discovery platform launched"
                    ]
                ],
                status: .success,
                timestamp: Date()
            )
            
            ToolUseView(
                toolName: "Calculator",
                toolDescription: "Perform mathematical calculations",
                parameters: [
                    "expression": "sqrt(16) + 5^2"
                ],
                result: nil,
                status: .inProgress,
                timestamp: Date()
            )
            
            ToolUseView(
                toolName: "Weather",
                toolDescription: "Get weather information for a location",
                parameters: [
                    "location": "Invalid Location",
                    "units": "metric"
                ],
                result: "Error: Location not found",
                status: .error,
                timestamp: Date()
            )
        }
        .padding()
    }
}
