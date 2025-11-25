import SwiftUI
import PDFKit

struct PDFDetailedPreview: View {
    let document: DocumentDTO
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    @State private var pdfDocument: PDFDocument?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appWhite
                    .ignoresSafeArea()
                
                if let pdfDoc = pdfDocument {
                    PDFKitPreviewView(pdfDocument: pdfDoc, currentPage: $currentPage)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appGray)
                        
                        Text("Unable to load document")
                            .font(.medium(16))
                            .foregroundColor(.appGray)
                    }
                }
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.appRed)
                }
                
                if let pdfDoc = pdfDocument, pdfDoc.pageCount > 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 8) {
                            Button {
                                if currentPage > 0 {
                                    currentPage -= 1
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(currentPage > 0 ? .appRed : .appGray)
                            }
                            .disabled(currentPage <= 0)
                            
                            Text("\(currentPage + 1) / \(pdfDoc.pageCount)")
                                .font(.medium(12))
                                .foregroundColor(.appGray)
                            
                            Button {
                                if currentPage < pdfDoc.pageCount - 1 {
                                    currentPage += 1
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(currentPage < pdfDoc.pageCount - 1 ? .appRed : .appGray)
                            }
                            .disabled(currentPage >= pdfDoc.pageCount - 1)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadPDFDocument()
        }
    }
    
    private func loadPDFDocument() {
        switch document.type {
        case .pdf:
            pdfDocument = document.pdf
            
        case .image:
            // Если это изображение из PDF, попробуем загрузить исходный PDF
            if let sourcePDFURL = document.sourcePDFURL {
                pdfDocument = PDFDocument(url: sourcePDFURL)
            }
            
        case .text:
            // Для текстовых файлов можно показать содержимое или создать PDF
            break
        }
    }
}

struct PDFKitPreviewView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.backgroundColor = UIColor(Color.appWhite)
        
        // Add notification for page changes
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let page = pdfView.currentPage {
                let pageIndex = pdfDocument.index(for: page)
                currentPage = pageIndex
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let page = pdfDocument.page(at: currentPage) {
            pdfView.go(to: page)
        }
    }
}

#Preview {
    PDFDetailedPreview(
        document: DocumentDTO(
            name: "Sample Document",
            type: .pdf
        )
    )
}