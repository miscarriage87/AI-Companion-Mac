
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
        guard
            let value = parameters["value"] as? Double,
            let fromUnitString = parameters["from_unit"] as? String,
            let toUnitString = parameters["to_unit"] as? String
        else {
            throw PluginError.invalidParameters("value, from_unit and to_unit parameters are required")
        }

        guard let fromUnit = unit(from: fromUnitString),
              let toUnit = unit(from: toUnitString) else {
            throw PluginError.conversionError("Invalid units")
        }

        let resultValue: Double
        if let from = fromUnit as? UnitLength, let to = toUnit as? UnitLength {
            let measurement = Measurement(value: value, unit: from)
            resultValue = measurement.converted(to: to).value
        } else if let from = fromUnit as? UnitMass, let to = toUnit as? UnitMass {
            let measurement = Measurement(value: value, unit: from)
            resultValue = measurement.converted(to: to).value
        } else if let from = fromUnit as? UnitTemperature, let to = toUnit as? UnitTemperature {
            let measurement = Measurement(value: value, unit: from)
            resultValue = measurement.converted(to: to).value
        } else if let from = fromUnit as? UnitVolume, let to = toUnit as? UnitVolume {
            let measurement = Measurement(value: value, unit: from)
            resultValue = measurement.converted(to: to).value
        } else {
            throw PluginError.conversionError("Incompatible unit types")
        }

        return ["result": resultValue, "from_unit": fromUnitString, "to_unit": toUnitString]
    }

    /// Convert a string representation of a unit into a `Unit` type
    private func unit(from string: String) -> Dimension? {
        switch string.lowercased() {
        // Length
        case "m", "meter", "meters":
            return UnitLength.meters
        case "km", "kilometer", "kilometers":
            return UnitLength.kilometers
        case "cm", "centimeter", "centimeters":
            return UnitLength.centimeters
        case "mm", "millimeter", "millimeters":
            return UnitLength.millimeters
        case "ft", "foot", "feet":
            return UnitLength.feet
        case "yd", "yard", "yards":
            return UnitLength.yards
        case "mi", "mile", "miles":
            return UnitLength.miles
        case "in", "inch", "inches":
            return UnitLength.inches

        // Mass
        case "g", "gram", "grams":
            return UnitMass.grams
        case "kg", "kilogram", "kilograms":
            return UnitMass.kilograms
        case "lb", "lbs", "pound", "pounds":
            return UnitMass.pounds
        case "oz", "ounce", "ounces":
            return UnitMass.ounces

        // Volume
        case "l", "liter", "liters":
            return UnitVolume.liters
        case "ml", "milliliter", "milliliters":
            return UnitVolume.milliliters
        case "gal", "gallon", "gallons":
            return UnitVolume.gallons

        // Temperature
        case "c", "celsius", "\u00B0c":
            return UnitTemperature.celsius
        case "f", "fahrenheit", "\u00B0f":
            return UnitTemperature.fahrenheit
        case "k", "kelvin", "\u00B0k":
            return UnitTemperature.kelvin
        default:
            return nil
        }
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
