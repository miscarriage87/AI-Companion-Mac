
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isShowingSignUp = false
    @State private var isShowingResetPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo and title
            Image(systemName: "brain.head.profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            Text("AI Companion")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sign in to your account")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Form fields
            VStack(spacing: 15) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
            }
            
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)
            }
            
            // Success message
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)
            }
            
            // Sign in button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
            
            // Magic link button
            Button(action: {
                Task {
                    await viewModel.signInWithMagicLink()
                }
            }) {
                Text("Sign in with Magic Link")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            .disabled(viewModel.isLoading)
            
            // OAuth buttons
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                        await viewModel.signInWithApple()
                    }
                }) {
                    Image(systemName: "apple.logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    Task {
                        await viewModel.signInWithGoogle()
                    }
                }) {
                    Text("G")
                        .font(.system(size: 20, weight: .bold))
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isLoading)
            }
            
            Spacer()
            
            // Footer links
            HStack {
                Button("Forgot Password?") {
                    isShowingResetPassword = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
                
                Spacer()
                
                Button("Create Account") {
                    isShowingSignUp = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .frame(width: 400, height: 600)
        .sheet(isPresented: $isShowingSignUp) {
            RegisterView()
        }
        .sheet(isPresented: $isShowingResetPassword) {
            ResetPasswordView()
        }
    }
}

struct ResetPasswordView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter your email to receive password reset instructions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                
                .disableAutocorrection(true)
                
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)
            }
            
            // Success message
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)
            }
            
            Button(action: {
                Task {
                    await viewModel.resetPassword()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("Send Reset Instructions")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

#Preview {
    LoginView()
}
