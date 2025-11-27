import SwiftUI
import PDFKit

struct PDFDetailedPreview: View {
    let document: DocumentDTO
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: PDFConverterStorage
    @EnvironmentObject var convertViewModel: ConvertViewModel
    @EnvironmentObject var premium: PremiumManager
    
    @EnvironmentObject private var router: Router
    
    @State private var currentPage = 0
    @State private var pdfDocument: PDFDocument?
    @State private var showingRenameAlert = false
    @State private var newName = ""
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // PDF Viewer
                    if let pdfDoc = pdfDocument {
                        PDFKitPreviewView(pdfDocument: pdfDoc, currentPage: $currentPage)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.appGray)
                            
                            Text("Unable to load document")
                                .font(.medium(16))
                                .foregroundColor(.appGray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Action Buttons
                    actionButtons
                        .padding(.horizontal)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // Page navigation (if multi-page)
                        if let pdfDoc = pdfDocument, pdfDoc.pageCount > 1 {
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
                        
                        // Menu Button
                        Menu {
                            Button {
                                showingShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                newName = document.name
                                showingRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Button {
                                storage.toggleFavorite(document)
                            } label: {
                                Label(
                                    document.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                    systemImage: document.isFavorite ? "heart.slash" : "heart"
                                )
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.appRed)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadPDFDocument()
        }
        .alert("Rename Document", isPresented: $showingRenameAlert) {
            TextField("Document name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                storage.renameDocument(document, to: newName)
                dismiss()
            }
        }
        .alert("Delete Document", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                storage.removeDocument(document)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(document.name)'? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = document.url {
                ShareSheet(items: [url])
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Edit Button
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    router.push(.pdfEditor(document))
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                    Text("Edit")
                        .font(.semiBold(16))
                }
                .foregroundColor(.appWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appOrange)
                .cornerRadius(12)
            }
            
            // Convert Button  
            Button {
                dismiss()
                guard premium.canConvert(currentCount: convertViewModel.currentConvertsCount) else {
                    premium.presentPaywall(true)
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    router.push(.pdfConverter(document))
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                    Text("Convert")
                        .font(.semiBold(16))
                }
                .foregroundColor(.appWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appRed)
                .cornerRadius(12)
            }
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
