
//
//  PluginView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for managing and interacting with plugins
struct PluginView: View {
    @EnvironmentObject private var pluginManager: PluginManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var searchText = ""
    @State private var selectedPlugin: Plugin?
    @State private var showPluginDetails = false
    @State private var isImportingPlugin = false
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search plugins", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            
            Divider()
            
            // Plugin list
            List {
                Section(header: Text("Enabled Plugins")) {
                    ForEach(filteredEnabledPlugins) { plugin in
                        PluginRowView(plugin: plugin, isEnabled: true)
                            .contextMenu {
                                Button(action: {
                                    pluginManager.disablePlugin(withID: plugin.id)
                                }) {
                                    Label("Disable", systemImage: "power")
                                }
                                
                                Button(action: {
                                    selectedPlugin = plugin
                                    showPluginDetails = true
                                }) {
                                    Label("View Details", systemImage: "info.circle")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    pluginManager.uninstallPlugin(withID: plugin.id)
                                }) {
                                    Label("Uninstall", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .draggableItem(plugin.id) {
                                PluginDragPreview(plugin: plugin)
                            }
                            .onTapGesture {
                                selectedPlugin = plugin
                                showPluginDetails = true
                            }
                    }
                    
                    if filteredEnabledPlugins.isEmpty {
                        Text("No enabled plugins match your search")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                    }
                }
                
                Section(header: Text("Available Plugins")) {
                    ForEach(filteredAvailablePlugins) { plugin in
                        PluginRowView(plugin: plugin, isEnabled: false)
                            .contextMenu {
                                Button(action: {
                                    pluginManager.enablePlugin(withID: plugin.id)
                                }) {
                                    Label("Enable", systemImage: "power")
                                }
                                
                                Button(action: {
                                    selectedPlugin = plugin
                                    showPluginDetails = true
                                }) {
                                    Label("View Details", systemImage: "info.circle")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    pluginManager.uninstallPlugin(withID: plugin.id)
                                }) {
                                    Label("Uninstall", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .draggableItem(plugin.id) {
                                PluginDragPreview(plugin: plugin)
                            }
                            .onTapGesture {
                                selectedPlugin = plugin
                                showPluginDetails = true
                            }
                    }
                    
                    if filteredAvailablePlugins.isEmpty {
                        Text("No available plugins match your search")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            Divider()
            
            // Bottom toolbar
            HStack {
                Button(action: {
                    isImportingPlugin = true
                }) {
                    Label("Import Plugin", systemImage: "plus")
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                
                Spacer()
                
                Button(action: {
                    // Open plugin marketplace or documentation
                }) {
                    Label("Plugin Marketplace", systemImage: "bag")
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                )
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
        )
        .dropDestinationWithFeedback(for: URL.self, isTargeted: $isTargeted) { urls, _ in
            handleDroppedPlugins(urls: urls)
            return true
        }
        .sheet(isPresented: $showPluginDetails) {
            if let plugin = selectedPlugin {
                PluginDetailView(plugin: plugin)
                    .environmentObject(pluginManager)
                    .environmentObject(themeManager)
            }
        }
        .fileImporter(
            isPresented: $isImportingPlugin,
            allowedContentTypes: [UTType(filenameExtension: "aiplugin")!],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    for url in urls {
                        do {
                            try await pluginManager.installPlugin(from: url)
                        } catch {
                            print("Failed to install plugin: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print("Plugin import failed: \(error.localizedDescription)")
            }
        }
        .onAppear {
            // Refresh plugin list when view appears
            Task {
                await pluginManager.refreshPlugins()
            }
        }
    }
    
    /// Filtered list of enabled plugins based on search text
    private var filteredEnabledPlugins: [Plugin] {
        if searchText.isEmpty {
            return Array(pluginManager.enabledPlugins)
        } else {
            return pluginManager.enabledPlugins.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// Filtered list of available (but not enabled) plugins based on search text
    private var filteredAvailablePlugins: [Plugin] {
        let availablePlugins = pluginManager.availablePlugins.filter { plugin in
            !pluginManager.enabledPlugins.contains { $0.id == plugin.id }
        }
        
        if searchText.isEmpty {
            return Array(availablePlugins)
        } else {
            return availablePlugins.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// Handle dropped plugin files
    private func handleDroppedPlugins(urls: [URL]) -> Bool {
        Task {
            for url in urls {
                if url.pathExtension.lowercased() == "aiplugin" {
                    do {
                        try await pluginManager.installPlugin(from: url)
                    } catch {
                        print("Failed to install plugin: \(error.localizedDescription)")
                    }
                }
            }
        }
        return true
    }
}

/// Row view for a plugin in the list
struct PluginRowView: View {
    let plugin: Plugin
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            // Plugin icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if let iconName = plugin.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }
            }
            
            // Plugin info
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.headline)
                
                Text(plugin.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status indicator
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

/// Preview view for a plugin being dragged
struct PluginDragPreview: View {
    let plugin: Plugin
    
    var body: some View {
        HStack {
            Image(systemName: plugin.iconName ?? "puzzlepiece.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text(plugin.name)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.accentColor)
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}

/// Detailed view for a plugin
struct PluginDetailView: View {
    let plugin: Plugin
    @EnvironmentObject private var pluginManager: PluginManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(plugin.name)
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
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Plugin icon and basic info
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            if let iconName = plugin.iconName {
                                Image(systemName: iconName)
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                            } else {
                                Image(systemName: "puzzlepiece.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plugin.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Version: \(plugin.version)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Author: \(plugin.author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Enable/Disable toggle
                        Toggle("", isOn: Binding(
                            get: { pluginManager.enabledPlugins.contains { $0.id == plugin.id } },
                            set: { isEnabled in
                                if isEnabled {
                                    pluginManager.enablePlugin(withID: plugin.id)
                                } else {
                                    pluginManager.disablePlugin(withID: plugin.id)
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(12)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(plugin.description)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(12)
                    
                    // Capabilities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capabilities")
                            .font(.headline)
                        
                        ForEach(plugin.capabilities, id: \.self) { capability in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text(capability)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(12)
                    
                    // Permissions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissions")
                            .font(.headline)
                        
                        ForEach(plugin.permissions, id: \.self) { permission in
                            HStack {
                                Image(systemName: "lock.open.fill")
                                    .foregroundColor(.orange)
                                
                                Text(permission)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(12)
                }
                .padding()
            }
            
            Divider()
            
            // Footer with actions
            HStack {
                Button(action: {
                    // Open plugin website or documentation
                    if let websiteURL = URL(string: plugin.website) {
                        NSWorkspace.shared.open(websiteURL)
                    }
                }) {
                    Label("Visit Website", systemImage: "globe")
                }
                .disabled(plugin.website.isEmpty)
                
                Spacer()
                
                Button(action: {
                    pluginManager.uninstallPlugin(withID: plugin.id)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Label("Uninstall", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }
}

// Preview for SwiftUI canvas
struct PluginView_Previews: PreviewProvider {
    static var previews: some View {
        PluginView()
            .environmentObject(PluginManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}
