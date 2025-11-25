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
    
    // Signature functionality
    @Published var showSignatureCreator = false
    @Published var showQuickSignMenu = false
    @Published var selectedDocumentForSigning: DocumentDTO?
    @Published var signatureStorage = SignatureStorage()
    
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
        
        guard let storage = storage else { return }
        
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
    
    // MARK: - Quick Signature Actions
    
    func showQuickSignOptions(for document: DocumentDTO) {
        selectedDocumentForSigning = document
        showQuickSignMenu = true
    }
    
    func createNewSignature(for document: DocumentDTO) {
        selectedDocumentForSigning = document
        showSignatureCreator = true
    }
    
    func applySignature(_ signature: UIImage, to document: DocumentDTO) {
        Task {
            do {
                let signedDocument = try await addSignatureToPDF(document, signature: signature)
                print("✅ Signature applied to document: \(signedDocument.name)")
                
                // Refresh documents list
                storage?.loadDocuments()
                
            } catch {
                print("❌ Failed to apply signature: \(error)")
            }
        }
    }
    
    func applyExistingSignature(_ savedSignature: SavedSignature, to document: DocumentDTO) {
        guard let signatureImage = signatureStorage.loadSignatureImage(savedSignature) else {
            print("❌ Failed to load signature image")
            return
        }
        
        applySignature(signatureImage, to: document)
    }
    
    // MARK: - Quick Signature Creation
    
    func handleQuickSignatureCreated(_ signature: UIImage) {
        guard let document = selectedDocumentForSigning else { return }
        
        showSignatureCreator = false
        selectedDocumentForSigning = nil
        
        // Apply signature directly
        applySignature(signature, to: document)
    }
    
    // MARK: - PDF Signature Addition
    
    private func addSignatureToPDF(_ document: DocumentDTO, signature: UIImage) async throws -> DocumentDTO {
        guard let pdfDocument = document.pdf,
              let storage = storage else {
            throw PDFConverterStorageError.saveFailed
        }
        
        // Get first page for signature placement
        guard let firstPage = pdfDocument.page(at: 0) else {
            throw PDFConverterStorageError.invalidPDF
        }
        
        let pageRect = firstPage.bounds(for: .mediaBox)
        
        // Place signature in bottom right corner
        let signatureWidth: CGFloat = 120
        let signatureHeight: CGFloat = 60
        let margin: CGFloat = 20
        
        let signatureRect = CGRect(
            x: pageRect.width - signatureWidth - margin,
            y: margin, // Bottom of page (PDF coordinates)
            width: signatureWidth,
            height: signatureHeight
        )
        
        // Create image annotation
        let annotation = ImageAnnotation(bounds: signatureRect, image: signature)
        firstPage.addAnnotation(annotation)
        
        // Save as new document
        let fileName = "\(document.name)_signed_\(Date().timeIntervalSince1970)"
        let signedDocument = try await storage.savePDFDocument(pdfDocument, name: fileName)
        
        return signedDocument
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