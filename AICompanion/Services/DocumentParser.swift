
//
//  DocumentParser.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import PDFKit
import NaturalLanguage
import ZIPFoundation
import UniformTypeIdentifiers

/// Protocol for document parsers
protocol DocumentParser {
    /// Extract text from a document
    /// - Parameters:
    ///   - url: URL of the document
    ///   - progressHandler: Handler for reporting progress (0.0 to 1.0)
    /// - Returns: Extracted text
    func extractText(from url: URL, progressHandler: ((Double) -> Void)?) async throws -> String
    
    /// Check if the parser can handle a file
    /// - Parameter url: URL of the file
    /// - Returns: Whether the parser can handle the file
    func canHandle(url: URL) -> Bool
}

/// Factory for creating document parsers
class DocumentParserFactory {
    /// Create a parser for a file extension
    /// - Parameter fileExtension: File extension
    /// - Returns: A parser that can handle the file extension, or nil if none is available
    func createParser(for fileExtension: String) -> DocumentParser? {
        switch fileExtension.lowercased() {
        case "pdf":
            return PDFParser()
        case "docx", "doc":
            return DOCXParser()
        case "txt", "md", "markdown", "rtf", "rtfd":
            return TextParser()
        case "html", "htm":
            return HTMLParser()
        default:
            return nil
        }
    }
    
    /// Create a parser for a file URL
    /// - Parameter url: File URL
    /// - Returns: A parser that can handle the file, or nil if none is available
    func createParser(for url: URL) -> DocumentParser? {
        // Try to determine the file type
        if let fileType = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let utType = UTType(fileType) {
            
            // Check for PDF
            if utType.conforms(to: .pdf) {
                return PDFParser()
            }
            
            // Check for Word documents
            if utType.conforms(to: UTType("org.openxmlformats.wordprocessingml.document")!) ||
               utType.conforms(to: UTType("com.microsoft.word.doc")!) {
                return DOCXParser()
            }
            
            // Check for text documents
            if utType.conforms(to: .plainText) || utType.conforms(to: .rtf) {
                return TextParser()
            }
            
            // Check for HTML
            if utType.conforms(to: .html) {
                return HTMLParser()
            }
        }
        
        // Fall back to extension
        return createParser(for: url.pathExtension)
    }
}

/// Parser for PDF documents
class PDFParser: DocumentParser {
    func extractText(from url: URL, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ParserError.failedToLoadDocument
        }
        
        let pageCount = pdfDocument.pageCount
        var extractedText = ""
        
        for i in 0..<pageCount {
            // Report progress
            progressHandler?(Double(i) / Double(pageCount))
            
            // Get page
            guard let page = pdfDocument.page(at: i) else {
                continue
            }
            
            // Extract text
            if let pageText = page.string {
                extractedText += pageText
                
                // Add page separator if not the last page
                if i < pageCount - 1 {
                    extractedText += "\n\n--- Page \(i + 1) ---\n\n"
                }
            }
        }
        
        // Report completion
        progressHandler?(1.0)
        
        return extractedText
    }
    
    func canHandle(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "pdf"
    }
}

/// Parser for DOCX documents
class DOCXParser: DocumentParser {
    func extractText(from url: URL, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        // Report initial progress
        progressHandler?(0.1)
        
        // Create a temporary directory for extraction
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // Clean up temporary directory
            try? fileManager.removeItem(at: tempDir)
        }
        
        do {
            // DOCX files are ZIP archives, so unzip it
            progressHandler?(0.2)
            try fileManager.unzipItem(at: url, to: tempDir)
            
            // Look for document.xml
            progressHandler?(0.4)
            let documentXmlPath = tempDir.appendingPathComponent("word/document.xml")
            
            guard fileManager.fileExists(atPath: documentXmlPath.path) else {
                throw ParserError.documentXmlNotFound
            }
            
            // Load XML data
            progressHandler?(0.6)
            let xmlData = try Data(contentsOf: documentXmlPath)
            
            // Parse XML to extract text
            progressHandler?(0.8)
            let text = try extractTextFromDocumentXml(xmlData)
            
            // Report completion
            progressHandler?(1.0)
            
            return text
        } catch {
            throw ParserError.failedToParseDocument(error)
        }
    }
    
    /// Extract text from document.xml
    /// - Parameter xmlData: XML data
    /// - Returns: Extracted text
    private func extractTextFromDocumentXml(_ xmlData: Data) throws -> String {
        let xmlParser = XMLParser(data: xmlData)
        let delegate = DOCXXMLParserDelegate()
        xmlParser.delegate = delegate
        
        if xmlParser.parse() {
            return delegate.extractedText
        } else if let error = xmlParser.parserError {
            throw ParserError.failedToParseXml(error)
        } else {
            throw ParserError.unknownParsingError
        }
    }
    
    func canHandle(url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        return pathExtension == "docx" || pathExtension == "doc"
    }
}

/// XML parser delegate for DOCX documents
class DOCXXMLParserDelegate: NSObject, XMLParserDelegate {
    var extractedText = ""
    private var currentElement = ""
    private var isInTextElement = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        // In DOCX, text is contained in <w:t> elements
        if elementName == "w:t" {
            isInTextElement = true
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "w:t" {
            isInTextElement = false
        }
        
        // Add paragraph breaks
        if elementName == "w:p" {
            extractedText += "\n"
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInTextElement {
            extractedText += string
        }
    }
}

/// Parser for plain text documents
class TextParser: DocumentParser {
    func extractText(from url: URL, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        // Report initial progress
        progressHandler?(0.2)
        
        do {
            // Load text
            let text = try String(contentsOf: url, encoding: .utf8)
            
            // Report completion
            progressHandler?(1.0)
            
            return text
        } catch {
            // Try other encodings if UTF-8 fails
            do {
                let text = try String(contentsOf: url, encoding: .isoLatin1)
                progressHandler?(1.0)
                return text
            } catch {
                throw ParserError.failedToLoadDocument
            }
        }
    }
    
    func canHandle(url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        return ["txt", "md", "markdown", "rtf", "rtfd"].contains(pathExtension)
    }
}

/// Parser for HTML documents
class HTMLParser: DocumentParser {
    func extractText(from url: URL, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        // Report initial progress
        progressHandler?(0.2)
        
        do {
            // Load HTML
            let html = try String(contentsOf: url, encoding: .utf8)
            
            // Report progress
            progressHandler?(0.5)
            
            // Extract text from HTML
            let text = extractTextFromHTML(html)
            
            // Report completion
            progressHandler?(1.0)
            
            return text
        } catch {
            throw ParserError.failedToLoadDocument
        }
    }
    
    /// Extract text from HTML
    /// - Parameter html: HTML content
    /// - Returns: Extracted text
    private func extractTextFromHTML(_ html: String) -> String {
        // Simple regex-based HTML tag removal
        // For a production app, consider using a proper HTML parser
        var text = html
        
        // Remove scripts
        text = text.replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive, .dotMatchesLineSeparators])
        
        // Remove styles
        text = text.replacingOccurrences(of: "<style[^>]*>.*?</style>", with: "", options: [.regularExpression, .caseInsensitive, .dotMatchesLineSeparators])
        
        // Remove HTML comments
        text = text.replacingOccurrences(of: "<!--.*?-->", with: "", options: [.regularExpression, .caseInsensitive, .dotMatchesLineSeparators])
        
        // Replace line breaks and paragraphs with newlines
        text = text.replacingOccurrences(of: "<br[^>]*>|<p[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])
        
        // Replace closing paragraph tags with newlines
        text = text.replacingOccurrences(of: "</p>", with: "\n", options: [.caseInsensitive])
        
        // Replace headings with newlines and text
        text = text.replacingOccurrences(of: "<h[1-6][^>]*>", with: "\n\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "</h[1-6]>", with: "\n\n", options: [.regularExpression, .caseInsensitive])
        
        // Remove all other HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        
        // Normalize whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Trim whitespace
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
    
    func canHandle(url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        return pathExtension == "html" || pathExtension == "htm"
    }
}

/// Parser errors
enum ParserError: Error, LocalizedError {
    case failedToLoadDocument
    case documentXmlNotFound
    case failedToParseDocument(Error)
    case failedToParseXml(Error)
    case unknownParsingError
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadDocument:
            return "Failed to load document"
        case .documentXmlNotFound:
            return "Document XML not found"
        case .failedToParseDocument(let error):
            return "Failed to parse document: \(error.localizedDescription)"
        case .failedToParseXml(let error):
            return "Failed to parse XML: \(error.localizedDescription)"
        case .unknownParsingError:
            return "Unknown parsing error"
        }
    }
}
