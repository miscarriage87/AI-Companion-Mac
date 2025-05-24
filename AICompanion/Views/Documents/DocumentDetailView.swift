
//
//  DocumentDetailView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI
import PDFKit

/// View for displaying document details
struct DocumentDetailView: View {
    @EnvironmentObject private var documentManager: DocumentManager
    @EnvironmentObject private var chatViewModel: ChatViewModel
    
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @State private var showAddTagSheet = false
    @State private var newTagName = ""
    @State private var newTagColor = "3B82F6" // Default blue color
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showAnalysisProgress = false
    @State private var analysisProgress = 0.0
    @State private var similarDocuments: [(document: Document, similarity: Double)] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Document header
            if let document = documentManager.selectedDocument {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Title
                        if isEditingTitle {
                            TextField("Document Title", text: $editedTitle, onCommit: {
                                updateDocumentTitle(document)
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.trailing, 8)
                            
                            Button("Save") {
                                updateDocumentTitle(document)
                            }
                            .buttonStyle(BorderedButtonStyle())
                            
                            Button("Cancel") {
                                isEditingTitle = false
                            }
                            .buttonStyle(BorderedButtonStyle())
                        } else {
                            Text(document.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Button(action: {
                                editedTitle = document.title
                                isEditingTitle = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        Spacer()
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                chatViewModel.addDocumentReference(document)
                            }) {
                                Label("Add to Chat", systemImage: "bubble.left.and.text.bubble.right")
                            }
                            .buttonStyle(BorderedButtonStyle())
                            
                            Button(action: {
                                analyzeDocument(document)
                            }) {
                                Label("Analyze", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }
                    
                    // Document metadata
                    HStack {
                        Label(document.fileExtension.uppercased(), systemImage: documentIcon(for: document))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(formattedFileSize(document.fileSize))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Created: \(formatDate(document.createdAt))")
                            .foregroundColor(.secondary)
                        
                        Text("Updated: \(formatDate(document.updatedAt))")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    // Tags
                    HStack {
                        Text("Tags:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(document.tags) { tag in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: tag.color))
                                            .frame(width: 8, height: 8)
                                        
                                        Text(tag.name)
                                            .font(.caption)
                                        
                                        Button(action: {
                                            removeTag(tag, from: document)
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8))
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: tag.color).opacity(0.2))
                                    .cornerRadius(4)
                                }
                                
                                Button(action: {
                                    showAddTagSheet = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Tab view for document content
                TabView(selection: $selectedTab) {
                    // Content tab
                    DocumentContentView(document: document, searchText: $searchText)
                        .tabItem {
                            Label("Content", systemImage: "doc.text")
                        }
                        .tag(0)
                    
                    // Summary tab
                    DocumentSummaryView(document: document)
                        .tabItem {
                            Label("Summary", systemImage: "list.bullet.rectangle")
                        }
                        .tag(1)
                    
                    // Similar Documents tab
                    SimilarDocumentsView(documents: similarDocuments)
                        .tabItem {
                            Label("Similar", systemImage: "doc.on.doc")
                        }
                        .tag(2)
                }
                .padding()
                .onAppear {
                    // Load similar documents
                    loadSimilarDocuments(for: document)
                }
            } else {
                // No document selected
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No document selected")
                        .font(.headline)
                    
                    Text("Select a document from the list to view its details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddTagView(isPresented: $showAddTagSheet, document: documentManager.selectedDocument)
                .environmentObject(documentManager)
        }
        .overlay(
            Group {
                if showAnalysisProgress {
                    VStack {
                        ProgressView("Analyzing document...", value: analysisProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                }
            }
        )
    }
    
    /// Update document title
    private func updateDocumentTitle(_ document: Document) {
        guard !editedTitle.isEmpty else {
            isEditingTitle = false
            return
        }
        
        var updatedDocument = document
        updatedDocument.title = editedTitle
        
        Task {
            do {
                try await documentManager.updateDocument(updatedDocument)
                await MainActor.run {
                    isEditingTitle = false
                }
            } catch {
                documentManager.errorMessage = "Failed to update title: \(error.localizedDescription)"
                documentManager.showError = true
            }
        }
    }
    
    /// Remove a tag from a document
    private func removeTag(_ tag: DocumentTag, from document: Document) {
        Task {
            do {
                try await documentManager.removeTag(tag, from: document)
            } catch {
                documentManager.errorMessage = "Failed to remove tag: \(error.localizedDescription)"
                documentManager.showError = true
            }
        }
    }
    
    /// Analyze a document
    private func analyzeDocument(_ document: Document) {
        showAnalysisProgress = true
        analysisProgress = 0.1
        
        Task {
            do {
                // Simulate progress updates
                for progress in stride(from: 0.2, to: 0.9, by: 0.1) {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        analysisProgress = progress
                    }
                }
                
                // Perform actual analysis
                try await documentManager.analyzeDocument(document)
                
                // Update similar documents
                await loadSimilarDocuments(for: document)
                
                await MainActor.run {
                    analysisProgress = 1.0
                    
                    // Hide progress after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAnalysisProgress = false
                    }
                    
                    // Switch to summary tab
                    selectedTab = 1
                }
            } catch {
                await MainActor.run {
                    showAnalysisProgress = false
                    documentManager.errorMessage = "Analysis failed: \(error.localizedDescription)"
                    documentManager.showError = true
                }
            }
        }
    }
    
    /// Load similar documents
    private func loadSimilarDocuments(for document: Document) async {
        do {
            let documents = try await DocumentSearchManager.shared.findSimilarDocuments(to: document)
            
            await MainActor.run {
                similarDocuments = documents
            }
        } catch {
            print("Error loading similar documents: \(error)")
        }
    }
    
    /// Get icon for document based on file extension
    private func documentIcon(for document: Document) -> String {
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
    
    /// Format file size for display
    private func formattedFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// View for displaying document content
struct DocumentContentView: View {
    let document: Document
    @Binding var searchText: String
    
    @State private var pdfDocument: PDFDocument?
    @State private var highlightedRanges: [NSRange] = []
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search in document", text: $searchText, onCommit: {
                    highlightSearchResults()
                })
                .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        highlightedRanges = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button("Find") {
                    highlightSearchResults()
                }
                .buttonStyle(BorderedButtonStyle())
                .disabled(searchText.isEmpty)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Document content
            if document.fileExtension.lowercased() == "pdf", let pdfDocument = pdfDocument {
                PDFKitView(document: pdfDocument, highlightedRanges: highlightedRanges)
            } else {
                ScrollView {
                    Text(document.content)
                        .padding()
                        .textSelection(.enabled)
                }
            }
        }
        .onAppear {
            // Load PDF document if applicable
            if document.fileExtension.lowercased() == "pdf", let filePath = document.filePath {
                pdfDocument = PDFDocument(url: URL(fileURLWithPath: filePath))
            }
        }
    }
    
    /// Highlight search results in the document
    private func highlightSearchResults() {
        guard !searchText.isEmpty else {
            highlightedRanges = []
            return
        }
        
        if document.fileExtension.lowercased() == "pdf", let pdfDocument = pdfDocument {
            // For PDF documents
            highlightedRanges = []
            
            // Search in PDF
            pdfDocument.cancelFindString()
            pdfDocument.beginFindString(searchText, withOptions: .caseInsensitive)
            
            // PDF search is asynchronous, so we can't get the results directly
            // Instead, we'll rely on PDFKitView to handle highlighting
        } else {
            // For text documents
            highlightedRanges = []
            
            // Find all occurrences of search text
            let content = document.content.lowercased()
            let searchLower = searchText.lowercased()
            
            var searchRange = NSRange(location: 0, length: content.count)
            var foundRange = NSRange(location: NSNotFound, length: 0)
            
            repeat {
                foundRange = (content as NSString).range(of: searchLower, options: [], range: searchRange)
                
                if foundRange.location != NSNotFound {
                    highlightedRanges.append(foundRange)
                    
                    // Update search range for next iteration
                    searchRange.location = foundRange.location + foundRange.length
                    searchRange.length = content.count - searchRange.location
                }
            } while foundRange.location != NSNotFound && searchRange.location < content.count
        }
    }
}

/// View for displaying PDF documents
struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    let highlightedRanges: [NSRange]
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
        
        // Apply search highlighting if needed
        if !highlightedRanges.isEmpty {
            // PDFView handles highlighting through its search functionality
            // We don't need to manually highlight ranges
        }
    }
}

/// View for displaying document summary
struct DocumentSummaryView: View {
    let document: Document
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let summary = document.summary {
                    Text(summary)
                        .padding()
                        .textSelection(.enabled)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No summary available")
                            .font(.headline)
                        
                        Text("Analyze the document to generate a summary")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
        }
    }
}

/// View for displaying similar documents
struct SimilarDocumentsView: View {
    let documents: [(document: Document, similarity: Double)]
    
    @EnvironmentObject private var documentManager: DocumentManager
    
    var body: some View {
        if documents.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("No similar documents found")
                    .font(.headline)
                
                Text("Analyze the document to find similar content")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            List {
                ForEach(documents, id: \.document.id) { item in
                    HStack {
                        Text(item.document.title)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(item.similarity * 100))% match")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        documentManager.selectedDocument = item.document
                    }
                }
            }
        }
    }
}

/// View for adding a tag to a document
struct AddTagView: View {
    @Binding var isPresented: Bool
    let document: Document?
    
    @State private var selectedTag: DocumentTag?
    @State private var showCreateTagSheet = false
    @State private var newTagName = ""
    @State private var newTagColor = "3B82F6" // Default blue color
    
    @EnvironmentObject private var documentManager: DocumentManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Tag to Document")
                .font(.headline)
            
            // Existing tags
            if documentManager.tags.isEmpty {
                Text("No tags available")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                        ForEach(documentManager.tags) { tag in
                            TagSelectionButton(tag: tag, isSelected: selectedTag?.id == tag.id) {
                                if selectedTag?.id == tag.id {
                                    selectedTag = nil
                                } else {
                                    selectedTag = tag
                                }
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
            
            // Create new tag button
            Button("Create New Tag") {
                showCreateTagSheet = true
            }
            
            Divider()
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Add Tag") {
                    if let tag = selectedTag, let doc = document {
                        Task {
                            do {
                                try await documentManager.addTag(tag, to: doc)
                                await MainActor.run {
                                    isPresented = false
                                }
                            } catch {
                                documentManager.errorMessage = "Failed to add tag: \(error.localizedDescription)"
                                documentManager.showError = true
                            }
                        }
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(selectedTag == nil)
            }
        }
        .padding()
        .frame(width: 400)
        .sheet(isPresented: $showCreateTagSheet) {
            CreateTagView(isPresented: $showCreateTagSheet, onTagCreated: { tag in
                selectedTag = tag
            })
            .environmentObject(documentManager)
        }
    }
}

/// Button for tag selection
struct TagSelectionButton: View {
    let tag: DocumentTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(Color(hex: tag.color))
                    .frame(width: 12, height: 12)
                
                Text(tag.name)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(hex: tag.color).opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: tag.color).opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// View for creating a new tag
struct CreateTagView: View {
    @Binding var isPresented: Bool
    let onTagCreated: (DocumentTag) -> Void
    
    @State private var tagName = ""
    @State private var tagColor = "3B82F6" // Default blue color
    
    @EnvironmentObject private var documentManager: DocumentManager
    
    // Predefined colors
    let colors = [
        "3B82F6", // Blue
        "10B981", // Green
        "F59E0B", // Yellow
        "EF4444", // Red
        "8B5CF6", // Purple
        "EC4899", // Pink
        "6B7280", // Gray
        "000000"  // Black
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Create New Tag")
                .font(.headline)
            
            TextField("Tag Name", text: $tagName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Color selection
            Text("Select Color")
                .font(.subheadline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                ForEach(colors, id: \.self) { color in
                    ColorButton(color: color, isSelected: tagColor == color) {
                        tagColor = color
                    }
                }
            }
            
            Divider()
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Create") {
                    guard !tagName.isEmpty else { return }
                    
                    Task {
                        do {
                            let tag = try await documentManager.createTag(name: tagName, color: tagColor)
                            await MainActor.run {
                                onTagCreated(tag)
                                isPresented = false
                            }
                        } catch {
                            documentManager.errorMessage = "Failed to create tag: \(error.localizedDescription)"
                            documentManager.showError = true
                        }
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(tagName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

/// Button for color selection
struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 30, height: 30)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
