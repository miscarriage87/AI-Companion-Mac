
//
//  DragDropManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Manager for handling drag and drop operations
class DragDropManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = DragDropManager()
    
    /// Whether drag and drop is enabled
    @Published var dragDropEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(dragDropEnabled, forKey: "dragDropEnabled")
        }
    }
    
    /// Whether to show visual feedback during drag operations
    @Published var showVisualFeedback: Bool = true {
        didSet {
            UserDefaults.standard.set(showVisualFeedback, forKey: "showDragDropVisualFeedback")
        }
    }
    
    /// Supported document types for drag and drop
    let supportedDocumentTypes: [UTType] = [
        .plainText,
        .pdf,
        .image,
        .jpeg,
        .png,
        .html,
        .rtf,
        .spreadsheet,
        .presentation,
        .audio,
        .video,
        .zip
    ]
    
    /// Supported message content types for drag and drop
    let supportedMessageTypes: [UTType] = [
        .plainText,
        .rtf,
        .image,
        .jpeg,
        .png
    ]
    
    private init() {
        // Load user preferences
        dragDropEnabled = UserDefaults.standard.bool(forKey: "dragDropEnabled")
        showVisualFeedback = UserDefaults.standard.bool(forKey: "showDragDropVisualFeedback")
        
        // Set defaults if not previously set
        if !UserDefaults.standard.object(forKey: "dragDropEnabled").map({ $0 as? Bool }) ?? false {
            dragDropEnabled = true
            UserDefaults.standard.set(true, forKey: "dragDropEnabled")
        }
        
        if !UserDefaults.standard.object(forKey: "showDragDropVisualFeedback").map({ $0 as? Bool }) ?? false {
            showVisualFeedback = true
            UserDefaults.standard.set(true, forKey: "showDragDropVisualFeedback")
        }
    }
    
    /// Check if a UTType is supported for document drag and drop
    func isDocumentTypeSupported(_ type: UTType) -> Bool {
        return supportedDocumentTypes.contains { $0 == type || type.conforms(to: $0) }
    }
    
    /// Check if a UTType is supported for message drag and drop
    func isMessageTypeSupported(_ type: UTType) -> Bool {
        return supportedMessageTypes.contains { $0 == type || type.conforms(to: $0) }
    }
    
    /// Process dropped files and return their URLs
    func processDroppedFiles(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                    defer { group.leave() }
                    
                    if let urlData = urlData as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(urls)
        }
    }
    
    /// Process dropped text and return the string
    func processDroppedText(from providers: [NSItemProvider], completion: @escaping (String?) -> Void) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
                    if let data = data as? Data, let string = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            completion(string)
                        }
                        return
                    } else if let string = data as? String {
                        DispatchQueue.main.async {
                            completion(string)
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
                return
            }
        }
        
        completion(nil)
    }
    
    /// Process dropped images and return the image data
    func processDroppedImages(from providers: [NSItemProvider], completion: @escaping ([NSImage]) -> Void) {
        var images: [NSImage] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (data, error) in
                    defer { group.leave() }
                    
                    if let url = data as? URL, let image = NSImage(contentsOf: url) {
                        images.append(image)
                    } else if let data = data as? Data, let image = NSImage(data: data) {
                        images.append(image)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(images)
        }
    }
}

// MARK: - Drag and Drop View Modifiers

/// Modifier to make a view draggable with visual feedback
struct DraggableModifier<Item: Transferable>: ViewModifier {
    let item: Item
    let preview: (() -> some View)?
    @State private var isDragging = false
    
    init(item: Item, preview: (() -> some View)? = nil) {
        self.item = item
        self.preview = preview
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isDragging && DragDropManager.shared.showVisualFeedback ? 0.5 : 1.0)
            .draggable(item) {
                if let preview = preview {
                    return preview()
                } else {
                    return content
                        .frame(width: 100, height: 100)
                        .opacity(0.8)
                }
            }
            .onDrag {
                isDragging = true
                return NSItemProvider(object: "Dragging" as NSString)
            }
            .onDrop(of: [UTType.plainText], isTargeted: nil) { _ in
                isDragging = false
                return false
            }
    }
}

/// Modifier to make a view a drop destination with visual feedback
struct DropDestinationModifier<T: Transferable>: ViewModifier {
    let type: T.Type
    let isTargeted: Binding<Bool>?
    let action: ([T], CGPoint) -> Bool
    
    func body(content: Content) -> some View {
        content
            .dropDestination(for: type) { items, location in
                return action(items, location)
            } isTargeted: { targeted in
                if let isTargeted = isTargeted {
                    isTargeted.wrappedValue = targeted
                }
            }
    }
}

// MARK: - View Extensions for Drag and Drop

extension View {
    /// Make a view draggable with the specified item
    func draggableItem<Item: Transferable>(_ item: Item, preview: (() -> some View)? = nil) -> some View {
        self.modifier(DraggableModifier(item: item, preview: preview))
    }
    
    /// Make a view a drop destination for the specified type
    func dropDestinationWithFeedback<T: Transferable>(for type: T.Type, isTargeted: Binding<Bool>? = nil, action: @escaping ([T], CGPoint) -> Bool) -> some View {
        self.modifier(DropDestinationModifier(type: type, isTargeted: isTargeted, action: action))
    }
}

// MARK: - Drag Visual Feedback View

/// Visual feedback view for drag operations
struct DragVisualFeedbackView: View {
    let isTargeted: Bool
    let validDrop: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(
                validDrop ? Color.green : Color.red,
                style: StrokeStyle(
                    lineWidth: 2,
                    dash: [6, 3]
                )
            )
            .opacity(isTargeted ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
}
