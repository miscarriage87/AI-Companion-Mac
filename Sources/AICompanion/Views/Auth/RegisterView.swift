
import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Join AI Companion")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Form fields
            VStack(spacing: 15) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
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
            
            // Sign up button
            Button(action: {
                Task {
                    await viewModel.signUp()
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
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
            
            // OAuth buttons
            HStack {
                Text("Or sign up with")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
            
            // Footer
            HStack {
                Text("Already have an account?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Sign In") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .frame(width: 400, height: 600)
    }
}

#Preview {
    RegisterView()
}
