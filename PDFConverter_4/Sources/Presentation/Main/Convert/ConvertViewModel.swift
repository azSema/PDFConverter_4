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
    @Published var showTextEditor = false
    @Published var convertedDocument: DocumentDTO?
    
    private let storage = PDFConverterStorage()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        storage.$documents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] documents in
                // Handle documents updates if needed
            }
            .store(in: &cancellables)
    }
    
    func handleTextToPDF() {
        showTextEditor = true
    }
    
    func handleImageToPDF() {
        showImagePicker = true
    }
    
    func handlePDFToImage() {
        showFilePicker = true
    }
    
    func convertTextToPDF(text: String, fileName: String) async {
        isConverting = true
        convertProgress = 0
        
        do {
            // Simulate progress
            for i in 1...5 {
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                convertProgress = Double(i) / 5.0
            }
            
            let document = try await storage.convertTextToPDF(text, fileName: fileName)
            convertedDocument = document
            
        } catch {
            print("Failed to convert text to PDF: \(error)")
        }
        
        isConverting = false
    }
    
    func convertImagesToPDF(images: [UIImage], fileName: String) async {
        isConverting = true
        convertProgress = 0
        
        do {
            // Simulate progress
            for i in 1...5 {
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                convertProgress = Double(i) / 5.0
            }
            
            let document = try await storage.convertImagesToPDF(images, fileName: fileName)
            convertedDocument = document
            
        } catch {
            print("Failed to convert images to PDF: \(error)")
        }
        
        isConverting = false
    }
    
    func convertPDFToImages(document: DocumentDTO) async -> [UIImage]? {
        isConverting = true
        convertProgress = 0
        
        do {
            // Simulate progress
            for i in 1...5 {
                try await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                convertProgress = Double(i) / 5.0
            }
            
            let images = try await storage.convertPDFToImages(document)
            isConverting = false
            return images
            
        } catch {
            print("Failed to convert PDF to images: \(error)")
            isConverting = false
            return nil
        }
    }
    
    func convertPDFToImages(fileURL: URL) async {
        isConverting = true
        convertProgress = 0
        
        do {
            // Create temporary document from file URL
            guard let pdfDocument = PDFDocument(url: fileURL) else {
                print("Failed to load PDF from URL")
                isConverting = false
                return
            }
            
            let tempDocument = DocumentDTO(
                pdf: pdfDocument,
                name: fileURL.deletingPathExtension().lastPathComponent,
                type: .pdf,
                url: fileURL
            )
            
            // Simulate progress
            for i in 1...5 {
                try await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                convertProgress = Double(i) / 5.0
            }
            
            let images = try await storage.convertPDFToImages(tempDocument)
            
            // Save images to photo library or show preview
            // This could be expanded to save images to files
            print("Converted PDF to \(images.count) images")
            
        } catch {
            print("Failed to convert PDF to images: \(error)")
        }
        
        isConverting = false
    }
}


