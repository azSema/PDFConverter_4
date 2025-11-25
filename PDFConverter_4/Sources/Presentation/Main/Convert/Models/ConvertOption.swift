import Foundation

enum ConvertOption: String, CaseIterable {
    case textToPDF = "Text to PDF"
    case imageToPDF = "Image to PDF"
    case pdfToImage = "PDF to Image"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: ImageResource {
        switch self {
        case .textToPDF:
                .txtToPdf
        case .imageToPDF:
                .imgToPdf
        case .pdfToImage:
                .pdfToImg
        }
    }
    
}
