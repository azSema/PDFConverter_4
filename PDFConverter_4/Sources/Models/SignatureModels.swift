import Foundation
import SwiftUI
import UIKit
import PDFKit

// MARK: - Saved Signature Model

struct SavedSignature: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let imageName: String  // Filename in documents directory
    let createdDate: Date
    let color: String      // Hex color
    
    init(name: String, imageName: String, color: String) {
        self.id = UUID()
        self.name = name
        self.imageName = imageName
        self.createdDate = Date()
        self.color = color
    }
}

// MARK: - Drawing Path Model

struct DrawingPath {
    private(set) var points: [CGPoint] = []
    private var breaks: Set<Int> = []
    
    var isEmpty: Bool {
        points.isEmpty
    }
    
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    mutating func addBreak() {
        breaks.insert(points.count)
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        guard let firstPoint = points.first else { return path }
        
        path.move(to: firstPoint)
        
        for i in 1..<points.count {
            if breaks.contains(i) {
                // Start new stroke
                path.move(to: points[i])
            } else {
                // Continue current stroke
                path.addLine(to: points[i])
            }
        }
        
        return path
    }
    
    var swiftUIPath: Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        
        path.move(to: firstPoint)
        
        for i in 1..<points.count {
            if breaks.contains(i) {
                // Start new stroke
                path.move(to: points[i])
            } else {
                // Continue current stroke
                path.addLine(to: points[i])
            }
        }
        
        return path
    }
    
    // Get bounds of the drawn signature
    var boundingBox: CGRect {
        guard !points.isEmpty else { return .zero }
        
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Editor Tools

enum EditorTool: String, CaseIterable {
    case highlight = "highlight"
    case addImage = "addImage"
    case signature = "signature"
    case rotate = "rotate"
    
    var title: String {
        switch self {
        case .highlight:
            return "Highlight"
        case .addImage:
            return "Add Image"
        case .signature:
            return "Signature"
        case .rotate:
            return "Rotate"
        }
    }
    
    var systemImage: String {
        switch self {
        case .highlight:
            return "highlighter"
        case .addImage:
            return "photo.badge.plus"
        case .signature:
            return "signature"
        case .rotate:
            return "rotate.right"
        }
    }
    
    var description: String {
        switch self {
        case .highlight:
            return "Highlight text and content"
        case .addImage:
            return "Insert images into document"
        case .signature:
            return "Create and add digital signature"
        case .rotate:
            return "Rotate pages"
        }
    }
}

// MARK: - Highlight Colors

enum HighlightColor: String, CaseIterable {
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case red = "red"
    case orange = "orange"
    case purple = "purple"
    case clear = "clear"
    
    var color: UIColor {
        switch self {
        case .yellow:
            return .systemYellow
        case .green:
            return .systemGreen
        case .blue:
            return .systemBlue
        case .red:
            return .systemRed
        case .orange:
            return .systemOrange
        case .purple:
            return .systemPurple
        case .clear:
            return .clear
        }
    }
    
    var title: String {
        switch self {
        case .yellow:
            return "Yellow"
        case .green:
            return "Green"
        case .blue:
            return "Blue"
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .purple:
            return "Purple"
        case .clear:
            return "Clear"
        }
    }
    
    var isClearMode: Bool {
        return self == .clear
    }
}

// MARK: - Extensions

extension Color {
    var uiColor: UIColor {
        return UIColor(self)
    }
    
    var hexString: String {
        let uic = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uic.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        return String(format: "#%06X", rgb)
    }
}

extension String {
    var color: Color {
        let hex = self.hasPrefix("#") ? String(self.dropFirst()) : self
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let g = Double((rgbValue & 0xff00) >> 8) / 255.0
        let b = Double(rgbValue & 0xff) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}