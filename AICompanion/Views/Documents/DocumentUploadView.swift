
//
//  DocumentUploadView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI
import UniformTypeIdentifiers

/// View for uploading documents
struct DocumentUploadView: View {
    @EnvironmentObject private var documentManager: DocumentManager
    
    @State private var isImporting = false
    @State private var isImportingURL = false
    @State private var importURL = ""
    @State private var showURLImportSheet = false
    @State private var importProgress: Double?
    @State private var dragOver = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Upload Documents")
                .font(.title2)
                .fontWeight(.bold)
            
            // Upload area
            VStack(spacing: 16) {
                if importProgress != nil {
                    // Progress indicator
                    VStack(spacing: 12) {
                        ProgressView("Importing document...", value: importProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 300)
                        
                        Text("Please wait while we process your document")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    // Drag and drop area
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(dragOver ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(dragOver ? Color.accentColor : Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [6]))
                            )
                        
                        VStack(spacing: 16) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 48))
                                .foregroundColor(dragOver ? .accentColor : .secondary)
                            
                            Text("Drag and drop files here")
                                .font(.headline)
                            
                            Text("or")
                                .foregroundColor(.secondary)
                            
                            Button("Choose File") {
                                isImporting = true
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                        .padding(40)
                    }
                    .frame(height: 250)
                    .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
                        guard let provider = providers.first else { return false }
                        
                        _ = provider.loadObject(ofClass: URL.self) { url, error in
                            guard let url = url, error == nil else { return }
                            
                            // Import the dropped file
                            DispatchQueue.main.async {
                                importDocument(from: url)
                            }
                        }
                        
                        return true
                    }
                    
                    // URL import
                    VStack(spacing: 8) {
                        Text("Import from URL")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter URL", text: $importURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Import") {
                                importDocumentFromURL()
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .disabled(importURL.isEmpty)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Supported formats
            VStack(alignment: .leading, spacing: 8) {
                Text("Supported Formats")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    FormatBadge(format: "PDF", icon: "doc.richtext")
                    FormatBadge(format: "DOCX", icon: "doc.text")
                    FormatBadge(format: "TXT", icon: "doc.plaintext")
                    FormatBadge(format: "HTML", icon: "doc.text.globe")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .plainText, .html, .rtf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importDocument(from: url)
                
            case .failure(let error):
                documentManager.errorMessage = "Import failed: \(error.localizedDescription)"
                documentManager.showError = true
            }
        }
    }
    
    /// Import a document from a file URL
    private func importDocument(from url: URL) {
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
    }
    
    /// Import a document from a URL
    private func importDocumentFromURL() {
        guard let url = URL(string: importURL) else {
            documentManager.errorMessage = "Invalid URL"
            documentManager.showError = true
            return
        }
        
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
                    importURL = ""
                }
            } catch {
                await MainActor.run {
                    documentManager.errorMessage = "Import failed: \(error.localizedDescription)"
                    documentManager.showError = true
                    importProgress = nil
                }
            }
        }
    }
}

/// Badge for displaying supported file formats
struct FormatBadge: View {
    let format: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            
            Text(format)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .foregroundColor(.accentColor)
        .cornerRadius(6)
    }
}
