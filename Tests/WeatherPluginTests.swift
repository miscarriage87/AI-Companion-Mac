import XCTest
@testable import AI_Companion

final class WeatherPluginTests: XCTestCase {
    func testCurrentWeatherMock() async throws {
        let plugin = WeatherPlugin(provider: MockWeatherProvider())
        guard let tool = plugin.tools.first(where: { $0.name == "get_current_weather" }) else {
            XCTFail("Tool not found")
            return
        }
        let resultAny = try await tool.execute?(["location": "San Francisco", "units": "celsius"]) as? [String: Any]
        XCTAssertEqual(resultAny?["condition"] as? String, "Partly Cloudy")
        XCTAssertEqual(resultAny?["temperature"] as? Double, 22.0)
    }

    func testWeatherForecastMock() async throws {
        let plugin = WeatherPlugin(provider: MockWeatherProvider())
        guard let tool = plugin.tools.first(where: { $0.name == "get_weather_forecast" }) else {
            XCTFail("Tool not found")
            return
        }
        let resultAny = try await tool.execute?(["location": "San Francisco", "days": 3, "units": "celsius"]) as? [[String: Any]]
        XCTAssertEqual(resultAny?.count, 3)
        XCTAssertEqual(resultAny?[1]["condition"] as? String, "Sunny")
    }
}
