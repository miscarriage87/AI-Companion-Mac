
//
//  DocumentChatView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for document-based chat
struct DocumentChatView: View {
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var documentManager: DocumentManager
    
    @State private var showDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Referenced documents
            if !chatViewModel.referencedDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Referenced Documents")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(chatViewModel.referencedDocuments) { document in
                                DocumentReferenceCard(document: document) {
                                    chatViewModel.removeDocumentReference(document)
                                }
                            }
                            
                            Button(action: {
                                showDocumentPicker = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 24))
                                    
                                    Text("Add Document")
                                        .font(.caption)
                                }
                                .frame(width: 100, height: 120)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 140)
                    
                    // Document context toggle
                    Toggle("Include document context in AI prompts", isOn: $chatViewModel.includeDocumentContext)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                }
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
            } else {
                Button(action: {
                    showDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Add Document Reference")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(BorderedButtonStyle())
                .padding(8)
            }
            
            Divider()
            
            // Chat view
            ChatView()
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { document in
                chatViewModel.addDocumentReference(document)
                showDocumentPicker = false
            }
            .environmentObject(documentManager)
        }
    }
}

/// Card for displaying a document reference
struct DocumentReferenceCard: View {
    let document: Document
    let onRemove: () -> Void
    
    @State private var thumbnail: NSImage?
    @EnvironmentObject private var documentManager: DocumentManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Document icon or thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 100, height: 70)
                
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 70)
                        .cornerRadius(6)
                } else {
                    Image(systemName: documentIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
            }
            
            // Document title
            Text(document.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 100, alignment: .leading)
            
            // Remove button
            Button(action: onRemove) {
                Label("Remove", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 100)
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
}

/// View for picking a document to reference
struct DocumentPickerView: View {
    let onSelect: (Document) -> Void
    
    @EnvironmentObject private var documentManager: DocumentManager
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Select a Document")
                .font(.headline)
                .padding()
            
            Divider()
            
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
            
            // Documents list
            if filteredDocuments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    if !searchText.isEmpty {
                        Text("No documents match your search")
                            .font(.headline)
                        
                        Button("Clear Search") {
                            searchText = ""
                        }
                        .buttonStyle(BorderedButtonStyle())
                    } else {
                        Text("No documents available")
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(document)
                            }
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    /// Filtered documents based on search text
    private var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documentManager.documents
        } else {
            return documentManager.documents.filter { document in
                document.title.localizedCaseInsensitiveContains(searchText) ||
                document.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
