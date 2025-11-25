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
                PDFDetailedPreview(document: document)
            }
        }
        .sheet(isPresented: $viewModel.showSignatureCreator) {
            SignatureCreatorView(
                onSave: { signature in
                    viewModel.handleQuickSignatureCreated(signature)
                },
                onCancel: {
                    viewModel.showSignatureCreator = false
                    viewModel.selectedDocumentForSigning = nil
                }
            )
        }
        .confirmationDialog("Quick Sign", isPresented: $viewModel.showQuickSignMenu) {
            Button("Create New Signature") {
                if let document = viewModel.selectedDocumentForSigning {
                    viewModel.createNewSignature(for: document)
                }
            }
            
            if !viewModel.signatureStorage.savedSignatures.isEmpty {
                ForEach(viewModel.signatureStorage.savedSignatures.prefix(3)) { signature in
                    Button("Use '\(signature.name)'") {
                        if let document = viewModel.selectedDocumentForSigning {
                            viewModel.applyExistingSignature(signature, to: document)
                        }
                    }
                }
                
                if viewModel.signatureStorage.savedSignatures.count > 3 {
                    Button("More Signatures...") {
                        // Open signature selector
                        viewModel.showSignatureCreator = true
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {
                viewModel.selectedDocumentForSigning = nil
            }
        } message: {
            if let document = viewModel.selectedDocumentForSigning {
                Text("Choose how to sign '\(document.name)'")
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView()
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

// MARK: - Document Row View with Quick Sign

struct DocumentRowViewWithSignature: View {
    let document: DocumentDTO
    let onTap: () -> Void
    let onQuickSign: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            
            // Document thumbnail with type indicator
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: document.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 80)
                    .clipped()
                    .background(Color.appGray.opacity(0.1))
                    .cornerRadius(8)
                
                // Use FileType icon instead of text badge
                document.type.icon
                    .offset(x: -4, y: -4)
            }
            
            // Document info
            VStack(alignment: .leading, spacing: 6) {
                Text(document.name)
                    .font(.semibold(16))
                    .foregroundColor(.appBlack)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.appGray)
                        
                        Text(document.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.regular(12))
                            .foregroundColor(.appGray)
                    }
                    
                    HStack(spacing: 4) {
                        Text(document.type.name.uppercased())
                            .font(.semibold(10))
                            .foregroundColor(typeColor)
                    }
                    
                    if document.isFavorite {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.appRed)
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            // Quick sign button
            Button(action: onQuickSign) {
                HStack(spacing: 6) {
                    Image(systemName: "signature")
                        .font(.system(size: 14, weight: .medium))
                    Text("Sign")
                        .font(.semiBold(12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.appRed)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(.appWhite)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.appStroke, lineWidth: 1)
        )
        .shadow(color: .appBlack.opacity(0.04), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    private var typeColor: Color {
        switch document.type {
        case .pdf:
            return .appRed
        case .image:
            return .appOrange
        case .text:
            return .appBlue
        }
    }
}

extension SignView {
    
    private func DocumentsListView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.documents) { document in
                        DocumentRowViewWithSignature(
                            document: document,
                            onTap: { viewModel.openDocument(document) },
                            onQuickSign: { viewModel.showQuickSignOptions(for: document) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 80)
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
