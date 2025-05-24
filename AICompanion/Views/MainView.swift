
//
//  MainView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// Main container view for the application
struct MainView: View {
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var sidebarViewModel: SidebarViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @StateObject private var authService = AuthService.shared
    
    @State private var showSettings = false
    @State private var showProfile = false
    @State private var sidebarWidth: CGFloat = 280
    
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
                authenticatedView
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
    
    private var authenticatedView: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView()
                .frame(minWidth: 250, idealWidth: sidebarWidth)
        } detail: {
            // Main content area
            ChatView()
                .frame(minWidth: 500)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, idealWidth: 1200, minHeight: 600, idealHeight: 800)
        .position(x: NSScreen.main?.visibleFrame.width ?? 1200 / 2, 
                 y: NSScreen.main?.visibleFrame.height ?? 800 / 2)
        .toolbar {
            // Left toolbar items
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    sidebarViewModel.toggleSidebar()
                }) {
                    Image(systemName: "sidebar.left")
                        .help("Toggle Sidebar")
                }
            }
            
            // Center toolbar items
            ToolbarItemGroup(placement: .principal) {
                if let conversation = chatViewModel.currentConversation {
                    Text(conversation.title)
                        .font(.headline)
                }
            }
            
            // Right toolbar items
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    chatViewModel.startNewChat()
                }) {
                    Image(systemName: "square.and.pencil")
                        .help("New Chat")
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button(action: {
                    if let conversation = chatViewModel.currentConversation {
                        chatViewModel.exportChat()
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .help("Export Chat")
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(chatViewModel.currentConversation == nil || chatViewModel.messages.isEmpty)
                
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                        .help("Settings")
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button(action: {
                    showProfile = true
                }) {
                    Image(systemName: "person.circle")
                        .help("Profile")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(width: 700, height: 500)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .frame(width: 500, height: 600)
        }
        .onAppear {
            // Set initial window position to center of screen
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                if let window = NSApplication.shared.windows.first {
                    window.setFrame(NSRect(x: screenRect.midX - 600, y: screenRect.midY - 400, width: 1200, height: 800), display: true)
                }
            }
        }
        .handlesExternalEvents(preferring: Set(arrayLiteral: "aicompanion"), allowing: Set(arrayLiteral: "*"))
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(ChatViewModel())
            .environmentObject(SidebarViewModel())
            .environmentObject(SettingsViewModel())
    }
}
