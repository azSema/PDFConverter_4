import SwiftUI
import UniformTypeIdentifiers

struct EditView: View {
    
    @EnvironmentObject private var storage: PDFConverterStorage
    @StateObject private var viewModel: EditViewModel
    @State private var showDocumentTypePicker = false
    
    init() {
        self._viewModel = StateObject(wrappedValue: EditViewModel(storage: PDFConverterStorage()))
    }
    
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
            }
        }
        .background(Color.appWhite)
        .environmentObject(viewModel)
        .onAppear {
            viewModel.loadDocuments()
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
                DocumentDetailView(document: document)
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
            // Header with selection controls
            if !viewModel.selectedDocuments.isEmpty {
                SelectionToolbar()
            }
            
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
        
        // Floating Add Button
        .overlay(alignment: .bottomTrailing) {
            Button {
                viewModel.handleFileSelection()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.appWhite)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Selection Toolbar

struct SelectionToolbar: View {
    @EnvironmentObject private var viewModel: EditViewModel
    
    var body: some View {
        HStack {
            Button("Cancel") {
                viewModel.clearSelection()
            }
            .foregroundColor(Color.appWhite)
            
            Spacer()
            
            Text("\(viewModel.selectedDocuments.count) selected")
                .font(.medium(16))
                .foregroundColor(Color.appGray)
            
            Spacer()
            
            Button {
                viewModel.deleteDocuments()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appWhite)
    }
}

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

// MARK: - Document Detail View

struct DocumentDetailView: View {
    let document: DocumentDTO
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Document editing functionality coming soon")
                    .font(.regular(16))
                    .foregroundColor(Color.appGray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.appWhite)
                }
            }
        }
    }
}

#Preview {
    EditView()
        .environmentObject(PDFConverterStorage())
}
