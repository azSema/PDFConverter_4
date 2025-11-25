import SwiftUI
import UniformTypeIdentifiers

struct EditView: View {
    
    @EnvironmentObject private var storage: PDFConverterStorage
    @StateObject private var viewModel = EditViewModel()
    @State private var showDocumentTypePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "Edit",
                showProButton: true, content: {}
            )
            
            if viewModel.documents.isEmpty && !viewModel.isLoading {
                // Empty State
                addFileToEditVIew
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
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
            DocumentTypePickerSheet { fileType in
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
        .fullScreenCover(isPresented: $viewModel.showPDFEditor) {
            if let document = viewModel.selectedDocumentForEdit,
               let pdfDocument = document.pdf,
               let storage = viewModel.storage {
                PDFEditorView(
                    document: pdfDocument,
                    storage: storage
                )
            }
        }
    }
    
    private func handleFileTypeSelection(_ fileType: EditableFileType) {
        viewModel.showFilePicker = true
    }
    
    private var addFileToEditVIew: some View {
        Button {
            showDocumentTypePicker = true
        } label: {
            VStack(spacing: 24) {
                Image(.plus)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                Text("Add file to edit")
                    .foregroundStyle(.appBlack)
                    .font(.medium(15))
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.appWhite)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.appStroke, lineWidth: 1)
                    }
                    .shadow(color: .appBlack.opacity(0.05), radius: 4, y: 1)
            }
        }
    }
}


// MARK: - Documents List

struct DocumentsListView: View {
    @EnvironmentObject private var viewModel: EditViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.documents) { document in
                        DocumentRowViewWithEdit(
                            document: document,
                            onTap: { viewModel.openDocument(document) },
                            onQuickEdit: { viewModel.handleQuickEdit(document) }
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

// MARK: - Selection Toolbar

// MARK: - Document Type Picker

struct DocumentTypePickerSheet: View {
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
                                .foregroundColor(Color.appWhite)
                                .frame(width: 40)
                            
                            Text(fileType.rawValue + " Files")
                                .font(.medium(18))
                                .foregroundColor(Color.appGray)
                            
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
                                .stroke(Color.appGray, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Select File Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.appGray)
                }
            }
        }
    }
}



#Preview {
    EditView()
}

// MARK: - Document Row View with Edit Button

struct DocumentRowViewWithEdit: View {
    let document: DocumentDTO
    let onTap: () -> Void
    let onQuickEdit: () -> Void
    
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
            
            // Quick edit button
            Button(action: onQuickEdit) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                    Text("Edit")
                        .font(.semiBold(12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.appBlue)
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
