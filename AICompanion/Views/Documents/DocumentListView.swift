
//
//  DocumentListView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for displaying a list of documents
struct DocumentListView: View {
    @EnvironmentObject private var documentManager: DocumentManager
    @EnvironmentObject private var chatViewModel: ChatViewModel
    
    @State private var searchText = ""
    @State private var isImporting = false
    @State private var isImportingURL = false
    @State private var importURL = ""
    @State private var showURLImportSheet = false
    @State private var selectedTags: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var documentToDelete: Document?
    @State private var importProgress: Double?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search documents", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
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
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding([.horizontal, .top], 8)
            
            // Import buttons
            HStack {
                Button(action: {
                    isImporting = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Import File")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button(action: {
                    showURLImportSheet = true
                }) {
                    HStack {
                        Image(systemName: "link.badge.plus")
                        Text("Import URL")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            // Tag filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(documentManager.tags) { tag in
                        TagButton(tag: tag, isSelected: selectedTags.contains(tag.id)) {
                            if selectedTags.contains(tag.id) {
                                selectedTags.remove(tag.id)
                            } else {
                                selectedTags.insert(tag.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(height: 40)
            
            Divider()
                .padding(.vertical, 4)
            
            // Documents list
            if importProgress != nil {
                ProgressView("Importing document...", value: importProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            } else if filteredDocuments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    if !searchText.isEmpty || !selectedTags.isEmpty {
                        Text("No documents match your search")
                            .font(.headline)
                        
                        Button("Clear Filters") {
                            searchText = ""
                            selectedTags.removeAll()
                        }
                        .buttonStyle(BorderedButtonStyle())
                    } else {
                        Text("No documents yet")
                            .font(.headline)
                        
                        Text("Import documents to get started")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(filteredDocuments) { document in
                        DocumentRow(document: document)
                            .contextMenu {
                                Button(action: {
                                    documentManager.selectedDocument = document
                                }) {
                                    Label("View Details", systemImage: "doc.text.magnifyingglass")
                                }
                                
                                Button(action: {
                                    chatViewModel.addDocumentReference(document)
                                }) {
                                    Label("Add to Chat", systemImage: "bubble.left.and.text.bubble.right")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    documentToDelete = document
                                    showDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .onTapGesture {
                                documentManager.selectedDocument = document
                            }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .html, .rtf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                // Start import with progress tracking
                importProgress = 0.0
                
                Task {
                    do {
                        _ = try await documentManager.importDocument(from: url) { progress in
                            Task { @MainActor in
                                importProgress = progress
                            }
                        }
                        
                        // Clear progress when done
                        await MainActor.run {
                            importProgress = nil
                        }
                    } catch {
                        await MainActor.run {
                            documentManager.errorMessage = "Import failed: \(error.localizedDescription)"
                            documentManager.showError = true
                            importProgress = nil
                        }
                    }
                }
                
            case .failure(let error):
                documentManager.errorMessage = "Import failed: \(error.localizedDescription)"
                documentManager.showError = true
            }
        }
        .sheet(isPresented: $showURLImportSheet) {
            URLImportView(isPresented: $showURLImportSheet, importProgress: $importProgress)
                .environmentObject(documentManager)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Document"),
                message: Text("Are you sure you want to delete '\(documentToDelete?.title ?? "this document")'? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let document = documentToDelete {
                        Task {
                            do {
                                try await documentManager.deleteDocument(document)
                            } catch {
                                documentManager.errorMessage = "Delete failed: \(error.localizedDescription)"
                                documentManager.showError = true
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    /// Filtered documents based on search text and selected tags
    private var filteredDocuments: [Document] {
        documentManager.documents.filter { document in
            // Filter by search text
            let matchesSearch = searchText.isEmpty || 
                document.title.localizedCaseInsensitiveContains(searchText) ||
                document.content.localizedCaseInsensitiveContains(searchText)
            
            // Filter by selected tags
            let matchesTags = selectedTags.isEmpty || 
                document.tags.contains { tag in selectedTags.contains(tag.id) }
            
            return matchesSearch && matchesTags
        }
    }
}

/// View for a document row in the list
struct DocumentRow: View {
    let document: Document
    
    @State private var thumbnail: NSImage?
    @EnvironmentObject private var documentManager: DocumentManager
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Document icon or thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 50, height: 60)
                
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 60)
                        .cornerRadius(6)
                } else {
                    Image(systemName: documentIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
            }
            
            // Document details
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(document.fileExtension.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(document.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                if !document.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(document.tags) { tag in
                                Text(tag.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: tag.color).opacity(0.2))
                                    .foregroundColor(Color(hex: tag.color))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            // Load thumbnail
            Task {
                thumbnail = await documentManager.generateThumbnail(for: document)
            }
        }
    }
    
    /// Icon for the document based on file extension
    private var documentIcon: String {
        switch document.fileExtension.lowercased() {
        case "pdf":
            return "doc.richtext"
        case "docx", "doc":
            return "doc.text"
        case "txt":
            return "doc.plaintext"
        case "html", "htm":
            return "doc.text.globe"
        default:
            return "doc"
        }
    }
    
    /// Formatted file size
    private var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: document.fileSize)
    }
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

/// Button for tag selection
struct TagButton: View {
    let tag: DocumentTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color(hex: tag.color).opacity(0.3) : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isSelected ? Color(hex: tag.color) : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// View for importing a document from a URL
struct URLImportView: View {
    @Binding var isPresented: Bool
    @Binding var importProgress: Double?
    @State private var url = ""
    @State private var isImporting = false
    
    @EnvironmentObject private var documentManager: DocumentManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Import Document from URL")
                .font(.headline)
            
            TextField("Enter URL", text: $url)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let progress = importProgress {
                ProgressView("Importing...", value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Import") {
                    guard let importURL = URL(string: url) else {
                        documentManager.errorMessage = "Invalid URL"
                        documentManager.showError = true
                        return
                    }
                    
                    isImporting = true
                    importProgress = 0.0
                    
                    Task {
                        do {
                            _ = try await documentManager.importDocument(from: importURL) { progress in
                                Task { @MainActor in
                                    importProgress = progress
                                }
                            }
                            
                            await MainActor.run {
                                isImporting = false
                                importProgress = nil
                                isPresented = false
                            }
                        } catch {
                            await MainActor.run {
                                documentManager.errorMessage = "Import failed: \(error.localizedDescription)"
                                documentManager.showError = true
                                isImporting = false
                                importProgress = nil
                            }
                        }
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(url.isEmpty || isImporting)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

/// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
