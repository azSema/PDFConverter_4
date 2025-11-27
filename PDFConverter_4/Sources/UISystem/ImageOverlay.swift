import SwiftUI
import PDFKit

struct ImageOverlay: View {
    @ObservedObject var editService: PDFEditService
    @Binding var annotation: IdentifiablePDFAnnotation
    @Binding var isScaling: Bool
    @State private var isDragging = false
    @State private var showMenu = false
    
    let geometry: GeometryProxy
    
    var body: some View {
        let image = getAnnotationImage()
        let width = (image?.size.width ?? 100) * annotation.scale
        let height = (image?.size.height ?? 100) * annotation.scale
        
        let viewPosition = convertedViewPosition(for: CGSize(width: width, height: height))
        let clampedPosition = self.clampedPosition(for: CGSize(width: width, height: height), viewPosition: viewPosition)
        
        ZStack {
            // Image
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
                                editService.cancelImageOverlay()
                            }
                        }
                    }
                    .overlay(
                        Rectangle()
                            .stroke(Color.appRed.opacity(0.7), lineWidth: 2)
                            .opacity(isDragging || isScaling ? 1 : 0)
                    )
            }
            
            // Interactive border when dragging or scaling
            if isDragging || isScaling {
                let rectangleWidth = width
                let rectangleHeight = height
                let inset: CGFloat = 1
                
                Rectangle()
                    .stroke(Color.appRed, lineWidth: 2)
                    .frame(width: rectangleWidth - inset, height: rectangleHeight - inset)
                    .position(clampedPosition)
                
                // Corner handles
                Group {
                    Circle()
                        .fill(Color.appRed)
                        .frame(width: 12, height: 12)
                        .position(x: clampedPosition.x - rectangleWidth/2 + 6, 
                                y: clampedPosition.y - rectangleHeight/2 + 6)
                    
                    Circle()
                        .fill(Color.appRed)
                        .frame(width: 12, height: 12)
                        .position(x: clampedPosition.x + rectangleWidth/2 - 6, 
                                y: clampedPosition.y - rectangleHeight/2 + 6)
                    
                    Circle()
                        .fill(Color.appRed)
                        .frame(width: 12, height: 12)
                        .position(x: clampedPosition.x - rectangleWidth/2 + 6, 
                                y: clampedPosition.y + rectangleHeight/2 - 6)
                    
                    Circle()
                        .fill(Color.appRed)
                        .frame(width: 12, height: 12)
                        .position(x: clampedPosition.x + rectangleWidth/2 - 6, 
                                y: clampedPosition.y + rectangleHeight/2 - 6)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    print("🔄 Image drag changed: \(value.location)")
                    let clampedX = min(max(value.location.x, width/2), geometry.size.width - width/2)
                    let clampedY = min(max(value.location.y, height/2), geometry.size.height - height/2)
                    
                    annotation.midPosition = CGPoint(x: clampedX, y: clampedY)
                    annotation.position = CGPoint(x: clampedX, y: clampedY)
                    isDragging = true
                }
                .onEnded { _ in
                    print("🏁 Image drag ended at: \(annotation.midPosition)")
                    isDragging = false
                    saveImagePosition()
                }
        )
        .onChange(of: isScaling) { scaling in
            if !scaling {
                // Scale ended, save position
                saveImagePosition()
            }
        }
    }
    
    private func convertedViewPosition(for size: CGSize) -> CGPoint {
        // If midPosition is normalized (0-1), convert to view coordinates
        if annotation.midPosition.x <= 1.0 && annotation.midPosition.y <= 1.0 {
            let viewX = annotation.midPosition.x * geometry.size.width
            let viewY = annotation.midPosition.y * geometry.size.height
            
            print("🔄 Converting normalized coordinates to view: \(viewX), \(viewY)")
            
            let viewPosition = CGPoint(x: viewX, y: viewY)
            annotation.midPosition = viewPosition
            
            return viewPosition
        }
        
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
    
    private func saveImagePosition() {
        guard let document = editService.pdfDocument,
              let page = document.page(at: editService.currentPageIndex) else { return }
        
        let pageRect = page.bounds(for: .mediaBox)
        
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
        
        let scaleX = pageRect.width / displaySize.width
        let scaleY = pageRect.height / displaySize.height
        
        let image = getAnnotationImage()
        let originalWidth = image?.size.width ?? 100
        let originalHeight = image?.size.height ?? 100
        
        let currentWidthView = originalWidth * annotation.scale
        let currentHeightView = originalHeight * annotation.scale
        
        let currentWidthPDF = currentWidthView * scaleX
        let currentHeightPDF = currentHeightView * scaleY
        
        print("🔍 Image size: Original(\(originalWidth)x\(originalHeight)) → View(\(currentWidthView)x\(currentHeightView)) → PDF(\(currentWidthPDF)x\(currentHeightPDF))")
        
        // Convert view coordinates to PDF coordinates  
        // Account for PDFEditorView_Internal offset (18, 36)
        let adjustedViewX = annotation.midPosition.x - displayOffset.x - 18  // Account for .offset(x: 18)
        let adjustedViewY = annotation.midPosition.y - displayOffset.y - 36  // Account for .offset(y: 36)
        
        let pdfCenterX = adjustedViewX * scaleX
        let pdfCenterY = pageRect.height - (adjustedViewY * scaleY)
        
        print("🔍 Position adjustment: ViewPos(\(annotation.midPosition)) → Adjusted(\(adjustedViewX), \(adjustedViewY)) → PDFCenter(\(pdfCenterX), \(pdfCenterY))")
        
        let newBounds = CGRect(
            x: pdfCenterX - currentWidthPDF / 2,
            y: pdfCenterY - currentHeightPDF / 2,
            width: currentWidthPDF,
            height: currentHeightPDF
        )
        
        annotation.annotation.bounds = newBounds
        annotation.boundingBox = newBounds
        annotation.position = CGPoint(x: pdfCenterX, y: pdfCenterY)
        
        editService.hasUnsavedChanges = true
        
        print("💾 Final bounds set: \(newBounds)")
        print("🎯 Expected center in PDF: (\(pdfCenterX), \(pdfCenterY))")
    }
}