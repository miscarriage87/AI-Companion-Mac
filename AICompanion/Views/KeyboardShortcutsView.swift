
//
//  KeyboardShortcutsView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for displaying keyboard shortcuts
struct KeyboardShortcutsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Keyboard Shortcuts".localized)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Close keyboard shortcuts")
            }
            .padding()
            
            Divider()
            
            // Shortcuts list
            ScrollView {
                VStack(spacing: 20) {
                    ShortcutSection(
                        title: "General".localized,
                        shortcuts: [
                            Shortcut(name: "New Chat".localized, keys: "⌘N"),
                            Shortcut(name: "Settings".localized, keys: "⌘,"),
                            Shortcut(name: "Toggle Sidebar".localized, keys: "⇧⌘S"),
                            Shortcut(name: "Search".localized, keys: "⌘F")
                        ]
                    )
                    
                    ShortcutSection(
                        title: "Chat".localized,
                        shortcuts: [
                            Shortcut(name: "Send Message".localized, keys: "⌘↩"),
                            Shortcut(name: "Stop Generation".localized, keys: "Esc"),
                            Shortcut(name: "Regenerate Response".localized, keys: "⇧⌘R"),
                            Shortcut(name: "Clear Chat".localized, keys: "⇧⌘K"),
                            Shortcut(name: "Export Chat".localized, keys: "⇧⌘E")
                        ]
                    )
                    
                    ShortcutSection(
                        title: "Voice".localized,
                        shortcuts: [
                            Shortcut(name: "Start Voice Input".localized, keys: "⌘M"),
                            Shortcut(name: "Stop Voice Input".localized, keys: "⌘.")
                        ]
                    )
                    
                    ShortcutSection(
                        title: "Documents".localized,
                        shortcuts: [
                            Shortcut(name: "Import Document".localized, keys: "⌘I"),
                            Shortcut(name: "Export Document".localized, keys: "⇧⌘D")
                        ]
                    )
                    
                    ShortcutSection(
                        title: "Plugins".localized,
                        shortcuts: [
                            Shortcut(name: "Import Plugin".localized, keys: "⇧⌘I"),
                            Shortcut(name: "Manage Plugins".localized, keys: "⌥⌘P")
                        ]
                    )
                    
                    ShortcutSection(
                        title: "Editing".localized,
                        shortcuts: [
                            Shortcut(name: "Copy".localized, keys: "⌘C"),
                            Shortcut(name: "Paste".localized, keys: "⌘V"),
                            Shortcut(name: "Select All".localized, keys: "⌘A"),
                            Shortcut(name: "Undo".localized, keys: "⌘Z"),
                            Shortcut(name: "Redo".localized, keys: "⇧⌘Z")
                        ]
                    )
                    
                    ShortcutSection(
                        title: "View".localized,
                        shortcuts: [
                            Shortcut(name: "Increase Font Size".localized, keys: "⌘+"),
                            Shortcut(name: "Decrease Font Size".localized, keys: "⌘-"),
                            Shortcut(name: "Reset Font Size".localized, keys: "⌘0")
                        ]
                    )
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// Section of keyboard shortcuts
struct ShortcutSection: View {
    let title: String
    let shortcuts: [Shortcut]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Divider()
            
            ForEach(shortcuts) { shortcut in
                HStack {
                    Text(shortcut.name)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(shortcut.keys)
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

/// Represents a keyboard shortcut
struct Shortcut: Identifiable {
    let id = UUID()
    let name: String
    let keys: String
}

// Preview for SwiftUI canvas
struct KeyboardShortcutsView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutsView()
    }
}
