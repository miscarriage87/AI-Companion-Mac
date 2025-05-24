
//
//  CalculatorPlugin.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import Expression

/// Plugin for performing calculations
class CalculatorPlugin: PluginProtocol {
    /// Unique identifier for the plugin
    let id = UUID(uuidString: "B2C3D4E5-F6A7-48B9-C0D1-E2F3A4B5C6D7")!
    
    /// Name of the plugin
    let name = "Calculator"
    
    /// Description of what the plugin does
    let description = "Performs mathematical calculations and conversions"
    
    /// Version of the plugin
    let version = "1.0.0"
    
    /// Author of the plugin
    let author = "AI Companion Team"
    
    /// URL for more information about the plugin
    let websiteURL: URL? = URL(string: "https://aicompanion.example.com/plugins/calculator")
    
    /// Icon to display for the plugin
    var icon: Image {
        return Image(systemName: "calculator")
    }
    
    /// Category of the plugin
    let category: PluginCategory = .utilities
    
    /// Tools provided by the plugin
    lazy var tools: [AITool] = [
        AITool(
            name: "calculate_expression",
            description: "Calculate the result of a mathematical expression",
            parameters: [
                AIToolParameter(
                    name: "expression",
                    description: "The mathematical expression to calculate",
                    type: .string,
                    required: true
                )
            ],
            execute: calculateExpression
        ),
        AITool(
            name: "convert_units",
            description: "Convert a value from one unit to another",
            parameters: [
                AIToolParameter(
                    name: "value",
                    description: "The value to convert",
                    type: .number,
                    required: true
                ),
                AIToolParameter(
                    name: "from_unit",
                    description: "The unit to convert from",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "to_unit",
                    description: "The unit to convert to",
                    type: .string,
                    required: true
                )
            ],
            execute: convertUnits
        )
    ]
    
    /// Initialize the plugin
    func initialize() async throws {
        // No initialization needed
    }
    
    /// Clean up resources when the plugin is unloaded
    func cleanup() async {
        // No cleanup needed
    }
    
    /// Calculate the result of a mathematical expression
    private func calculateExpression(parameters: [String: Any]) async throws -> Any {
        guard let expression = parameters["expression"] as? String else {
            throw PluginError.invalidParameters("Expression parameter is required")
        }
        
        do {
            // Use Expression library to evaluate the expression
            let result = try Expression(expression).evaluate()
            return ["result": result]
        } catch {
            throw PluginError.calculationError("Error evaluating expression: \(error.localizedDescription)")
        }
    }
    
    /// Convert a value from one unit to another
    private func convertUnits(parameters: [String: Any]) async throws -> Any {
        // TODO: Implement unit conversion
        return ["result": 0.0, "from_unit": "kg", "to_unit": "lb"]
    }
    
    /// Errors that can occur in the calculator plugin
    enum PluginError: Error, LocalizedError {
        case invalidParameters(String)
        case calculationError(String)
        case conversionError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidParameters(let message):
                return "Invalid parameters: \(message)"
            case .calculationError(let message):
                return "Calculation error: \(message)"
            case .conversionError(let message):
                return "Conversion error: \(message)"
            }
        }
    }
}
