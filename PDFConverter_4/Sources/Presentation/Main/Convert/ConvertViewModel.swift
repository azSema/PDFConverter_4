import SwiftUI
import Combine
import PDFKit

@MainActor
final class ConvertViewModel: ObservableObject {
    
    @Published var selectedOption: ConvertOption = .textToPDF
    @Published var selectedFileType: FileType? = nil
    @Published var searchText = ""
    @Published var isConverting = false
    @Published var convertProgress: Double = 0
    @Published var showFilePicker = false
    @Published var showImagePicker = false
    @Published var showTextFilePicker = false
    @Published var showTextEditor = false
    @Published var convertedDocument: DocumentDTO?
    @Published var showSuccessAlert = false
    @Published var conversionError: String?
    @Published var documents: [DocumentDTO] = []
    @Published var showPDFPreview = false
    @Published var selectedDocument: DocumentDTO?
    
    weak var storage: PDFConverterStorage?
    private let conversionService = DocumentConversionService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredDocuments: [DocumentDTO] {
        var filtered = documents
        
        // Фильтр по типу файла
        if let selectedType = selectedFileType {
            filtered = filtered.filter { $0.type == selectedType }
        }
        
        // Фильтр по поисковому тексту
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let searchQuery = searchText.lowercased()
            filtered = filtered.filter { document in
                document.name.lowercased().contains(searchQuery)
            }
        }
        
        return filtered
    }
    
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
            .receive(on: DispatchQueue.main)
            .assign(to: \.documents, on: self)
            .store(in: &cancellables)
        
        conversionService.$conversionProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$convertProgress)
        
        conversionService.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConverting)
    }
    
    func handleTextToPDF() {
        showTextFilePicker = true
    }
    
    func handleTextFileImport(url: URL) {
        Task {
            await convertTextFileToPDF(fileURL: url)
        }
    }
    
    func handleImageToPDF() {
        showImagePicker = true
    }
    
    func handlePDFToImage() {
        showFilePicker = true
    }
    
    func convertTextToPDF(text: String, fileName: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            conversionError = "Text cannot be empty"
            return
        }
        
        guard let storage = storage else {
            conversionError = "Storage not available"
            return
        }
        
        do {
            let convertedFileURL = try await conversionService.performTextToPDFConversion(
                content: text, 
                documentName: fileName
            )
            
            // Create PDF document from converted file
            guard let pdfDocument = PDFDocument(url: convertedFileURL) else {
                conversionError = "Failed to create PDF document"
                return
            }
            
            let document = DocumentDTO(
                id: UUID().uuidString,
                pdf: pdfDocument,
                name: fileName,
                type: .pdf,
                date: Date(),
                url: convertedFileURL,
                isFavorite: false
            )
            
            try await storage.saveDocument(document)
            convertedDocument = document
            showSuccessAlert = true
            
        } catch {
            conversionError = error.localizedDescription
        }
    }
    
    func convertTextFileToPDF(fileURL: URL) async {
        guard let storage = storage else {
            conversionError = "Storage not available"
            return
        }
        
        do {
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            
            let convertedFileURL = try await conversionService.performTextToPDFConversion(
                content: text, 
                documentName: fileName
            )
            
            // Create PDF document from converted file
            guard let pdfDocument = PDFDocument(url: convertedFileURL) else {
                conversionError = "Failed to create PDF document"
                return
            }
            
            let document = DocumentDTO(
                id: UUID().uuidString,
                pdf: pdfDocument,
                name: fileName,
                type: .pdf,
                date: Date(),
                url: convertedFileURL,
                isFavorite: false
            )
            
            try await storage.saveDocument(document)
            convertedDocument = document
            showSuccessAlert = true
            
        } catch {
            conversionError = error.localizedDescription
        }
    }
    
    func convertImagesToPDF(images: [UIImage], fileName: String) async {
        guard !images.isEmpty else {
            conversionError = "No images selected"
            return
        }
        
        guard let storage = storage else {
            conversionError = "Storage not available"
            return
        }
        
        do {
            let convertedFileURL = try await conversionService.performImageCollectionToPDFConversion(
                imageCollection: images, 
                documentName: fileName
            )
            
            // Create PDF document from converted file
            guard let pdfDocument = PDFDocument(url: convertedFileURL) else {
                conversionError = "Failed to create PDF document"
                return
            }
            
            let document = DocumentDTO(
                id: UUID().uuidString,
                pdf: pdfDocument,
                name: fileName,
                type: .pdf,
                date: Date(),
                url: convertedFileURL,
                isFavorite: false
            )
            
            try await storage.saveDocument(document)
            convertedDocument = document
            showSuccessAlert = true
            
        } catch {
            conversionError = error.localizedDescription
        }
    }
    
    func convertPDFToImages(document: DocumentDTO) async -> [UIImage]? {
        guard let pdfURL = document.url else {
            conversionError = "PDF file not found"
            return nil
        }
        
        do {
            let imageURLs = try await conversionService.performPDFToImageCollectionConversion(
                pdfFileURL: pdfURL,
                imageQuality: 150.0
            )
            
            // Convert URLs to UIImages
            var resultImages: [UIImage] = []
            for imageURL in imageURLs {
                if let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: imageData) {
                    resultImages.append(image)
                }
            }
            
            if !resultImages.isEmpty {
                showSuccessAlert = true
            }
            
            return resultImages
            
        } catch {
            conversionError = error.localizedDescription
            return nil
        }
    }
    
    func convertPDFToImages(fileURL: URL) async {
        guard let storage = storage else {
            conversionError = "Storage not available"
            return
        }
        
        do {
            let imageURLs = try await conversionService.performPDFToImageCollectionConversion(
                pdfFileURL: fileURL,
                imageQuality: 150.0
            )
            
            // Save each image as separate document
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            
            for (index, imageURL) in imageURLs.enumerated() {
                if let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: imageData) {
                    
                    let imageDocument = DocumentDTO(
                        id: UUID().uuidString,
                        pdf: nil,
                        name: "\(fileName)_page_\(index + 1)",
                        type: .image,
                        date: Date(),
                        url: imageURL,
                        isFavorite: false,
                        sourcePDFURL: fileURL // Сохраняем ссылку на исходный PDF
                    )
                    
                    try await storage.saveDocument(imageDocument)
                }
            }
            
            showSuccessAlert = true
            
        } catch {
            conversionError = error.localizedDescription
        }
    }
    
    func dismissError() {
        conversionError = nil
    }
    
    func dismissSuccess() {
        showSuccessAlert = false
    }
    
    func openDocument(_ document: DocumentDTO) {
        selectedDocument = document
        showPDFPreview = true
    }
}


