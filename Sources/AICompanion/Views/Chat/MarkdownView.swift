
import SwiftUI
import MarkdownUI
import Highlightr

/// View for rendering markdown content
struct MarkdownView: View {
    let content: String
    @State private var isLoading = true
    @State private var error: Error? = nil
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .onAppear {
                        // Simulate a short loading time for better UX
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isLoading = false
                        }
                    }
            } else if let error = error {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error rendering markdown:")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(content)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Markdown(content)
                    .markdownTheme(.gitHub)
                    .markdownCodeSyntaxHighlighter(.highlightr(theme: .xcode))
                    .markdownImageProvider(.asset())
                    .markdownBlockStyle(\.codeBlock) { configuration in
                        configuration.label
                            .markdownTextStyle {
                                FontFamilyVariant(.monospaced)
                                FontSize(.em(0.85))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                codeBlockHeader(configuration.language)
                                    .padding(.bottom, 8),
                                alignment: .topLeading
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            do {
                // Validate markdown content
                _ = try AttributedString(markdown: content)
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    private func codeBlockHeader(_ language: String?) -> some View {
        HStack {
            if let language = language {
                Text(language)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Button(action: {
                copyToClipboard(getCodeContent())
            }) {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
    }
    
    private func getCodeContent() -> String {
        // Extract code content from markdown
        // This is a simple implementation that works for basic code blocks
        let codeBlockPattern = "```(?:\\w+)?\\n([\\s\\S]*?)\\n```"
        let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: [])
        let nsRange = NSRange(content.startIndex..<content.endIndex, in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: nsRange),
           let range = Range(match.range(at: 1), in: content) {
            return String(content[range])
        }
        
        return ""
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Code Block View

/// View for rendering code blocks with syntax highlighting
struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var isCopied = false
    
    private let highlightr = Highlightr()
    
    init(code: String, language: String? = nil) {
        self.code = code
        self.language = language
        
        // Set default theme
        highlightr?.setTheme(to: "xcode")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Code block header
            HStack {
                if let language = language {
                    Text(language)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(code)
                    isCopied = true
                    
                    // Reset copied state after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }) {
                    Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(isCopied ? .green : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(8)
            .background(Color(.systemGray6))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                if let highlightedCode = highlightedCode {
                    highlightedCode
                        .padding(12)
                } else {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                }
            }
            .background(Color(.systemGray6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var highlightedCode: Text? {
        guard let language = language,
              let highlightr = highlightr,
              let highlightedCode = highlightr.highlight(code, as: language) else {
            return nil
        }
        
        return Text(AttributedString(highlightedCode))
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Markdown Syntax Highlighter

extension MarkdownUI.SyntaxHighlighter where Self == HighlightrSyntaxHighlighter {
    static func highlightr(theme: HighlightrTheme = .default) -> Self {
        HighlightrSyntaxHighlighter(theme: theme)
    }
}

struct HighlightrSyntaxHighlighter: MarkdownUI.SyntaxHighlighter {
    enum HighlightrTheme: String {
        case `default` = "default"
        case xcode = "xcode"
        case atom = "atom-one-dark"
        case github = "github"
        case monokai = "monokai"
        case solarizedLight = "solarized-light"
        case solarizedDark = "solarized-dark"
    }
    
    let theme: HighlightrTheme
    
    func highlightCode(_ code: String, language: String?) -> AttributedString {
        guard let language = language,
              let highlightr = Highlightr(),
              let highlightedCode = highlightr.highlight(code, as: language) else {
            return AttributedString(code)
        }
        
        highlightr.setTheme(to: theme.rawValue)
        return AttributedString(highlightedCode)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MarkdownView(content: """
        # Heading 1
        ## Heading 2
        
        This is a paragraph with **bold** and *italic* text.
        
        - List item 1
        - List item 2
        
        [Link to Apple](https://apple.com)
        
        ```swift
        func hello() {
            print("Hello, world!")
        }
        ```
        """)
        
        CodeBlockView(code: """
        func hello() {
            print("Hello, world!")
        }
        """, language: "swift")
    }
    .padding()
}
