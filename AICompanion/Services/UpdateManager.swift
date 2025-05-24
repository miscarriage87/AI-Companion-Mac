
//
//  UpdateManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import UserNotifications
import AppKit

/// Protocol abstraction for URLSession to allow mocking in tests
protocol URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
}

extension URLSession: URLSessionProtocol {}

/// Manager for handling application updates
class UpdateManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = UpdateManager()
    
    /// Whether an update is available
    @Published var updateAvailable: Bool = false
    
    /// Latest available version
    @Published var latestVersion: String?
    
    /// Current version of the application
    let currentVersion: String
    
    /// Whether to check for updates automatically
    @Published var checkAutomatically: Bool {
        didSet {
            saveCheckAutomatically()
        }
    }
    
    /// URL for the update server
    private let updateServerURL = URL(string: "https://aicompanion.example.com/updates")!

    /// URL session used for network calls (injected for testing)
    private let session: URLSessionProtocol

    /// Download URL for the latest version
    private var downloadURL: URL?
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(currentVersion: String? = nil, session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        // Get current version from bundle
        self.currentVersion = currentVersion ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        // Load user preferences
        checkAutomatically = UserDefaults.standard.bool(forKey: "checkForUpdatesAutomatically")
        
        // Check for updates if enabled
        if checkAutomatically {
            checkForUpdates()
        }
    }
    
    /// Save the check automatically setting to user defaults
    private func saveCheckAutomatically() {
        UserDefaults.standard.set(checkAutomatically, forKey: "checkForUpdatesAutomatically")
    }

    /// Check for updates
    func checkForUpdates() {
        let task = session.dataTask(with: updateServerURL) { [weak self] data, response, error in
            guard let self = self else { return }

            guard error == nil,
                  let data = data,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                return
            }

            struct UpdateInfo: Decodable {
                let version: String
                let downloadURL: URL
            }

            guard let info = try? JSONDecoder().decode(UpdateInfo.self, from: data) else { return }

            let isNewer = self.isNewerVersion(info.version, than: self.currentVersion)

            DispatchQueue.main.async {
                self.latestVersion = info.version
                self.updateAvailable = isNewer
                self.downloadURL = info.downloadURL

                if isNewer {
                    self.notifyUserAboutUpdate(version: info.version)
                }
            }
        }

        task.resume()
    }

    /// Download and install the update
    func downloadAndInstallUpdate() {
        guard let downloadURL else { return }

        let task = session.downloadTask(with: downloadURL) { url, response, error in
            guard let tempURL = url, error == nil else { return }

            // Move downloaded file to a permanent location
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent(downloadURL.lastPathComponent)
            try? FileManager.default.removeItem(at: destination)
            do {
                try FileManager.default.moveItem(at: tempURL, to: destination)
                DispatchQueue.main.async {
                    NSWorkspace.shared.open(destination)
                }
            } catch {
                // Handle move error silently
            }
        }

        task.resume()
    }

    /// Compare semantic versions (e.g., 1.2.3)
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        for (new, old) in zip(newParts, currentParts) {
            if new > old { return true }
            if new < old { return false }
        }
        return newParts.count > currentParts.count && newParts.dropFirst(currentParts.count).contains { $0 > 0 }
    }

    /// Notify the user that an update is available
    private func notifyUserAboutUpdate(version: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Update Available"
            content.body = "Version \(version) is available to download."
            let request = UNNotificationRequest(identifier: "AICompanionUpdate", content: content, trigger: nil)
            center.add(request, withCompletionHandler: nil)
        }
    }
}
