import Foundation
import PDFKit

struct DocumentDTO: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var pdf: PDFDocument?
    var name: String
    var type: DocumentType
    var date: Date
    var url: URL?
    var isFavorite: Bool
    
    init(id: String = UUID().uuidString,
         pdf: PDFDocument? = nil,
         name: String = "",
         type: DocumentType = .pdf,
         date: Date = .now,
         url: URL? = nil,
         isFavorite: Bool = false) {
        self.id = id
        self.pdf = pdf
        self.name = name
        self.type = type
        self.date = date
        self.url = url
        self.isFavorite = isFavorite
    }
    
    var thumbnail: UIImage {
        switch type {
        case .pdf:
            if let firstPage = pdf?.page(at: 0) {
                return firstPage.toImage() ?? UIImage(systemName: "document")!
            } else {
                return UIImage(systemName: "document")!
            }
        case .doc:
            return UIImage(systemName: "document")!
        }
    }
    
}

enum DocumentType: String {
    case pdf
    case doc
}
