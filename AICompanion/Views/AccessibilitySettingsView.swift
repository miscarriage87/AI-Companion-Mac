
//
//  AccessibilitySettingsView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for accessibility settings
struct AccessibilitySettingsView: View {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @State private var showingHelp = false
    
    var body: some View {
        Form {
            Section(header: Text("Text Size".localized)) {
                Toggle("Larger Text".localized, isOn: $accessibilityManager.useLargerText)
                    .accessibilityLabel("Enable larger text for better readability")
                
                VStack(alignment: .leading) {
                    Text("Font Size Multiplier".localized)
                        .font(.headline)
                    
                    HStack {
                        Text("A")
                            .font(.system(size: 12))
                        
                        Slider(value: $accessibilityManager.fontSizeMultiplier, in: 0.8...2.0, step: 0.1)
                            .accessibilityLabel("Adjust font size multiplier")
                            .accessibilityValue("\(Int(accessibilityManager.fontSizeMultiplier * 100))%")
                        
                        Text("A")
                            .font(.system(size: 24))
                    }
                    
                    Text("Current multiplier: \(Int(accessibilityManager.fontSizeMultiplier * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Preview text with current settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview".localized)
                        .font(.headline)
                    
                    Text("This is how text will appear throughout the app.")
                        .font(.system(size: accessibilityManager.adjustedFontSize(14)))
                }
                .padding()
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
            }
            
            Section(header: Text("Display".localized)) {
                Toggle("High Contrast".localized, isOn: $accessibilityManager.useHighContrast)
                    .accessibilityLabel("Enable high contrast mode for better visibility")
                
                Toggle("Reduce Motion".localized, isOn: $accessibilityManager.reduceMotion)
                    .accessibilityLabel("Reduce animations and motion effects")
                
                Toggle("Reduce Transparency".localized, isOn: $accessibilityManager.reduceTransparency)
                    .accessibilityLabel("Reduce transparency effects for better visibility")
            }
            
            Section(header: Text("VoiceOver".localized)) {
                Toggle("Enhanced VoiceOver Descriptions".localized, isOn: $accessibilityManager.enableVoiceOverDescriptions)
                    .accessibilityLabel("Enable more detailed descriptions for VoiceOver")
                
                Text("When enabled, more detailed descriptions will be provided for VoiceOver users.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: {
                    showingHelp = true
                }) {
                    Label("Accessibility Help".localized, systemImage: "questionmark.circle")
                }
                .accessibilityLabel("Get help with accessibility features")
            }
        }
        .padding()
        .sheet(isPresented: $showingHelp) {
            AccessibilityHelpView()
        }
    }
}

/// Help view for accessibility features
struct AccessibilityHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Accessibility Help".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Close help")
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Text Size Options".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("The Larger Text option increases the size of text throughout the app. The Font Size Multiplier allows you to fine-tune the text size to your preference.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Display Options".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("High Contrast mode increases the contrast between text and backgrounds. Reduce Motion minimizes animations. Reduce Transparency makes backgrounds more solid.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("VoiceOver Support".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enhanced VoiceOver Descriptions provides more detailed descriptions for VoiceOver users. The app is fully compatible with VoiceOver navigation and reading.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Group {
                        Text("Keyboard Navigation".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("You can navigate the app using keyboard shortcuts. Press Tab to move between controls, and use arrow keys to navigate lists. Press Space or Return to activate buttons.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("System Accessibility".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("AI Companion also respects your macOS system accessibility settings. You can configure additional accessibility features in System Preferences > Accessibility.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess")!)
                        }) {
                            Text("Open System Accessibility Settings".localized)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 600, height: 700)
    }
}

// Preview for SwiftUI canvas
struct AccessibilitySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilitySettingsView()
    }
}
