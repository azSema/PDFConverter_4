import SwiftUI
import Combine
import UniformTypeIdentifiers
import PDFKit

@MainActor
final class SignViewModel: ObservableObject {
    
    @Published var documents: [DocumentDTO] = []
    @Published var isLoading = false
    @Published var showFilePicker = false
    @Published var showDocumentDetail = false
    @Published var editingDocument: DocumentDTO?
    
    private let storage: PDFConverterStorage
    private var cancellables = Set<AnyCancellable>()
    
    init(storage: PDFConverterStorage) {
        self.storage = storage
        setupBindings()
    }
    
    private func setupBindings() {
        storage.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: &$documents)
    }
    
    // MARK: - Public Methods
    
    func loadDocuments() {
        isLoading = true
        storage.loadDocuments()
        isLoading = false
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