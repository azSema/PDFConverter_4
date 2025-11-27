import Foundation
import PDFKit
import SwiftUI
import Combine

struct DocumentMetadata: Codable {
    let id: String
    var name: String
    var isFavorite: Bool
    let dateCreated: Date
    let type: FileType
    let sourcePDFURL: URL?
    
    init(id: String, name: String, isFavorite: Bool = false, dateCreated: Date = Date(), type: FileType = .pdf, sourcePDFURL: URL? = nil) {
        self.id = id
        self.name = name
        self.isFavorite = isFavorite
        self.dateCreated = dateCreated
        self.type = type
        self.sourcePDFURL = sourcePDFURL
    }
}

@MainActor
final class PDFConverterStorage: ObservableObject {
    
    @Published var documents: [DocumentDTO] = []
    @Published var isLoading = false
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let metadataDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PDFConverter", isDirectory: true)
        
        metadataDirectory = documentsDirectory.appendingPathComponent("Metadata", isDirectory: true)
        
        createDocumentsDirectoryIfNeeded()
        loadDocuments()
    }
    
    // MARK: - Public Methods
    
    func addDocument(_ document: DocumentDTO) {
        documents.append(document)
    }
    
    func removeDocument(_ document: DocumentDTO) {
        documents.removeAll { $0.id == document.id }
        
        // Remove PDF file
        if let url = document.url, url.path.contains("PDFConverter") {
            try? fileManager.removeItem(at: url)
        }
        
        // Remove metadata file
        let metadataURL = metadataDirectory.appendingPathComponent("\(document.id).json")
        try? fileManager.removeItem(at: metadataURL)
    }
    
    func toggleFavorite(_ document: DocumentDTO) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index].isFavorite.toggle()
        
        // Update metadata
        try? saveDocumentMetadata(documents[index])
    }
    
    func renameDocument(_ document: DocumentDTO, to newName: String) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index].name = newName
        
        // Update metadata
        try? saveDocumentMetadata(documents[index])
    }
    
    func saveDocument(_ document: DocumentDTO) async throws {
        let fileName: String
        let fileURL: URL
        
        switch document.type {
        case .pdf:
            guard let pdfDocument = document.pdf else {
                throw PDFConverterStorageError.invalidPDF
            }
            fileName = "\(document.id).pdf"
            fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            // Save PDF to documents directory
            guard pdfDocument.write(to: fileURL) else {
                throw PDFConverterStorageError.saveFailed
            }
            
        case .image:
            guard let existingURL = document.url else {
                throw PDFConverterStorageError.saveFailed
            }
            fileName = "\(document.id).jpg"
            fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            // Copy image file to documents directory
            try FileManager.default.copyItem(at: existingURL, to: fileURL)
            
        case .text:
            fileName = "\(document.id).txt"
            fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            if let existingURL = document.url {
                // Copy text file to documents directory
                try FileManager.default.copyItem(at: existingURL, to: fileURL)
            } else {
                throw PDFConverterStorageError.saveFailed
            }
        }
        
        // Update document with file URL
        var updatedDocument = document
        updatedDocument.url = fileURL
        
        // Save metadata
        try saveDocumentMetadata(updatedDocument)
        
        // Add or update in documents array
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = updatedDocument
        } else {
            documents.append(updatedDocument)
        }
    }
    
    func convertTextToPDF(_ text: String, fileName: String) async throws -> DocumentDTO {
        let pdfDocument = PDFDocument()
        let page = PDFPage()
        
        // Create attributed string with proper formatting
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        page.setValue(attributedText, forKey: "contents")
        
        pdfDocument.insert(page, at: 0)
        
        let documentDTO = DocumentDTO(
            id: UUID().uuidString,
            pdf: pdfDocument,
            name: fileName,
            type: .pdf,
            date: Date(),
            url: nil,
            isFavorite: false
        )
        
        try await saveDocument(documentDTO)
        return documentDTO
    }
    
    func convertImagesToPDF(_ images: [UIImage], fileName: String) async throws -> DocumentDTO {
        print("🔄 Converting \(images.count) images to PDF with name: \(fileName)")
        
        let pdfDocument = PDFDocument()
        
        for (index, image) in images.enumerated() {
            if let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: index)
                print("✅ Added page \(index + 1) to PDF")
            } else {
                print("❌ Failed to create PDF page from image \(index + 1)")
            }
        }
        
        guard pdfDocument.pageCount > 0 else {
            print("❌ PDF document has no pages")
            throw PDFConverterStorageError.conversionFailed
        }
        
        let documentDTO = DocumentDTO(
            id: UUID().uuidString,
            pdf: pdfDocument,
            name: fileName,
            type: .pdf,
            date: Date(),
            url: nil,
            isFavorite: false
        )
        
        print("💾 Saving document with ID: \(documentDTO.id)")
        try await saveDocument(documentDTO)
        print("✅ Document saved successfully!")
        return documentDTO
    }
    
    func convertPDFToImages(_ document: DocumentDTO) async throws -> [UIImage] {
        guard let pdfDocument = document.pdf else {
            throw PDFConverterStorageError.invalidPDF
        }
        
        var images: [UIImage] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                let pageRect = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                
                let image = renderer.image { context in
                    UIColor.white.set()
                    context.fill(pageRect)
                    
                    context.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    
                    page.draw(with: .mediaBox, to: context.cgContext)
                }
                
                images.append(image)
            }
        }
        
        return images
    }
    
    func loadDocuments() {
        isLoading = true
        
        // Clear existing documents to avoid duplicates
        documents.removeAll()
        
        // Load documents from documents directory
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            ).filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return ["pdf", "jpg", "jpeg", "png", "txt", "text"].contains(pathExtension)
            }
            
            for fileURL in fileURLs {
                if let document = createDocumentFromFile(at: fileURL) {
                    documents.append(document)
                }
            }
        } catch {
            print("Failed to load documents: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func createDocumentsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try? fileManager.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true
            )
        }
        
        if !fileManager.fileExists(atPath: metadataDirectory.path) {
            try? fileManager.createDirectory(
                at: metadataDirectory,
                withIntermediateDirectories: true
            )
        }
    }
    
    private func createDocumentFromFile(at url: URL) -> DocumentDTO? {
        let documentId = url.deletingPathExtension().lastPathComponent
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let creationDate = attributes?[.creationDate] as? Date ?? Date()
        
        // Load metadata if exists, otherwise use filename
        let metadata = loadDocumentMetadata(for: documentId)
        
        // Determine file type based on extension
        let fileExtension = url.pathExtension.lowercased()
        let fileType: FileType
        
        switch fileExtension {
        case "pdf":
            fileType = .pdf
        case "jpg", "jpeg", "png":
            fileType = .image
        case "txt", "text":
            fileType = .text
        default:
            fileType = metadata?.type ?? .pdf
        }
        
        // Load PDF document if it's a PDF file
        var pdfDocument: PDFDocument?
        if fileType == .pdf {
            pdfDocument = PDFDocument(url: url)
            guard pdfDocument != nil else { return nil }
        }
        
        return DocumentDTO(
            id: documentId,
            pdf: pdfDocument,
            name: metadata?.name ?? url.deletingPathExtension().lastPathComponent,
            type: metadata?.type ?? fileType,
            date: metadata?.dateCreated ?? creationDate,
            url: url,
            isFavorite: metadata?.isFavorite ?? false,
            sourcePDFURL: metadata?.sourcePDFURL
        )
    }
    
    private func loadBundlePDF(named fileName: String, displayName: String) {
        print("📄 Attempting to load \(fileName).pdf from Bundle...")
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "pdf") else {
            print("❌ Could not find \(fileName).pdf in Bundle")
            return
        }
        
        print("📄 Found PDF at: \(url)")
        
        guard let pdfDocument = PDFDocument(url: url) else {
            print("❌ Could not create PDFDocument from \(fileName).pdf")
            return
        }
        
        print("✅ Successfully loaded \(fileName).pdf with \(pdfDocument.pageCount) pages")
        
        let mockDocument = DocumentDTO(
            id: UUID().uuidString,
            pdf: pdfDocument,
            name: displayName,
            type: .pdf,
            date: Date().addingTimeInterval(-Double.random(in: 86400...604800)), // 1-7 days ago
            url: url,
            isFavorite: Bool.random()
        )
        
        documents.append(mockDocument)
    }
    
    // MARK: - Metadata Management
    
    private func saveDocumentMetadata(_ document: DocumentDTO) throws {
        let metadata = DocumentMetadata(
            id: document.id,
            name: document.name,
            isFavorite: document.isFavorite,
            dateCreated: document.date,
            type: document.type,
            sourcePDFURL: document.sourcePDFURL
        )
        
        let metadataURL = metadataDirectory.appendingPathComponent("\(document.id).json")
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)
    }
    
    private func loadDocumentMetadata(for documentId: String) -> DocumentMetadata? {
        let metadataURL = metadataDirectory.appendingPathComponent("\(documentId).json")
        
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(DocumentMetadata.self, from: data) else {
            return nil
        }
        
        return metadata
    }
    
    // MARK: - PDF Document Saving
    
    func savePDFDocument(_ pdfDocument: PDFDocument, name: String) async throws -> DocumentDTO {
        let fileName = "\(name).pdf"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Write PDF to file
        guard pdfDocument.write(to: fileURL) else {
            throw PDFConverterStorageError.saveFailed
        }
        
        // Create document DTO
        let document = DocumentDTO(
            pdf: pdfDocument,
            name: name,
            type: .pdf,
            date: Date(),
            url: fileURL,
            isFavorite: false
        )
        
        // Save document
        try await saveDocument(document)
        
        return document
    }
}

// MARK: - Errors

enum PDFConverterStorageError: Error, LocalizedError {
    case invalidPDF
    case saveFailed
    case loadFailed
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "Invalid PDF document"
        case .saveFailed:
            return "Failed to save PDF document"
        case .loadFailed:
            return "Failed to load PDF document"
        case .conversionFailed:
            return "Failed to convert document"
        }
    }
}
