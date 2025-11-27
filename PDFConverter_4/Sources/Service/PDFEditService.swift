import Foundation
import Combine
import PDFKit
import UIKit

@MainActor
final class PDFEditService: ObservableObject {
    
    @Published var selectedTool: EditorTool? = nil
    @Published var isToolbarVisible = true
    @Published var pdfDocument: PDFDocument?
    @Published var currentPageIndex = 0
    
    // Image insertion
    @Published var showingImagePicker = false
    @Published var showingImageInsertMode = false
    @Published var insertionPoint: CGPoint = .zero
    @Published var insertionGeometry: CGSize = .zero
    
    // Signature
    @Published var showingSignatureCreator = false
    @Published var showingSignatureInsertMode = false
    @Published var currentSignature: UIImage?
    @Published var signatureService = SignatureService()
    @Published var activeSignatureOverlay: IdentifiablePDFAnnotation? = nil
    
    // Image overlay state
    @Published var currentImage: UIImage?
    @Published var activeImageOverlay: IdentifiablePDFAnnotation? = nil
    
    // Document state
    @Published var hasUnsavedChanges = false
    @Published var isProcessing = false
    
    // Annotations service
    @Published var annotationsService = AnnotationsService()
    
    private var documentId: UUID?
    private var storage: PDFConverterStorage?
    private var documentURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    // Store reference to PDFView for coordinate calculations
    weak var pdfViewRef: PDFView?
    
    // MARK: - Computed Properties
    
    var currentPage: PDFPage? {
        return pdfDocument?.page(at: currentPageIndex)
    }
    
    func setPDFViewReference(_ pdfView: PDFView) {
        self.pdfViewRef = pdfView
        print("📐 PDFView reference set with bounds: \(pdfView.bounds)")
    }
    
    func getActualPDFDisplaySize() -> (size: CGSize, offset: CGPoint)? {
        guard let pdfView = pdfViewRef,
              let page = pdfDocument?.page(at: currentPageIndex) else {
            return nil
        }
        
        // Get the actual bounds of the PDF page as displayed in the view
        let pageRect = page.bounds(for: .mediaBox)
        let displayRect = pdfView.convert(pageRect, from: page)
        
        print("📐 PDF page original bounds: \(pageRect)")
        print("📐 PDF page display bounds: \(displayRect)")
        
        return (size: displayRect.size, offset: CGPoint(x: displayRect.origin.x, y: displayRect.origin.y))
    }
    
    // MARK: - Configuration
    
    func loadDocument(_ document: PDFDocument, url: URL? = nil, storage: PDFConverterStorage) {
        self.pdfDocument = document
        self.documentURL = url
        self.storage = storage
        self.currentPageIndex = 0
        
        print("📄 Loaded PDF document with \(document.pageCount) pages")
        if let url = url {
            print("📁 Document URL: \(url)")
        }
        
        // Configure annotations service
        annotationsService.configure(document: document, pageIndex: currentPageIndex)
    }
    
    // MARK: - Tool Selection
    
    func selectTool(_ tool: EditorTool) {
        // Deselect if same tool
        if selectedTool == tool {
            selectedTool = nil
            resetToolStates()
            return
        }
        
        selectedTool = tool
        resetToolStates()
        
        // Configure tool-specific states
        switch tool {
        case .highlight:
            // Highlight tool doesn't need special setup
            print("🖍️ Highlight tool selected")
        case .addImage:
            showingImagePicker = true
            print("🖼️ Showing image picker")
        case .signature:
            if currentSignature == nil {
                showingSignatureCreator = true
            } else {
                showingSignatureCreator = true
                print("🔄 Reopening signature creator for new signature")
            }
        case .rotate:
            // Execute rotation immediately
            rotateCurrentPage()
            selectedTool = nil // Deselect after rotation
            print("🔄 Page rotated")
        }
    }
    
    func deselectTool() {
        selectedTool = nil
        resetToolStates()
    }
    
    private func resetToolStates() {
        showingImageInsertMode = false
        showingSignatureInsertMode = false
        
        // Clear active overlays
        activeSignatureOverlay = nil
        activeImageOverlay = nil
        currentSignature = nil
        currentImage = nil
    }
    
    // MARK: - Image Tools
    
    func createImageOverlay(with image: UIImage) {
        guard let document = pdfDocument,
              let page = document.page(at: currentPageIndex) else {
            print("❌ Failed to create image overlay - no document/page")
            return
        }
        
        print("✨ Creating image overlay")
        
        // Calculate center position in PDF coordinates
        let pageRect = page.bounds(for: .mediaBox)
        let centerX = pageRect.width / 2
        let centerY = pageRect.height / 2
        
        // Calculate image bounds
        let desiredMaxWidth: CGFloat = 120   
        let desiredMaxHeight: CGFloat = 120   
        
        let imageSize = image.size
        let scaleX = desiredMaxWidth / imageSize.width
        let scaleY = desiredMaxHeight / imageSize.height
        let scale = min(scaleX, scaleY, 0.6)
        
        let finalWidth = imageSize.width * scale
        let finalHeight = imageSize.height * scale
        
        print("📏 Image sizing: image(\(imageSize)) → final(\(finalWidth)x\(finalHeight)) scale(\(scale))")
        
        // Create annotation bounds centered on page
        let bounds = CGRect(
            x: centerX - finalWidth / 2,
            y: centerY - finalHeight / 2,
            width: finalWidth,
            height: finalHeight
        )
        
        // Create image annotation but DON'T add to page yet
        let imageAnnotation = ImageAnnotation(bounds: bounds, image: image)
        
        // Create identifiable annotation for overlay
        let identifiableAnnotation = IdentifiablePDFAnnotation(
            annotation: imageAnnotation,
            position: CGPoint(x: centerX, y: centerY),
            midPosition: CGPoint(x: 0.5, y: 0.5), // Normalized center
            boundingBox: bounds,
            scale: 0.3
        )
        
        // Set as active overlay
        activeImageOverlay = identifiableAnnotation
        currentImage = image
        
        hasUnsavedChanges = true
        
        print("📸 Image overlay created and ready for positioning")
    }
    
    func finalizeImageOverlay() {
        guard let overlay = activeImageOverlay,
              let page = currentPage else {
            print("❌ Cannot finalize image overlay - no overlay or page")
            return
        }
        
        print("✅ Finalizing image overlay")
        print("🔍 Before finalize - overlay bounds: \(overlay.annotation.bounds)")
        print("🔍 Before finalize - overlay midPosition: \(overlay.midPosition)")
        print("🔍 Before finalize - overlay scale: \(overlay.scale)")
        
        // Add the annotation to the PDF page
        page.addAnnotation(overlay.annotation)
        objectWillChange.send()
        
        print("📄 Image finalized at PDF bounds: \(overlay.annotation.bounds)")
        
        // Clear the overlay after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.activeImageOverlay = nil
            self?.currentImage = nil
            print("🔄 Image overlay cleared after PDF render")
        }
        
        hasUnsavedChanges = true
    }
    
    func cancelImageOverlay() {
        activeImageOverlay = nil
        currentImage = nil
        print("❌ Image overlay cancelled")
    }
    
    func insertImage(_ image: UIImage, at point: CGPoint) {
        print("🖼️ Creating image overlay")
        createImageOverlay(with: image)
        showingImageInsertMode = false
    }
    
    func insertImageAtStoredPoint(_ image: UIImage) {
        print("🖼️ Creating image overlay from stored point")
        createImageOverlay(with: image)
        insertionPoint = .zero
    }
    
    // MARK: - Signature Tools
    
    func saveSignature(_ signature: UIImage) {
        print("💾 Saving signature and creating overlay")
        currentSignature = signature
        showingSignatureCreator = false
        
        // Create immediate overlay
        createSignatureOverlay(with: signature)
        
        // Reset signature service for next use
        signatureService.clearSignature()
    }
    
    func createSignatureOverlay(with signature: UIImage) {
        guard let document = pdfDocument,
              let page = document.page(at: currentPageIndex) else {
            print("❌ Failed to create signature overlay - no document/page")
            return
        }
        
        print("✨ Creating signature overlay")
        
        // Calculate center position in PDF coordinates
        let pageRect = page.bounds(for: .mediaBox)
        let centerX = pageRect.width / 2
        let centerY = pageRect.height / 2
        
        // Calculate signature bounds
        let desiredMaxWidth: CGFloat = 100    
        let desiredMaxHeight: CGFloat = 50    
        
        let imageSize = signature.size
        let scaleX = desiredMaxWidth / imageSize.width
        let scaleY = desiredMaxHeight / imageSize.height
        let scale = min(scaleX, scaleY, 0.6)
        
        let finalWidth = imageSize.width * scale
        let finalHeight = imageSize.height * scale
        
        print("📏 Signature sizing: image(\(imageSize)) → final(\(finalWidth)x\(finalHeight)) scale(\(scale))")
        
        // Create annotation bounds centered on page
        let bounds = CGRect(
            x: centerX - finalWidth / 2,
            y: centerY - finalHeight / 2,
            width: finalWidth,
            height: finalHeight
        )
        
        // Create image annotation but DON'T add to page yet
        let imageAnnotation = ImageAnnotation(bounds: bounds, image: signature)
        
        // Create identifiable annotation for overlay
        let identifiableAnnotation = IdentifiablePDFAnnotation(
            annotation: imageAnnotation,
            position: CGPoint(x: centerX, y: centerY),
            midPosition: CGPoint(x: 0.5, y: 0.5), // Normalized center
            boundingBox: bounds,
            scale: 0.3
        )
        
        // Set as active overlay
        activeSignatureOverlay = identifiableAnnotation
        
        hasUnsavedChanges = true
        selectedTool = nil
        
        print("✅ Signature overlay created")
    }
    
    func finalizeSignatureOverlay() {
        guard let overlay = activeSignatureOverlay,
              let document = pdfDocument,
              let page = document.page(at: currentPageIndex) else {
            print("❌ Cannot finalize signature overlay - missing data")
            return
        }
        
        print("✅ Finalizing signature overlay")
        print("🔍 Before finalize - overlay bounds: \(overlay.annotation.bounds)")
        print("🔍 Before finalize - overlay midPosition: \(overlay.midPosition)")
        print("🔍 Before finalize - overlay scale: \(overlay.scale)")
        
        // Add annotation to PDF page
        page.addAnnotation(overlay.annotation)
        
        // Force PDF document update
        objectWillChange.send()
        
        // Add to annotations service for tracking
        annotationsService.annotations.append(overlay)
        
        // Clear active overlay AFTER a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.activeSignatureOverlay = nil
            self?.selectedTool = nil
            print("🔄 Overlay cleared after PDF render")
        }
        
        print("📄 Signature finalized at PDF bounds: \(overlay.annotation.bounds)")
    }
    
    func clearSignature() {
        print("🗑️ Clearing signature")
        currentSignature = nil
        signatureService.clearSignature()
        showingSignatureInsertMode = false
        activeSignatureOverlay = nil
        selectedTool = nil
    }
    
    func resetSignatureService() {
        showingSignatureCreator = false
        signatureService.clearSignature()
    }
    
    func cancelSignatureInsertion() {
        showingSignatureInsertMode = false
        selectedTool = nil
        activeSignatureOverlay = nil
    }
    
    // MARK: - Highlight Tools
    
    func handleTextSelection(selectedText: String, bounds: CGRect, geometrySize: CGSize) {
        guard selectedTool == .highlight else { return }
        
        annotationsService.addHighlightAnnotation(selectedText: selectedText, bounds: bounds)
        hasUnsavedChanges = true
        
        print("🖍️ Added highlight for text: \(selectedText.prefix(30))...")
    }
    
    // MARK: - Navigation
    
    func goToNextPage() {
        guard let document = pdfDocument,
              currentPageIndex < document.pageCount - 1 else { return }
        
        currentPageIndex += 1
        annotationsService.updateCurrentPage(currentPageIndex)
    }
    
    func goToPreviousPage() {
        guard currentPageIndex > 0 else { return }
        
        currentPageIndex -= 1
        annotationsService.updateCurrentPage(currentPageIndex)
    }
    
    func goToPage(_ index: Int) {
        guard let document = pdfDocument,
              index >= 0 && index < document.pageCount else { return }
        
        currentPageIndex = index
        annotationsService.updateCurrentPage(currentPageIndex)
    }
    
    // MARK: - Rotation Tools
    
    private func rotateCurrentPage() {
        guard let document = pdfDocument,
              let page = document.page(at: currentPageIndex) else { return }
        
        // Rotate page 90 degrees clockwise
        let currentRotation = page.rotation
        page.rotation = (currentRotation + 90) % 360
        
        hasUnsavedChanges = true
        
        // Force refresh
        objectWillChange.send()
        
        print("🔄 Page rotated to \(page.rotation)°")
    }
    
    // MARK: - Save Changes
    
    func saveDocument() async {
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        guard let document = pdfDocument else {
            print("❌ No PDF document to save")
            return
        }
        
        // Save annotations
        annotationsService.saveAnnotations()
        
        // Save PDF to file if we have URL
        if let url = documentURL {
            do {
                let success = document.write(to: url)
                if success {
                    print("💾 PDF document successfully written to file: \(url)")
                    hasUnsavedChanges = false
                } else {
                    print("❌ Failed to write PDF document to file")
                }
            } catch {
                print("❌ Error writing PDF document: \(error)")
            }
        } else {
            print("⚠️ No document URL available - changes saved only in memory")
            hasUnsavedChanges = false
        }
        
        print("💾 Document saved successfully")
    }
    
    func discardChanges() {
        hasUnsavedChanges = false
        selectedTool = nil
        resetToolStates()
    }
}

// MARK: - Supporting Types

struct IdentifiablePDFAnnotation: Identifiable, Equatable {
    let id = UUID()
    let annotation: PDFAnnotation
    var position: CGPoint
    var midPosition: CGPoint
    var boundingBox: CGRect
    var scale: CGFloat
    
    static func == (lhs: IdentifiablePDFAnnotation, rhs: IdentifiablePDFAnnotation) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Custom Image Annotation

class ImageAnnotation: PDFAnnotation {
    private let _image: UIImage
    
    var image: UIImage {
        return _image
    }
    
    init(bounds: CGRect, image: UIImage) {
        self._image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = _image.cgImage else { return }
        
        context.saveGState()
        
        // Draw image exactly within the bounds (простой подход как в PDFScanner_1)
        context.draw(cgImage, in: bounds)
        
        context.restoreGState()
        
        print("🎨 ImageAnnotation drawn at exact bounds: \(bounds)")
    }
}
