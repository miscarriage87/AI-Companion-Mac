
//
//  MultiModalView.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import SwiftUI

/// View for displaying multi-modal interactions (images, audio, etc.)
struct MultiModalView: View {
    let type: MultiModalType
    let content: Any
    let caption: String?
    
    @State private var isExpanded = false
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content display
            Group {
                switch type {
                case .image:
                    if let image = content as? NSImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            .onTapGesture {
                                isExpanded.toggle()
                            }
                    } else {
                        Text("Invalid image data")
                            .foregroundColor(.red)
                    }
                case .audio:
                    AudioPlayerView(audioURL: content as? URL)
                case .video:
                    VideoPlayerView(videoURL: content as? URL)
                case .document:
                    DocumentPreviewView(documentURL: content as? URL)
                }
            }
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $isExpanded) {
                if type == .image, let image = content as? NSImage {
                    FullScreenImageView(image: image, caption: caption)
                }
            }
            
            // Caption
            if let caption = caption, !caption.isEmpty {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            // Action buttons
            HStack {
                Spacer()
                
                Button(action: {
                    saveContent()
                }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isHovering ? 1 : 0)
                
                Button(action: {
                    shareContent()
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isHovering ? 1 : 0)
                
                if type == .image {
                    Button(action: {
                        isExpanded.toggle()
                    }) {
                        Label(isExpanded ? "Close" : "Expand", systemImage: isExpanded ? "minus.magnifyingglass" : "plus.magnifyingglass")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(isHovering ? 1 : 0)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    /// Save the content to disk
    private func saveContent() {
        switch type {
        case .image:
            if let image = content as? NSImage {
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.png, .jpeg]
                savePanel.nameFieldStringValue = "Image-\(Date().timeIntervalSince1970).png"
                
                savePanel.begin { response in
                    if response == .OK, let url = savePanel.url {
                        if let tiffData = image.tiffRepresentation,
                           let bitmapImage = NSBitmapImageRep(data: tiffData),
                           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                            try? pngData.write(to: url)
                        }
                    }
                }
            }
        case .audio, .video, .document:
            if let url = content as? URL {
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.item]
                savePanel.nameFieldStringValue = url.lastPathComponent
                
                savePanel.begin { response in
                    if response == .OK, let saveURL = savePanel.url {
                        try? FileManager.default.copyItem(at: url, to: saveURL)
                    }
                }
            }
        }
    }
    
    /// Share the content
    private func shareContent() {
        switch type {
        case .image:
            if let image = content as? NSImage {
                let sharingServicePicker = NSSharingServicePicker(items: [image])
                
                if let window = NSApplication.shared.windows.first {
                    sharingServicePicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
                }
            }
        case .audio, .video, .document:
            if let url = content as? URL {
                let sharingServicePicker = NSSharingServicePicker(items: [url])
                
                if let window = NSApplication.shared.windows.first {
                    sharingServicePicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
                }
            }
        }
    }
}

/// Types of multi-modal content
enum MultiModalType {
    case image
    case audio
    case video
    case document
}

/// Full screen image view
struct FullScreenImageView: View {
    let image: NSImage
    let caption: String?
    
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
            
            Spacer()
            
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { value in
                            lastScale = scale
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { value in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        scale = scale == 1.0 ? 2.0 : 1.0
                        lastScale = scale
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            
            Spacer()
            
            if let caption = caption, !caption.isEmpty {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding()
            }
            
            HStack {
                Button(action: {
                    withAnimation {
                        scale = max(0.5, scale - 0.25)
                        lastScale = scale
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                
                Button(action: {
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }) {
                    Image(systemName: "1.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                
                Button(action: {
                    withAnimation {
                        scale = min(4.0, scale + 0.25)
                        lastScale = scale
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
}

/// Audio player view
struct AudioPlayerView: View {
    let audioURL: URL?
    
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 1
    
    var body: some View {
        if let audioURL = audioURL {
            VStack(spacing: 8) {
                // Waveform visualization
                WaveformView(progress: progress)
                    .frame(height: 40)
                    .padding(.horizontal)
                
                // Playback controls
                HStack {
                    Button(action: {
                        isPlaying.toggle()
                        // Actual audio playback would be implemented here
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Progress slider
                    Slider(value: $progress, in: 0...1)
                        .accentColor(.accentColor)
                    
                    // Duration
                    Text(formatDuration(progress * duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .onAppear {
                // In a real implementation, we would get the actual duration
                duration = 120 // Example: 2 minutes
            }
        } else {
            Text("Audio file not available")
                .foregroundColor(.red)
                .padding()
        }
    }
    
    /// Format duration as MM:SS
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Waveform visualization view
struct WaveformView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background waveform
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midHeight = height / 2
                    
                    for x in stride(from: 0, to: width, by: 3) {
                        let amplitude = CGFloat.random(in: 0.1...0.9)
                        let y1 = midHeight - (midHeight * amplitude)
                        let y2 = midHeight + (midHeight * amplitude)
                        
                        path.move(to: CGPoint(x: x, y: y1))
                        path.addLine(to: CGPoint(x: x, y: y2))
                    }
                }
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                
                // Progress waveform
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midHeight = height / 2
                    let progressWidth = width * CGFloat(progress)
                    
                    for x in stride(from: 0, to: progressWidth, by: 3) {
                        let amplitude = CGFloat.random(in: 0.1...0.9)
                        let y1 = midHeight - (midHeight * amplitude)
                        let y2 = midHeight + (midHeight * amplitude)
                        
                        path.move(to: CGPoint(x: x, y: y1))
                        path.addLine(to: CGPoint(x: x, y: y2))
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
                .mask(
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(progress))
                )
            }
        }
    }
}

/// Video player view
struct VideoPlayerView: View {
    let videoURL: URL?
    
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 1
    
    var body: some View {
        if let videoURL = videoURL {
            VStack(spacing: 0) {
                // Video preview
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                    
                    // In a real implementation, this would be an AVPlayerView
                    Text("Video Player")
                        .foregroundColor(.white)
                    
                    if !isPlaying {
                        Button(action: {
                            isPlaying.toggle()
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Playback controls
                HStack {
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause" : "play")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Progress slider
                    Slider(value: $progress, in: 0...1)
                        .accentColor(.accentColor)
                    
                    // Duration
                    Text(formatDuration(progress * duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .onAppear {
                // In a real implementation, we would get the actual duration
                duration = 180 // Example: 3 minutes
            }
        } else {
            Text("Video file not available")
                .foregroundColor(.red)
                .padding()
        }
    }
    
    /// Format duration as MM:SS
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Document preview view
struct DocumentPreviewView: View {
    let documentURL: URL?
    
    var body: some View {
        if let documentURL = documentURL {
            VStack {
                // Document icon
                Image(systemName: documentIcon(for: documentURL))
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .padding()
                
                // Document name
                Text(documentURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                
                // Document info
                if let attributes = try? FileManager.default.attributesOfItem(atPath: documentURL.path),
                   let size = attributes[.size] as? NSNumber {
                    Text(formatFileSize(size.int64Value))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Open button
                Button(action: {
                    NSWorkspace.shared.open(documentURL)
                }) {
                    Text("Open Document")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 8)
            }
            .padding()
            .frame(width: 200, height: 180)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        } else {
            Text("Document not available")
                .foregroundColor(.red)
                .padding()
        }
    }
    
    /// Get the system icon name for a document URL
    private func documentIcon(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf":
            return "doc.fill"
        case "doc", "docx":
            return "doc.fill"
        case "xls", "xlsx":
            return "chart.bar.doc.horizontal"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal"
        case "txt":
            return "doc.text"
        case "rtf":
            return "doc.richtext"
        case "html", "htm":
            return "doc.text.image"
        case "zip", "rar", "7z":
            return "doc.zipper"
        default:
            return "doc"
        }
    }
    
    /// Format file size
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// Preview for SwiftUI canvas
struct MultiModalView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MultiModalView(
                type: .image,
                content: NSImage(named: "AppIcon")!,
                caption: "Application icon image"
            )
            
            MultiModalView(
                type: .audio,
                content: URL(string: "file:///example.mp3")!,
                caption: "Audio recording from meeting"
            )
            
            MultiModalView(
                type: .video,
                content: URL(string: "file:///example.mp4")!,
                caption: "Tutorial video"
            )
            
            MultiModalView(
                type: .document,
                content: URL(string: "file:///example.pdf")!,
                caption: "Research paper"
            )
        }
        .padding()
        .frame(width: 500)
    }
}
