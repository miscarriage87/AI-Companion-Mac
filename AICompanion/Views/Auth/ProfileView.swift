//
//  ProfileView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isEditingProfile = false
    @State private var isShowingImagePicker = false
    @State private var selectedImage: NSImage?
    
    var body: some View {
        VStack {
            // Profile header
            VStack(spacing: 20) {
                // Profile picture
                ZStack(alignment: .bottomTrailing) {
                    if let avatarURL = viewModel.profile?.avatarURL, !avatarURL.isEmpty {
                        AsyncImage(url: URL(string: avatarURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 3)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    
                    if isEditingProfile {
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .background(Color.white)
                                .clipShape(Circle())
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                // User info
                if isEditingProfile {
                    TextField("Display Name", text: $viewModel.displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 300)
                } else {
                    Text(viewModel.profile?.displayName ?? "No Name")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                if let email = AuthService.shared.session?.user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            // Bio section
            VStack(alignment: .leading, spacing: 10) {
                Text("Bio")
                    .font(.headline)
                
                if isEditingProfile {
                    TextEditor(text: $viewModel.bio)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    Text(viewModel.profile?.bio ?? "No bio available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            .padding()
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Success message
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                if isEditingProfile {
                    Button("Cancel") {
                        isEditingProfile = false
                        // Reset to original values
                        viewModel.displayName = viewModel.profile?.displayName ?? ""
                        viewModel.bio = viewModel.profile?.bio ?? ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        Task {
                            await viewModel.updateProfile()
                            isEditingProfile = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Edit Profile") {
                        isEditingProfile = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Sign Out") {
                        Task {
                            await AuthViewModel().signOut()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            Task {
                await viewModel.fetchUserProfile()
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePickerView(selectedImage: $selectedImage)
                .onDisappear {
                    if let selectedImage = selectedImage,
                       let imageData = selectedImage.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: imageData),
                       let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) {
                        Task {
                            await viewModel.uploadProfilePicture(imageData: jpegData)
                        }
                    }
                }
        }
    }
}

// Image picker for macOS
struct ImagePickerView: NSViewRepresentable {
    @Binding var selectedImage: NSImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        panel.beginSheetModal(for: NSApplication.shared.mainWindow!) { response in
            if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                selectedImage = image
            }
            presentationMode.wrappedValue.dismiss()
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
