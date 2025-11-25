import Foundation
import UniformTypeIdentifiers
import SwiftUI

enum FileType: String, CaseIterable {
    case pdf, image, text
    
    var name: String {
        switch self {
        case .pdf:
            "PDF"
        case .image:
            "Image"
        case .text:
            "Text"
        }
    }
    
    var UTTypes: [UTType] {
        switch self {
        case .pdf:
            [.pdf]
        case .image:
            [.jpeg, .png]
        case .text:
            [.text]
        }
    }
    
    var icon: AnyView {
        switch self {
        case .pdf:
            AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.appRed)
                        .frame(width: 34, height: 34)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                    Text("PDF")
                        .foregroundStyle(.white)
                        .font(.medium(11))
                }
            )
        case .image:
            AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.appOrange)
                        .frame(width: 34, height: 34)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                    Image(.pic)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
            )
        case .text:
            AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.appBlue)
                        .frame(width: 34, height: 34)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                    Text("Text")
                        .foregroundStyle(.white)
                        .font(.medium(11))
                }
            )
        }
    }
}
