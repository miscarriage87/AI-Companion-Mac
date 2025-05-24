//
//  UpdateManagerTests.swift
//  AI CompanionTests
//
//  Created: May 21, 2025
//

import XCTest
@testable import AI_Companion

private class MockDataTask: URLSessionDataTask {
    let onResume: () -> Void
    init(onResume: @escaping () -> Void) { self.onResume = onResume }
    override func resume() { onResume() }
}

private class MockDownloadTask: URLSessionDownloadTask {
    let onResume: () -> Void
    init(onResume: @escaping () -> Void) { self.onResume = onResume }
    override func resume() { onResume() }
}

private class MockURLSession: URLSessionProtocol {
    var data: Data?
    var downloadFileURL: URL?

    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return MockDataTask {
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            completionHandler(self.data, response, nil)
        }
    }

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return MockDownloadTask {
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            completionHandler(self.downloadFileURL, response, nil)
        }
    }
}

class UpdateManagerTests: XCTestCase {
    func testCheckForUpdatesWithNewVersion() {
        let mockSession = MockURLSession()
        let json = "{" + "\"version\":\"2.0.0\"," + "\"downloadURL\":\"https://example.com/app.dmg\"}"
        mockSession.data = json.data(using: .utf8)

        let manager = UpdateManager(currentVersion: "1.0.0", session: mockSession)
        manager.checkForUpdates()

        XCTAssertTrue(manager.updateAvailable)
        XCTAssertEqual(manager.latestVersion, "2.0.0")
    }

    func testCheckForUpdatesWhenUpToDate() {
        let mockSession = MockURLSession()
        let json = "{" + "\"version\":\"1.0.0\"," + "\"downloadURL\":\"https://example.com/app.dmg\"}"
        mockSession.data = json.data(using: .utf8)

        let manager = UpdateManager(currentVersion: "1.0.0", session: mockSession)
        manager.checkForUpdates()

        XCTAssertFalse(manager.updateAvailable)
    }

    func testDownloadAndInstallUpdateMovesFile() {
        let mockSession = MockURLSession()
        let json = "{" + "\"version\":\"2.0.0\"," + "\"downloadURL\":\"https://example.com/app.dmg\"}"
        mockSession.data = json.data(using: .utf8)

        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test.dmg")
        FileManager.default.createFile(atPath: tempFile.path, contents: Data("123".utf8), attributes: nil)
        mockSession.downloadFileURL = tempFile

        let manager = UpdateManager(currentVersion: "1.0.0", session: mockSession)
        manager.checkForUpdates()
        manager.downloadAndInstallUpdate()

        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("app.dmg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        try? FileManager.default.removeItem(at: destination)
    }
}
