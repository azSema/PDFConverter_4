import SwiftUI
import Combine
import UniformTypeIdentifiers
import PDFKit

@MainActor
final class EditViewModel: ObservableObject {
    
    @Published var documents: [DocumentDTO] = []
    @Published var isLoading = false
    @Published var showFilePicker = false
    @Published var showDocumentDetail = false
    @Published var editingDocument: DocumentDTO?
    
    // PDF Editor
    @Published var showPDFEditor = false
    @Published var selectedDocumentForEdit: DocumentDTO?
    @Published var pdfEditService = PDFEditService()
    
    weak var storage: PDFConverterStorage?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Storage will be set via updateStorage
    }
    
    func updateStorage(_ newStorage: PDFConverterStorage) {
        storage = newStorage
        setupBindings()
    }
    
    private func setupBindings() {
        cancellables.removeAll()
        
        guard let storage else { return }
        
        storage.$documents
            .map { documents in
                documents.filter { $0.type == .pdf }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.documents, on: self)
            .store(in: &cancellables)
        
        storage.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Document Management
    
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
    
    // MARK: - PDF Editor Actions
    
    func openPDFEditor(for document: DocumentDTO) {
        selectedDocumentForEdit = document
        showPDFEditor = true
    }
    
    func handleQuickEdit(_ document: DocumentDTO) {
        openPDFEditor(for: document)
    }
    
    // MARK: - Private Import Methods
    
    private func importPDFDocument(from url: URL) async throws {
        guard let storage = storage else {
            throw PDFConverterStorageError.saveFailed
        }
        
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
        guard let storage = storage else {
            throw PDFConverterStorageError.saveFailed
        }
        
        let text = try String(contentsOf: url, encoding: .utf8)
        let fileName = url.deletingPathExtension().lastPathComponent
        
        let document = try await storage.convertTextToPDF(text, fileName: fileName)
        // Document is automatically saved in convertTextToPDF
    }
    
    private func importImageDocument(from url: URL) async throws {
        guard let storage = storage else {
            throw PDFConverterStorageError.saveFailed
        }
        
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            throw PDFConverterStorageError.conversionFailed
        }
        
        let fileName = url.deletingPathExtension().lastPathComponent
        let document = try await storage.convertImagesToPDF([image], fileName: fileName)
        // Document is automatically saved in convertImagesToPDF
    }
}
