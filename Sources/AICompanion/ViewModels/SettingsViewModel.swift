
import Foundation
import Combine
import KeychainAccess

class SettingsViewModel: ObservableObject {
    // MARK: - Properties
    
    /// API key input
    @Published var apiKey = ""
    
    /// Status message
    @Published var message: String?
    
    /// Error state
    @Published var isError = false
    
    /// Keychain for secure storage
    private let keychain = Keychain(service: "com.aicompanion.settings")
    
    // MARK: - Initialization
    
    init() {
        // Load API key from keychain
        loadAPIKey()
    }
    
    // MARK: - Public Methods
    
    /// Save API key to keychain
    func saveAPIKey() {
        do {
            try keychain.set(apiKey, key: "apiKey")
            message = "API key saved successfully"
            isError = false
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.message = nil
            }
        } catch {
            message = "Failed to save API key: \(error.localizedDescription)"
            isError = true
        }
    }
    
    /// Load API key from keychain
    func loadAPIKey() {
        do {
            if let savedAPIKey = try keychain.get("apiKey") {
                apiKey = savedAPIKey
            }
        } catch {
            print("Failed to load API key: \(error.localizedDescription)")
        }
    }
    
    /// Delete API key from keychain
    func deleteAPIKey() {
        do {
            try keychain.remove("apiKey")
            apiKey = ""
            message = "API key removed successfully"
            isError = false
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.message = nil
            }
        } catch {
            message = "Failed to remove API key: \(error.localizedDescription)"
            isError = true
        }
    }
}
