
//
//  WeatherPlugin.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import CoreLocation
import WeatherKit

/// Plugin for accessing weather information
class WeatherPlugin: PluginProtocol {
    /// Unique identifier for the plugin
    let id = UUID(uuidString: "A1B2C3D4-E5F6-47A8-B9C0-D1E2F3A4B5C6")!
    
    /// Name of the plugin
    let name = "Weather"
    
    /// Description of what the plugin does
    let description = "Provides access to weather information for locations around the world"
    
    /// Version of the plugin
    let version = "1.0.0"
    
    /// Author of the plugin
    let author = "AI Companion Team"
    
    /// URL for more information about the plugin
    let websiteURL: URL? = URL(string: "https://aicompanion.example.com/plugins/weather")
    
    /// Icon to display for the plugin
    var icon: Image {
        return Image(systemName: "cloud.sun.fill")
    }
    
    /// Category of the plugin
    let category: PluginCategory = .utilities
    
    /// Tools provided by the plugin
    lazy var tools: [AITool] = [
        AITool(
            name: "get_current_weather",
            description: "Get the current weather for a location",
            parameters: [
                AIToolParameter(
                    name: "location",
                    description: "The location to get weather for (city name or latitude,longitude)",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "units",
                    description: "The units to use for temperature (celsius or fahrenheit)",
                    type: .string,
                    required: false,
                    enumValues: ["celsius", "fahrenheit"]
                )
            ],
            execute: getCurrentWeather
        ),
        AITool(
            name: "get_weather_forecast",
            description: "Get the weather forecast for a location",
            parameters: [
                AIToolParameter(
                    name: "location",
                    description: "The location to get weather for (city name or latitude,longitude)",
                    type: .string,
                    required: true
                ),
                AIToolParameter(
                    name: "days",
                    description: "Number of days to forecast (1-7)",
                    type: .number,
                    required: false
                ),
                AIToolParameter(
                    name: "units",
                    description: "The units to use for temperature (celsius or fahrenheit)",
                    type: .string,
                    required: false,
                    enumValues: ["celsius", "fahrenheit"]
                )
            ],
            execute: getWeatherForecast
        )
    ]
    
    /// Location manager for getting coordinates from location names
    private let locationManager = CLLocationManager()
    
    /// Weather service for getting weather data
    private let weatherService = WeatherService.shared
    
    /// Initialize the plugin
    func initialize() async throws {
        // Request location permissions if needed
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Clean up resources when the plugin is unloaded
    func cleanup() async {
        // No cleanup needed
    }
    
    /// Get the current weather for a location
    private func getCurrentWeather(parameters: [String: Any]) async throws -> Any {
        // TODO: Implement weather lookup
        return ["temperature": 22, "condition": "Partly Cloudy", "humidity": 65]
    }
    
    /// Get the weather forecast for a location
    private func getWeatherForecast(parameters: [String: Any]) async throws -> Any {
        // TODO: Implement forecast lookup
        return [
            ["date": "2025-05-20", "temperature": 22, "condition": "Partly Cloudy"],
            ["date": "2025-05-21", "temperature": 24, "condition": "Sunny"],
            ["date": "2025-05-22", "temperature": 20, "condition": "Rain"]
        ]
    }
}
