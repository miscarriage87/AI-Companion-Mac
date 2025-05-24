
//
//  FunctionCallView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for displaying function calls
struct FunctionCallView: View {
    let functionName: String
    let parameters: [String: Any]
    let result: Any?
    let status: FunctionCallStatus
    
    @State private var isExpanded = false
    @State private var showParameters = false
    @State private var showResult = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Function call header
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "function")
                        .foregroundColor(.accentColor)
                    
                    Text(functionName)
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
}

/// Status of a function call
enum FunctionCallStatus {
    case pending
    case inProgress
    case success
    case error
}

// Preview for SwiftUI canvas
struct FunctionCallView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            FunctionCallView(
                functionName: "getWeather",
                parameters: [
                    "location": "San Francisco",
                    "units": "metric"
                ],
                result: [
                    "temperature": 18.5,
                    "conditions": "Partly Cloudy",
                    "humidity": 65
                ],
                status: .success
            )
            
            FunctionCallView(
                functionName: "calculateMortgage",
                parameters: [
                    "principal": 300000,
                    "interestRate": 3.5,
                    "years": 30
                ],
                result: nil,
                status: .inProgress
            )
            
            FunctionCallView(
                functionName: "searchDatabase",
                parameters: [
                    "query": "machine learning",
                    "limit": 10
                ],
                result: "Error: Database connection failed",
                status: .error
            )
        }
        .padding()
    }
}
