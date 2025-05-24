
import SwiftUI

struct MainView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Group {
            switch authService.authState {
            case .initializing:
                ProgressView("Initializing...")
                    .progressViewStyle(CircularProgressViewStyle())
            case .loading:
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            case .signedIn:
                ContentView()
            case .signedOut, .error:
                LoginView()
            case .confirmationRequired:
                ConfirmationRequiredView()
            case .magicLinkSent:
                MagicLinkSentView()
            case .passwordRecovery:
                PasswordRecoveryView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onOpenURL { url in
            Task {
                await authService.processDeepLink(url: url)
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}

// ChatView is now implemented in a separate file

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        TabView {
            // General Settings
            Form {
                Section(header: Text("API Configuration")) {
                    SecureField("API Key", text: $viewModel.apiKey)
                    Button("Save API Key") {
                        viewModel.saveAPIKey()
                    }
                    .disabled(viewModel.apiKey.isEmpty)
                }
                
                if let message = viewModel.message {
                    Text(message)
                        .foregroundColor(viewModel.isError ? .red : .green)
                        .padding()
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // AI Settings
            AISettingsView()
                .tabItem {
                    Label("AI Providers", systemImage: "brain")
                }
            
            // Voice Settings
            VoiceSettingsView()
                .tabItem {
                    Label("Voice", systemImage: "waveform")
                }
        }
        .padding()
    }
}

struct ConfirmationRequiredView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("Confirmation Required")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("We've sent a confirmation email to your address. Please check your inbox and follow the instructions to activate your account.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Back to Login") {
                Task {
                    try? await AuthService.shared.signOut()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
        .frame(maxWidth: 500)
    }
}

struct MagicLinkSentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("Magic Link Sent")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("We've sent a magic link to your email address. Please check your inbox and click the link to sign in.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Back to Login") {
                Task {
                    try? await AuthService.shared.signOut()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
        .frame(maxWidth: 500)
    }
}

struct PasswordRecoveryView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.rotation")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("Reset Your Password")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please enter a new password for your account.")
                .multilineTextAlignment(.center)
                .padding()
            
            SecureField("New Password", text: $newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                updatePassword()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Update Password")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
            .padding()
        }
        .padding()
        .frame(maxWidth: 500)
    }
    
    private func updatePassword() {
        guard !newPassword.isEmpty else {
            errorMessage = "Password cannot be empty"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await AuthService.shared.updatePassword(newPassword: newPassword)
                // Password updated successfully, sign out to return to login screen
                try await AuthService.shared.signOut()
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    MainView()
}
