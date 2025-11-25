import Foundation
import PDFKit
import UIKit
import Combine

@MainActor
final class AnnotationsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var annotations: [IdentifiablePDFAnnotation] = []
    @Published var hasUnsavedAnnotations = false
    
    // Current document context
    private var currentDocument: PDFDocument?
    private var currentPageIndex: Int = 0
    
    // MARK: - Configuration
    
    func configure(document: PDFDocument, pageIndex: Int) {
        self.currentDocument = document
        self.currentPageIndex = pageIndex
        loadAnnotationsForCurrentPage()
    }
    
    func updateCurrentPage(_ pageIndex: Int) {
        self.currentPageIndex = pageIndex
        loadAnnotationsForCurrentPage()
    }
    
    private func loadAnnotationsForCurrentPage() {
        guard let document = currentDocument,
              let page = document.page(at: currentPageIndex) else { return }
        
        // Clear existing annotations
        annotations.removeAll()
        
        // Load annotations from PDF page
        for annotation in page.annotations {
            let identifiableAnnotation = IdentifiablePDFAnnotation(
                annotation: annotation,
                position: annotation.bounds.origin,
                midPosition: CGPoint(x: annotation.bounds.midX, y: annotation.bounds.midY),
                boundingBox: annotation.bounds,
                scale: 1.0
            )
            annotations.append(identifiableAnnotation)
        }
        
        print("📋 Loaded \(annotations.count) annotations for page \(currentPageIndex)")
    }
    
    // MARK: - Highlight Annotations
    
    func addHighlightAnnotation(selectedText: String, bounds: CGRect) {
        guard let document = currentDocument,
              let page = document.page(at: currentPageIndex) else { return }
        
        // Create highlight annotation
        let highlight = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
        highlight.color = UIColor.yellow.withAlphaComponent(0.3)
        highlight.contents = selectedText
        
        // Add to page
        page.addAnnotation(highlight)
        
        // Create identifiable annotation
        let identifiableAnnotation = IdentifiablePDFAnnotation(
            annotation: highlight,
            position: bounds.origin,
            midPosition: CGPoint(x: bounds.midX, y: bounds.midY),
            boundingBox: bounds,
            scale: 1.0
        )
        
        // Update local state
        annotations.append(identifiableAnnotation)
        hasUnsavedAnnotations = true
        
        print("🖍️ Added highlight annotation: \(selectedText.prefix(30))...")
    }
    
    // MARK: - Image Annotations
    
    func addImageAnnotation(image: UIImage, at position: CGPoint, in geometrySize: CGSize) {
        guard let document = currentDocument,
              let page = document.page(at: currentPageIndex) else { return }
        
        let bounds = calculateTransformedLocation(
            location: position,
            geometrySize: geometrySize,
            contentSize: image.size
        )
        
        let imageAnnotation = ImageAnnotation(bounds: bounds, image: image)
        page.addAnnotation(imageAnnotation)
        
        let identifiableAnnotation = IdentifiablePDFAnnotation(
            annotation: imageAnnotation,
            position: position,
            midPosition: CGPoint(x: bounds.midX, y: bounds.midY),
            boundingBox: bounds,
            scale: 1.0
        )
        
        annotations.append(identifiableAnnotation)
        hasUnsavedAnnotations = true
        
        print("✅ Added image annotation at: \(bounds)")
    }
    
    // MARK: - Document Management
    
    func saveAnnotations() {
        // Annotations are already saved to PDF pages
        hasUnsavedAnnotations = false
        print("💾 Annotations saved")
    }
    
    func discardAnnotations() {
        // Reload annotations from current page
        loadAnnotationsForCurrentPage()
        hasUnsavedAnnotations = false
        print("🔄 Annotations discarded")
    }
    
    func removeHighlightAnnotation(_ annotation: IdentifiablePDFAnnotation) {
        guard let document = currentDocument,
              let page = document.page(at: currentPageIndex) else { return }
        
        // Remove from PDF page
        page.removeAnnotation(annotation.annotation)
        
        // Remove from local state
        annotations.removeAll { $0.id == annotation.id }
        hasUnsavedAnnotations = true
        
        print("🗑️ Removed annotation")
    }
    
    // MARK: - Helper Methods
    
    private func calculateTransformedLocation(location: CGPoint, geometrySize: CGSize, contentSize: CGSize) -> CGRect {
        guard let page = currentDocument?.page(at: currentPageIndex) else {
            return CGRect(origin: location, size: contentSize)
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        
        // Convert from view coordinates to PDF coordinates
        let scaleX = pageRect.width / geometrySize.width
        let scaleY = pageRect.height / geometrySize.height
        
        let pdfX = location.x * scaleX
        let pdfY = pageRect.height - (location.y * scaleY) // Flip Y coordinate
        
        return CGRect(
            x: pdfX,
            y: pdfY - contentSize.height,
            width: contentSize.width,
            height: contentSize.height
        )
    }
}