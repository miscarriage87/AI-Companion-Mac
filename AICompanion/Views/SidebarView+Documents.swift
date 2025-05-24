
//
//  SidebarView+Documents.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// Extension to SidebarView for document management
extension SidebarView {
    /// Add document section to the sidebar
    var documentSection: some View {
        Section(header: Text("Documents")) {
            NavigationLink(
                destination: DocumentListView()
                    .environmentObject(documentManager),
                tag: SidebarItem.documents,
                selection: $sidebarViewModel.selectedItem
            ) {
                Label("All Documents", systemImage: "doc.text")
            }
            
            NavigationLink(
                destination: DocumentUploadView()
                    .environmentObject(documentManager),
                tag: SidebarItem.documentUpload,
                selection: $sidebarViewModel.selectedItem
            ) {
                Label("Upload Document", systemImage: "arrow.up.doc")
            }
            
            if let selectedDocument = documentManager.selectedDocument {
                NavigationLink(
                    destination: DocumentDetailView()
                        .environmentObject(documentManager),
                    tag: SidebarItem.documentDetail,
                    selection: $sidebarViewModel.selectedItem
                ) {
                    Label(selectedDocument.title, systemImage: "doc.text.magnifyingglass")
                }
            }
            
            NavigationLink(
                destination: DocumentChatView()
                    .environmentObject(documentManager)
                    .environmentObject(chatViewModel),
                tag: SidebarItem.documentChat,
                selection: $sidebarViewModel.selectedItem
            ) {
                Label("Document Chat", systemImage: "bubble.left.and.text.bubble.right")
            }
            
            // Tags section
            DisclosureGroup("Tags") {
                ForEach(documentManager.tags) { tag in
                    HStack {
                        Circle()
                            .fill(Color(hex: tag.color))
                            .frame(width: 8, height: 8)
                        
                        Text(tag.name)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(tagDocumentCount(tag))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Filter documents by tag
                        sidebarViewModel.selectedTagId = tag.id
                        sidebarViewModel.selectedItem = .documentsByTag
                    }
                }
                
                Button(action: {
                    showAddTagSheet = true
                }) {
                    Label("Add Tag", systemImage: "plus")
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    /// Count documents with a specific tag
    private func tagDocumentCount(_ tag: DocumentTag) -> Int {
        return documentManager.documents.filter { document in
            document.tags.contains { $0.id == tag.id }
        }.count
    }
}

/// Extension to SidebarViewModel for document management
extension SidebarViewModel {
    /// Selected tag ID for filtering
    @Published var selectedTagId: UUID?
    
    /// Document manager
    @Published var documentManager = DocumentManager.shared
    
    /// Get documents filtered by selected tag
    var documentsByTag: [Document] {
        guard let tagId = selectedTagId else {
            return []
        }
        
        return documentManager.documents.filter { document in
            document.tags.contains { $0.id == tagId }
        }
    }
}

/// Sidebar item types
enum SidebarItem: Hashable {
    case conversations
    case documents
    case documentUpload
    case documentDetail
    case documentChat
    case documentsByTag
    case settings
}
