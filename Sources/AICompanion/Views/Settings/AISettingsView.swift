
import SwiftUI
import KeychainAccess

struct AISettingsView: View {
    @StateObject private var viewModel = AISettingsViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Configuration")) {
                SecureField("OpenAI API Key", text: $viewModel.openAIKey)
                
                Button("Save OpenAI API Key") {
                    viewModel.saveOpenAIKey()
                }
                .disabled(viewModel.openAIKey.isEmpty)
            }
            
            Section(header: Text("Anthropic Configuration")) {
                SecureField("Anthropic API Key", text: $viewModel.anthropicKey)
                
                Button("Save Anthropic API Key") {
                    viewModel.saveAnthropicKey()
                }
                .disabled(viewModel.anthropicKey.isEmpty)
            }
            
            Section(header: Text("Default Settings")) {
                Picker("Default Provider", selection: $viewModel.defaultProvider) {
                    ForEach(AIProviderType.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                
                Picker("Default Model", selection: $viewModel.defaultModel) {
                    ForEach(viewModel.availableModels) { model in
                        Text(model.name).tag(model.id)
                    }
                }
                
                Button("Save Default Settings") {
                    viewModel.saveDefaultSettings()
                }
            }
            
            if let message = viewModel.message {
                Section {
                    Text(message)
                        .foregroundColor(viewModel.isError ? .red : .green)
                }
            }
        }
        .padding()
    }
}

class AISettingsViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var openAIKey = ""
    @Published var anthropicKey = ""
    @Published var defaultProvider: AIProviderType = .openAI
    @Published var defaultModel = ""
    @Published var availableModels: [AIModel] = []
    
    @Published var message: String?
    @Published var isError = false
    
    private let keychain = KeychainAccess.Keychain(service: "com.aicompanion.settings")
    private let aiService = AIService.shared
    
    // MARK: - Initialization
    
    init() {
        // Load API keys from keychain
        loadAPIKeys()
        
        // Load available models
        availableModels = aiService.getAvailableModels()
        
        // Set default model
        defaultModel = aiService.getDefaultModel().id
        
        // Load default settings
        loadDefaultSettings()
    }
    
    // MARK: - API Key Management
    
    func saveOpenAIKey() {
        do {
            try keychain.set(openAIKey, key: "openai_api_key")
            message = "OpenAI API key saved successfully"
            isError = false
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.message = nil
            }
        } catch {
            message = "Failed to save OpenAI API key: \(error.localizedDescription)"
            isError = true
        }
    }
    
    func saveAnthropicKey() {
        do {
            try keychain.set(anthropicKey, key: "anthropic_api_key")
            message = "Anthropic API key saved successfully"
            isError = false
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.message = nil
            }
        } catch {
            message = "Failed to save Anthropic API key: \(error.localizedDescription)"
            isError = true
        }
    }
    
    func loadAPIKeys() {
        do {
            if let savedOpenAIKey = try keychain.get("openai_api_key") {
                openAIKey = savedOpenAIKey
            }
            
            if let savedAnthropicKey = try keychain.get("anthropic_api_key") {
                anthropicKey = savedAnthropicKey
            }
        } catch {
            print("Failed to load API keys: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Default Settings
    
    func saveDefaultSettings() {
        do {
            // Save default provider
            UserDefaults.standard.set(defaultProvider.rawValue, forKey: "default_provider")
            
            // Save default model
            UserDefaults.standard.set(defaultModel, forKey: "default_model")
            
            message = "Default settings saved successfully"
            isError = false
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.message = nil
            }
        } catch {
            message = "Failed to save default settings: \(error.localizedDescription)"
            isError = true
        }
    }
    
    func loadDefaultSettings() {
        // Load default provider
        if let providerString = UserDefaults.standard.string(forKey: "default_provider"),
           let provider = AIProviderType(rawValue: providerString) {
            defaultProvider = provider
        }
        
        // Load default model
        if let modelID = UserDefaults.standard.string(forKey: "default_model") {
            defaultModel = modelID
        }
    }
}

#Preview {
    AISettingsView()
}
