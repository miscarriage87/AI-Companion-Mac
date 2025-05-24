
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

/// Data model for a single weather point
struct WeatherInfo {
    let date: Date
    let temperature: Double
    let condition: String
    let humidity: Int?
}

/// Protocol describing a weather provider
protocol WeatherProviding {
    func fetchCurrentWeather(for location: CLLocation, units: UnitTemperature) async throws -> WeatherInfo
    func fetchWeatherForecast(for location: CLLocation, days: Int, units: UnitTemperature) async throws -> [WeatherInfo]
}

/// Mock provider used for offline testing
struct MockWeatherProvider: WeatherProviding {
    func fetchCurrentWeather(for location: CLLocation, units: UnitTemperature) async throws -> WeatherInfo {
        let temp = units == .celsius ? 22.0 : 71.6
        return WeatherInfo(date: Date(), temperature: temp, condition: "Partly Cloudy", humidity: 65)
    }

    func fetchWeatherForecast(for location: CLLocation, days: Int, units: UnitTemperature) async throws -> [WeatherInfo] {
        let baseTempsC: [Double] = [22, 24, 20]
        let conditions = ["Partly Cloudy", "Sunny", "Rain"]
        var results: [WeatherInfo] = []
        for i in 0..<min(days, baseTempsC.count) {
            let temp = units == .celsius ? baseTempsC[i] : baseTempsC[i] * 9 / 5 + 32
            let date = Calendar.current.date(byAdding: .day, value: i + 1, to: Date()) ?? Date()
            results.append(WeatherInfo(date: date, temperature: temp, condition: conditions[i], humidity: nil))
        }
        return results
    }
}

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

    /// API key if required by the provider
    private let apiKey: String?

    /// Provider used to fetch weather data
    private let weatherProvider: WeatherProviding
    
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

    /// Create a plugin with a specific provider or API key
    init(apiKey: String? = nil, provider: WeatherProviding? = nil) {
        self.apiKey = apiKey
        self.weatherProvider = provider ?? MockWeatherProvider()
    }
    
    /// Location manager for getting coordinates from location names
    private let locationManager = CLLocationManager()

    /// Convert a location string to coordinates. Supports "lat,lon" or common city names.
    private func parseLocation(_ string: String) -> CLLocation {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ",")
        if parts.count == 2,
           let lat = Double(parts[0]),
           let lon = Double(parts[1]) {
            return CLLocation(latitude: lat, longitude: lon)
        }
        switch trimmed.lowercased() {
        case "san francisco":
            return CLLocation(latitude: 37.7749, longitude: -122.4194)
        case "new york":
            return CLLocation(latitude: 40.7128, longitude: -74.0060)
        default:
            return CLLocation(latitude: 0, longitude: 0)
        }
    }
    
    
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
        guard let locationStr = parameters["location"] as? String else {
            throw PluginError.executionFailed("Missing location parameter")
        }
        let unitsStr = (parameters["units"] as? String)?.lowercased()
        let units: UnitTemperature = unitsStr == "fahrenheit" ? .fahrenheit : .celsius

        let location = parseLocation(locationStr)
        let info = try await weatherProvider.fetchCurrentWeather(for: location, units: units)

        return [
            "temperature": info.temperature,
            "condition": info.condition,
            "humidity": info.humidity ?? 0
        ]
    }

    /// Get the weather forecast for a location
    private func getWeatherForecast(parameters: [String: Any]) async throws -> Any {
        guard let locationStr = parameters["location"] as? String else {
            throw PluginError.executionFailed("Missing location parameter")
        }
        let days = parameters["days"] as? Int ?? 3
        let unitsStr = (parameters["units"] as? String)?.lowercased()
        let units: UnitTemperature = unitsStr == "fahrenheit" ? .fahrenheit : .celsius

        let location = parseLocation(locationStr)
        let forecast = try await weatherProvider.fetchWeatherForecast(for: location, days: days, units: units)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return forecast.map { info in
            [
                "date": formatter.string(from: info.date),
                "temperature": info.temperature,
                "condition": info.condition
            ]
        }
    }
}
