import Foundation
import SwiftUI
import UIKit
import CoreGraphics
import Combine

@MainActor
final class SignatureService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var drawingPath = DrawingPath()
    @Published var selectedColor: Color = .appRed
    @Published var isDrawing = false
    @Published var hasSignature = false
    
    // Drawing settings
    @Published var lineWidth: CGFloat = 3.0
    @Published var maxHeight: CGFloat = 160
    
    // Available colors
    let availableColors: [Color] = [.appRed, .appBlack, .appBlue, .appOrange, .purple, .green]
    
    // MARK: - Drawing Management
    
    func startDrawing(at point: CGPoint, in bounds: CGRect) {
        guard bounds.contains(point) else { return }
        
        isDrawing = true
        drawingPath.addPoint(point)
        updateSignatureStatus()
    }
    
    func continueDrawing(to point: CGPoint, in bounds: CGRect) {
        guard isDrawing else { return }
        
        if bounds.contains(point) {
            drawingPath.addPoint(point)
        } else {
            // If outside bounds, add break to start new stroke when back in bounds
            drawingPath.addBreak()
        }
        updateSignatureStatus()
    }
    
    func endDrawing() {
        guard isDrawing else { return }
        
        isDrawing = false
        drawingPath.addBreak()
        updateSignatureStatus()
    }
    
    func clearSignature() {
        drawingPath = DrawingPath()
        isDrawing = false
        hasSignature = false
    }
    
    // MARK: - Color Management
    
    func updateColor(_ color: Color) {
        selectedColor = color
    }
    
    // MARK: - Image Generation
    
    func generateSignatureImage() -> UIImage? {
        guard hasSignature else { return nil }
        
        let path = drawingPath.cgPath
        let boundingBox = path.boundingBox
        
        // Calculate proper size with padding
        let padding: CGFloat = 10
        let width = max(boundingBox.width + padding * 2, 100)
        let height = max(boundingBox.height + padding * 2, 50)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        
        let image = renderer.image { ctx in
            // DON'T set any background - leave transparent!
            // Removed: ctx.cgContext.setFillColor(UIColor.white.cgColor)
            // Removed: ctx.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
            // Set drawing properties
            ctx.cgContext.setStrokeColor(selectedColor.uiColor.cgColor)
            ctx.cgContext.setLineWidth(lineWidth)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)
            
            // Translate path to center it with padding
            ctx.cgContext.translateBy(x: padding - boundingBox.minX, y: padding - boundingBox.minY)
            
            // Draw the path
            ctx.cgContext.beginPath()
            ctx.cgContext.addPath(path)
            ctx.cgContext.drawPath(using: .stroke)
        }
        
        return image
    }
    
    func generateSignatureImageForSize(_ targetSize: CGSize) -> UIImage? {
        guard hasSignature else { return nil }
        
        let path = drawingPath.cgPath
        let pathBounds = path.boundingBox
        
        // Calculate scale to fit in target size with some padding
        let padding: CGFloat = 10
        let availableWidth = targetSize.width - padding * 2
        let availableHeight = targetSize.height - padding * 2
        
        let scaleX = availableWidth / pathBounds.width
        let scaleY = availableHeight / pathBounds.height
        let scale = min(scaleX, scaleY, 1.0) // Don't scale up
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let image = renderer.image { ctx in
            // Set white background
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: targetSize))
            
            // Set drawing properties
            ctx.cgContext.setStrokeColor(selectedColor.uiColor.cgColor)
            ctx.cgContext.setLineWidth(lineWidth * scale)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)
            
            // Center and scale the path
            let scaledWidth = pathBounds.width * scale
            let scaledHeight = pathBounds.height * scale
            let offsetX = (targetSize.width - scaledWidth) / 2 - pathBounds.minX * scale
            let offsetY = (targetSize.height - scaledHeight) / 2 - pathBounds.minY * scale
            
            ctx.cgContext.translateBy(x: offsetX, y: offsetY)
            ctx.cgContext.scaleBy(x: scale, y: scale)
            
            // Draw the path
            ctx.cgContext.beginPath()
            ctx.cgContext.addPath(path)
            ctx.cgContext.drawPath(using: .stroke)
        }
        
        return image
    }
    
    // MARK: - Signature Persistence
    
    func saveSignatureToDocuments() -> URL? {
        guard let image = generateSignatureImage(),
              let data = image.pngData(),
              let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let filename = documentsDir.appendingPathComponent("Signature-\(Date().timeIntervalSince1970).png")
        
        do {
            try data.write(to: filename)
            return filename
        } catch {
            print("Failed to save signature: \(error)")
            return nil
        }
    }
    
    // MARK: - Signature from existing image
    
    func loadSignatureFromImage(_ image: UIImage) {
        // Clear current drawing and create from image bounds
        clearSignature()
        
        // Create a simple path around the image bounds for display
        // This is a placeholder - in real implementation you might want to 
        // trace the image or store path data separately
        let bounds = CGRect(x: 10, y: 10, width: 200, height: 80)
        drawingPath.addPoint(CGPoint(x: bounds.minX, y: bounds.minY))
        drawingPath.addPoint(CGPoint(x: bounds.maxX, y: bounds.maxY))
        
        hasSignature = true
    }
    
    // MARK: - Private Methods
    
    private func updateSignatureStatus() {
        hasSignature = !drawingPath.isEmpty
    }
}