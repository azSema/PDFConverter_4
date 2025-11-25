import SwiftUI
import UniformTypeIdentifiers

struct SignView: View {
    
    @EnvironmentObject private var storage: PDFConverterStorage
    @StateObject private var viewModel = SignViewModel()
    @State private var showDocumentTypePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "Sign",
                showProButton: true, content: {}
            )
            
            if viewModel.documents.isEmpty && !viewModel.isLoading {
                // Empty State
                EmptySignState(onSelectFile: {
                    showDocumentTypePicker = true
                })
            } else {
                // Documents List
                DocumentsListView()
                    .padding(.top, -40)
            }
        }
        .background(Color.appWhite)
        .environmentObject(viewModel)
        .onAppear {
            viewModel.updateStorage(storage)
        }
        .sheet(isPresented: $showDocumentTypePicker) {
            DocumentTypePickerSheetSign { fileType in
                handleFileTypeSelection(fileType)
            }
        }
        .sheet(isPresented: $viewModel.showFilePicker) {
            DocumentPickerView(
                allowedContentTypes: [.pdf, .image, .plainText, .text],
                allowsMultipleSelection: false
            ) { urls in
                if let url = urls.first {
                    viewModel.handleFileImport(url: url)
                }
            }
        }
        .sheet(isPresented: $viewModel.showDocumentDetail) {
            if let document = viewModel.editingDocument {
                DocumentSignView(document: document)
            }
        }
    }
    
    private func handleFileTypeSelection(_ fileType: EditableFileType) {
        viewModel.showFilePicker = true
    }
}

// MARK: - Empty State

struct EmptySignState: View {
    let onSelectFile: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                Image(systemName: "signature")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(Color.appGray.opacity(0.6))
                
                VStack(spacing: 16) {
                    Text("No documents to sign")
                        .font(.semiBold(24))
                        .foregroundColor(Color.appWhite)
                    
                    Text("Select a document to add your signature\n(PDF/Image/Text)")
                        .font(.regular(16))
                        .foregroundColor(Color.appGray)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                Button(action: onSelectFile) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("Select Document")
                            .font(.semiBold(16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.appRed)
                    .cornerRadius(16)
                    .shadow(color: Color.appRed.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Documents List (Reused from Edit)

extension SignView {
    
    private func DocumentsListView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.documents) { document in
                        DocumentRowView(document: document) {
                            viewModel.openDocument(document)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Document Sign View

struct DocumentSignView: View {
    let document: DocumentDTO
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Document signing functionality coming soon")
                    .font(.regular(16))
                    .foregroundColor(Color.appGray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Sign Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.appRed)
                }
            }
        }
    }
}

// MARK: - Document Type Picker (Reused from Edit)

struct DocumentTypePickerSheetSign: View {
    @Environment(\.dismiss) private var dismiss
    let onTypePicked: (EditableFileType) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(EditableFileType.allCases, id: \.self) { fileType in
                    Button {
                        onTypePicked(fileType)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: fileType.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(Color.appRed)
                                .frame(width: 40)
                            
                            Text(fileType.rawValue + " Files")
                                .font(.medium(18))
                                .foregroundColor(Color.appBlack)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.appGray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.appWhite)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.appWhite)
            .navigationTitle("Select File Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.appRed)
                }
            }
        }
    }
}

#Preview {
    SignView()
        .environmentObject(PDFConverterStorage())
}
