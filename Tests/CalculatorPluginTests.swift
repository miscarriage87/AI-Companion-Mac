//
//  CalculatorPluginTests.swift
//  AI CompanionTests
//
//  Created: May 20, 2025
//

import XCTest
@testable import AI_Companion

class CalculatorPluginTests: XCTestCase {

    private var plugin: CalculatorPlugin!
    private var convertTool: AITool!

    override func setUp() {
        super.setUp()
        plugin = CalculatorPlugin()
        convertTool = plugin.tools.first { $0.name == "convert_units" }
    }

    override func tearDown() {
        plugin = nil
        convertTool = nil
        super.tearDown()
    }

    func testKilogramsToPounds() async throws {
        guard let execute = convertTool.execute else {
            XCTFail("execute closure missing")
            return
        }
        let resultAny = try await execute(["value": 1.0, "from_unit": "kg", "to_unit": "lb"])
        let result = resultAny as? [String: Any]
        let value = result?["result"] as? Double
        XCTAssertNotNil(value)
        XCTAssertEqual(value!, 2.20462, accuracy: 0.001)
    }

    func testMetersToCentimeters() async throws {
        guard let execute = convertTool.execute else {
            XCTFail("execute closure missing")
            return
        }
        let resultAny = try await execute(["value": 2.0, "from_unit": "m", "to_unit": "cm"])
        let value = (resultAny as? [String: Any])?["result"] as? Double
        XCTAssertEqual(value, 200.0, accuracy: 0.001)
    }

    func testInvalidUnitThrows() async {
        guard let execute = convertTool.execute else {
            XCTFail("execute closure missing")
            return
        }
        do {
            _ = try await execute(["value": 1.0, "from_unit": "foo", "to_unit": "bar"])
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertTrue(error is CalculatorPlugin.PluginError)
        }
    }
}
