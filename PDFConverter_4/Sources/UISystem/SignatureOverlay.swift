import SwiftUI
import PDFKit

struct SignatureOverlay: View {
    @ObservedObject var editService: PDFEditService
    @Binding var annotation: IdentifiablePDFAnnotation
    @Binding var isScaling: Bool
    @State private var isDragging = false
    @State private var showMenu = false
    
    let geometry: GeometryProxy
    
    let onClose: () -> ()
    
    var body: some View {
        let signatureImage = getAnnotationImage()
        let width = (signatureImage?.size.width ?? 100) * annotation.scale
        let height = (signatureImage?.size.height ?? 100) * annotation.scale
        
        let viewPosition = convertedViewPosition(for: CGSize(width: width, height: height))
        let clampedPosition = self.clampedPosition(for: CGSize(width: width, height: height), viewPosition: viewPosition)
        
        ZStack {
            // Signature image
            if let image = getAnnotationImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .position(clampedPosition)
                    .onLongPressGesture {
                        showMenu = true
                    }
                    .contextMenu {
                        if showMenu {
                            Button("Copy") {
                                UIPasteboard.general.image = image
                            }
                            Button("Delete", role: .destructive) {
                                editService.annotationsService.removeHighlightAnnotation(annotation)
                            }
                        }
                    }
            }
            
            if /*isDragging || isScaling*/ true {
                let rectangleWidth = width
                let rectangleHeight = height
                let inset: CGFloat = 1
                
                ZStack {
                    // Dashed rectangle
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .foregroundColor(.red)
                        .frame(width: rectangleWidth, height: rectangleHeight)
                        .position(clampedPosition)
                    
                    // Dashed corner circles
                    cornerCircle(at: CGPoint(
                        x: clampedPosition.x - (rectangleWidth / 2) + inset,
                        y: clampedPosition.y - (rectangleHeight / 2) + inset
                    ))
                    cornerCircle(at: CGPoint(
                        x: clampedPosition.x + (rectangleWidth / 2) - inset,
                        y: clampedPosition.y - (rectangleHeight / 2) + inset
                    ))
                    cornerCircle(at: CGPoint(
                        x: clampedPosition.x - (rectangleWidth / 2) + inset,
                        y: clampedPosition.y + (rectangleHeight / 2) - inset
                    ))
                    cornerCircle(at: CGPoint(
                        x: clampedPosition.x + (rectangleWidth / 2) - inset,
                        y: clampedPosition.y + (rectangleHeight / 2) - inset
                    ))
                    
                    // Close button in top-right corner
                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.red)
                    }
                    .position(x: clampedPosition.x + (rectangleWidth / 2), y: clampedPosition.y - (rectangleHeight / 2))
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    print("🔄 Signature drag changed: \(value.location)")
                    let clampedX = min(max(value.location.x, width/2), geometry.size.width - width/2)
                    let clampedY = min(max(value.location.y, height/2), geometry.size.height - height/2)
                    
                    annotation.midPosition = CGPoint(x: clampedX, y: clampedY)
                    annotation.position = CGPoint(x: clampedX, y: clampedY)
                    isDragging = true
                }
                .onEnded { _ in
                    print("🏁 Signature drag ended at: \(annotation.midPosition)")
                    isDragging = false
                    saveSignaturePosition()
                }
        )
        .onChange(of: isScaling) { scaling in
            if !scaling {
                // Scale ended, save position
                saveSignaturePosition()
            }
        }
    }
    
    private func convertedViewPosition(for size: CGSize) -> CGPoint {
        // If midPosition is normalized (0-1), convert to view coordinates
        if annotation.midPosition.x <= 1.0 && annotation.midPosition.y <= 1.0 {
            let viewX = annotation.midPosition.x * geometry.size.width
            let viewY = annotation.midPosition.y * geometry.size.height
            
            print("🔄 Converting normalized coordinates to view: \(viewX), \(viewY)")
            
            // Update annotation with actual view coordinates but only once
            let viewPosition = CGPoint(x: viewX, y: viewY)
            annotation.midPosition = viewPosition
            
            return viewPosition
        }
        
        // Already in view coordinates
        return annotation.midPosition
    }
    
    private func getAnnotationImage() -> UIImage? {
        if let imageAnnotation = annotation.annotation as? ImageAnnotation {
            return imageAnnotation.image
        }
        return nil
    }
    
    private func clampedPosition(for size: CGSize, viewPosition: CGPoint) -> CGPoint {
        let clampedX = min(max(viewPosition.x, size.width / 2), geometry.size.width - size.width / 2)
        let clampedY = min(max(viewPosition.y, size.height / 2), geometry.size.height - size.height / 2)
        
        return CGPoint(x: clampedX, y: clampedY)
    }
    
        private func cornerCircle(at position: CGPoint) -> some View {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4]))
                .foregroundColor(.red)
                .frame(width: 10, height: 10)
                .position(position)
        }
    
    private func saveSignaturePosition() {
        // Convert view coordinates back to PDF coordinates and save
        guard let document = editService.pdfDocument,
              let page = document.page(at: editService.currentPageIndex) else { return }
        
        let pageRect = page.bounds(for: .mediaBox)
        
        // Try to get actual PDF display size and offset, fallback to geometry
        let displaySize: CGSize
        let displayOffset: CGPoint
        
        if let actualPDFData = editService.getActualPDFDisplaySize() {
            displaySize = actualPDFData.size
            displayOffset = actualPDFData.offset
            print("🎯 Using actual PDF display size: \(displaySize), offset: \(displayOffset)")
        } else {
            displaySize = geometry.size
            displayOffset = .zero
            print("⚠️ Using geometry size as fallback: \(displaySize), no offset")
        }
        
        // Log geometry info for debugging
        print("🔍 Geometry size: \(geometry.size)")
        print("🔍 Display size used: \(displaySize)")
        print("🔍 Display offset: \(displayOffset)")
        print("🔍 PDF page bounds: \(pageRect)")
        
        // Calculate scale factors using actual display size
        let scaleX = pageRect.width / displaySize.width
        let scaleY = pageRect.height / displaySize.height
        
        print("🔍 Scale factors: X=\(scaleX), Y=\(scaleY)")
        
        // Get actual current signature size (with scaling applied)
        let signatureImage = getAnnotationImage()
        let originalWidth = signatureImage?.size.width ?? 100
        let originalHeight = signatureImage?.size.height ?? 100
        
        // Current sizes in view coordinates
        let currentWidthView = originalWidth * annotation.scale
        let currentHeightView = originalHeight * annotation.scale
        
        // Convert to PDF coordinates
        let currentWidthPDF = currentWidthView * scaleX
        let currentHeightPDF = currentHeightView * scaleY
        
        print("🔍 Signature size: Original(\(originalWidth)x\(originalHeight)) → View(\(currentWidthView)x\(currentHeightView)) → PDF(\(currentWidthPDF)x\(currentHeightPDF))")
        
        // Convert view coordinates to PDF coordinates
        // Account for PDFEditorView_Internal offset (18, 36)
        let adjustedViewX = annotation.midPosition.x - displayOffset.x - 18  // Account for .offset(x: 18)
        let adjustedViewY = annotation.midPosition.y - displayOffset.y - 36  // Account for .offset(y: 36)
        
        let pdfCenterX = adjustedViewX * scaleX
        let pdfCenterY = pageRect.height - (adjustedViewY * scaleY) // Flip Y axis for PDF
        
        print("🔍 Position adjustment: ViewPos(\(annotation.midPosition)) → Adjusted(\(adjustedViewX), \(adjustedViewY)) → PDFCenter(\(pdfCenterX), \(pdfCenterY))")
        
        // Create bounds with center positioning
        let newBounds = CGRect(
            x: pdfCenterX - currentWidthPDF / 2,
            y: pdfCenterY - currentHeightPDF / 2,
            width: currentWidthPDF,
            height: currentHeightPDF
        )
        
        // Update annotation bounds
        annotation.annotation.bounds = newBounds
        annotation.boundingBox = newBounds
        
        // Update position fields to match new bounds  
        annotation.position = CGPoint(x: pdfCenterX, y: pdfCenterY)
        
        editService.hasUnsavedChanges = true
        
        print("💾 Final bounds set: \(newBounds)")
        print("🎯 Expected center in PDF: (\(pdfCenterX), \(pdfCenterY))")
    }
}
