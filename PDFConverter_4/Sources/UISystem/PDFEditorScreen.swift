import SwiftUI
import PDFKit

struct PDFEditorScreen: View {
    let document: DocumentDTO
    @EnvironmentObject private var storage: PDFConverterStorage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if let pdfDocument = loadPDFDocument() {
                PDFEditorView(document: pdfDocument, storage: storage)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.appOrange)
                    
                    Text("Cannot Open Document")
                        .font(.bold(20))
                        .foregroundColor(.appBlack)
                    
                    Text("This document cannot be opened for editing")
                        .font(.regular(16))
                        .foregroundColor(.appGray)
                        .multilineTextAlignment(.center)
                    
                    Button("Go Back") {
                        dismiss()
                    }
                    .font(.semibold(16))
                    .foregroundColor(.appWhite)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.appRed)
                    .cornerRadius(8)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appWhite)
            }
        }
    }
    
    private func loadPDFDocument() -> PDFDocument? {
        if let pdfDocument = document.pdf {
            return pdfDocument
        } else if let url = document.url {
            return PDFDocument(url: url)
        }
        return nil
    }
}