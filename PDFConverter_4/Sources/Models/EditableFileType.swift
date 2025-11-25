import Foundation
import UniformTypeIdentifiers

enum EditableFileType: String, CaseIterable {
    case pdf = "PDF"
    case image = "Image" 
    case text = "Text"
    
    var allowedContentTypes: [UTType] {
        switch self {
        case .pdf:
            return [.pdf]
        case .image:
            return [.image]
        case .text:
            return [.plainText, .text]
        }
    }
    
    var iconName: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .image:
            return "photo.fill"
        case .text:
            return "doc.text.fill"
        }
    }
}