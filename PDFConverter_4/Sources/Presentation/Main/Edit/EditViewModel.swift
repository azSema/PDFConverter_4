import SwiftUI
import Combine
import UniformTypeIdentifiers
import PDFKit

@MainActor
final class EditViewModel: ObservableObject {
    
    @Published var documents: [DocumentDTO] = []
    @Published var selectedDocuments: Set<String> = []
    @Published var isLoading = false
    @Published var showFilePicker = false
    @Published var editingDocument: DocumentDTO?
    @Published var showDocumentDetail = false
    
    private let storage: PDFConverterStorage
    private var cancellables = Set<AnyCancellable>()
    
    init(storage: PDFConverterStorage) {
        self.storage = storage
        setupBindings()
        loadDocuments()
    }
    
    private func setupBindings() {
        storage.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: \.documents, on: self)
            .store(in: &cancellables)
        
        storage.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadDocuments() {
        storage.loadDocuments()
    }
    
    func handleFileSelection() {
        showFilePicker = true
    }
    
    func handleFileImport(url: URL) {
        Task {
            do {
                let fileExtension = url.pathExtension.lowercased()
                
                switch fileExtension {
                case "pdf":
                    try await importPDFDocument(from: url)
                case "txt", "text":
                    try await importTextDocument(from: url)
                case "jpg", "jpeg", "png", "heic":
                    try await importImageDocument(from: url)
                default:
                    print("Unsupported file type: \(fileExtension)")
                }
                
            } catch {
                print("Failed to import document: \(error)")
            }
        }
    }
    
    func openDocument(_ document: DocumentDTO) {
        editingDocument = document
        showDocumentDetail = true
    }
    
    func deleteDocuments() {
        for documentId in selectedDocuments {
            if let document = documents.first(where: { $0.id == documentId }) {
                storage.removeDocument(document)
            }
        }
        selectedDocuments.removeAll()
    }
    
    func toggleDocumentSelection(_ documentId: String) {
        if selectedDocuments.contains(documentId) {
            selectedDocuments.remove(documentId)
        } else {
            selectedDocuments.insert(documentId)
        }
    }
    
    func clearSelection() {
        selectedDocuments.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func importPDFDocument(from url: URL) async throws {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFConverterStorageError.invalidPDF
        }
        
        let document = DocumentDTO(
            pdf: pdfDocument,
            name: url.deletingPathExtension().lastPathComponent,
            type: .pdf,
            url: url
        )
        
        try await storage.saveDocument(document)
    }
    
    private func importTextDocument(from url: URL) async throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        let fileName = url.deletingPathExtension().lastPathComponent
        
        let document = try await storage.convertTextToPDF(text, fileName: fileName)
        // Document is automatically saved in convertTextToPDF
    }
    
    private func importImageDocument(from url: URL) async throws {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            throw PDFConverterStorageError.conversionFailed
        }
        
        let fileName = url.deletingPathExtension().lastPathComponent
        let document = try await storage.convertImagesToPDF([image], fileName: fileName)
        // Document is automatically saved in convertImagesToPDF
    }
}

// MARK: - Edit Types

enum EditableFileType: String, CaseIterable {
    case pdf = "PDF"
    case image = "Image" 
    case text = "Text"
    
    var allowedContentTypes: [UTType] {
        switch self {
        case .pdf:
            return [.pdf]
        case .image:
            return [.image]
        case .text:
            return [.plainText, .text]
        }
    }
    
    var iconName: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .image:
            return "photo.fill"
        case .text:
            return "doc.text.fill"
        }
    }
}