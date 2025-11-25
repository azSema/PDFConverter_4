import UIKit
import PDFKit
import Foundation
import Combine

enum ConversionError: LocalizedError {
    case processingFailed
    case unsupportedFormat
    case fileSystemError
    case documentCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .processingFailed:
            return "Failed to process the document conversion"
        case .unsupportedFormat:
            return "The file format is not supported"
        case .fileSystemError:
            return "Unable to access file system"
        case .documentCreationFailed:
            return "Failed to create the converted document"
        }
    }
}

@MainActor
final class DocumentConversionService: ObservableObject {
    
    @Published var conversionProgress: Double = 0.0
    @Published var isProcessing: Bool = false
    
    private let processingQueue = DispatchQueue(label: "conversion.queue", qos: .userInitiated)
    private let fileManager = FileManager.default
    
    // MARK: - Public Methods
    
    func performTextToPDFConversion(content: String, documentName: String) async throws -> URL {
        return try await executeConversion {
            return try self.createPDFFromTextContent(content, title: documentName)
        }
    }
    
    func performImageCollectionToPDFConversion(imageCollection: [UIImage], documentName: String) async throws -> URL {
        return try await executeConversion {
            return try self.assemblePDFFromImageCollection(imageCollection, title: documentName)
        }
    }
    
    func performPDFToImageCollectionConversion(pdfFileURL: URL, imageQuality: CGFloat = 150.0) async throws -> [URL] {
        return try await executeConversion {
            return try self.extractImageCollectionFromPDF(pdfFileURL, quality: imageQuality)
        }
    }
    
    // MARK: - Private Conversion Methods
    
    private func createPDFFromTextContent(_ textContent: String, title: String) throws -> URL {
        let documentBounds = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let pdfFormat = UIGraphicsPDFRendererFormat()
        pdfFormat.documentInfo = [
            kCGPDFContextTitle: title,
            kCGPDFContextCreator: "LiteConvert",
            kCGPDFContextSubject: "Text Document Conversion"
        ] as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: documentBounds, format: pdfFormat)
        
        let pdfData = renderer.pdfData { rendererContext in
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black
            ]
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2.0
            paragraphStyle.paragraphSpacing = 6.0
            
            let styledTextAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let contentFrame = CGRect(x: 50, y: 50, width: documentBounds.width - 100, height: documentBounds.height - 100)
            
            rendererContext.beginPage()
            textContent.draw(in: contentFrame, withAttributes: styledTextAttributes)
        }
        
        let destinationURL = generateTemporaryFileLocation(withExtension: "pdf")
        try pdfData.write(to: destinationURL)
        
        return destinationURL
    }
    
    private func assemblePDFFromImageCollection(_ imageCollection: [UIImage], title: String) throws -> URL {
        let documentFormat = UIGraphicsPDFRendererFormat()
        documentFormat.documentInfo = [
            kCGPDFContextTitle: title,
            kCGPDFContextCreator: "LiteConvert"
        ] as [String: Any]
        
        let pageSize = CGSize(width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: documentFormat)
        
        let compiledPDFData = renderer.pdfData { context in
            for currentImage in imageCollection {
                context.beginPage()
                
                let imageAspectRatio = currentImage.size.width / currentImage.size.height
                let pageAspectRatio = pageSize.width / pageSize.height
                
                let scaledImageSize: CGSize
                let imagePosition: CGPoint
                
                if imageAspectRatio > pageAspectRatio {
                    // Image is wider than page
                    let scaledWidth = pageSize.width - 40
                    let scaledHeight = scaledWidth / imageAspectRatio
                    scaledImageSize = CGSize(width: scaledWidth, height: scaledHeight)
                    imagePosition = CGPoint(x: 20, y: (pageSize.height - scaledHeight) / 2)
                } else {
                    // Image is taller than page
                    let scaledHeight = pageSize.height - 40
                    let scaledWidth = scaledHeight * imageAspectRatio
                    scaledImageSize = CGSize(width: scaledWidth, height: scaledHeight)
                    imagePosition = CGPoint(x: (pageSize.width - scaledWidth) / 2, y: 20)
                }
                
                let imageRect = CGRect(origin: imagePosition, size: scaledImageSize)
                currentImage.draw(in: imageRect)
            }
        }
        
        let outputLocation = generateTemporaryFileLocation(withExtension: "pdf")
        try compiledPDFData.write(to: outputLocation)
        
        return outputLocation
    }
    
    private func extractImageCollectionFromPDF(_ pdfURL: URL, quality: CGFloat) throws -> [URL] {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw ConversionError.unsupportedFormat
        }
        
        var generatedImageURLs = [URL]()
        let totalPageCount = pdfDocument.pageCount
        
        for pageNumber in 0..<totalPageCount {
            guard let currentPage = pdfDocument.page(at: pageNumber) else { continue }
            
            let pageMediaBox = currentPage.bounds(for: .mediaBox)
            let scaleFactor = quality / 72.0
            let scaledSize = CGSize(
                width: pageMediaBox.width * scaleFactor,
                height: pageMediaBox.height * scaleFactor
            )
            
            let imageRenderer = UIGraphicsImageRenderer(size: scaledSize)
            let pageImage = imageRenderer.image { renderingContext in
                UIColor.white.setFill()
                renderingContext.fill(CGRect(origin: .zero, size: scaledSize))
                
                renderingContext.cgContext.translateBy(x: 0, y: scaledSize.height)
                renderingContext.cgContext.scaleBy(x: scaleFactor, y: -scaleFactor)
                
                currentPage.draw(with: .mediaBox, to: renderingContext.cgContext)
            }
            
            guard let imageData = pageImage.jpegData(compressionQuality: 0.9) else { continue }
            
            let imageFileURL = generateTemporaryFileLocation(withExtension: "jpg")
            try imageData.write(to: imageFileURL)
            generatedImageURLs.append(imageFileURL)
        }
        
        return generatedImageURLs
    }
    
    // MARK: - Helper Methods
    
    private func executeConversion<T>(_ conversionOperation: @escaping () throws -> T) async throws -> T {
        isProcessing = true
        conversionProgress = 0.0
        
        defer {
            Task { @MainActor in
                self.isProcessing = false
                self.conversionProgress = 0.0
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    // Simulate processing stages
                    self.updateProgress(0.25)
                    Thread.sleep(forTimeInterval: 0.2)
                    
                    let result = try conversionOperation()
                    
                    self.updateProgress(0.75)
                    Thread.sleep(forTimeInterval: 0.1)
                    
                    self.updateProgress(1.0)
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func updateProgress(_ value: Double) {
        Task { @MainActor in
            self.conversionProgress = value
        }
    }
    
    private func generateTemporaryFileLocation(withExtension fileExtension: String) -> URL {
        let uniqueIdentifier = UUID().uuidString
        let fileName = "\(uniqueIdentifier).\(fileExtension)"
        return fileManager.temporaryDirectory.appendingPathComponent(fileName)
    }
}