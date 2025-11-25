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
                EmptyEditState(onSelectFile: {
                    showDocumentTypePicker = true
                })
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
}

// MARK: - Empty State

struct EmptyEditState: View {
    let onSelectFile: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(Color.appGray.opacity(0.6))
                
                VStack(spacing: 16) {
                    Text("All files to edit")
                        .font(.semiBold(24))
                        .foregroundColor(Color.appWhite)
                    
                    Text("Select a file to start editing\n(PDF/Image/Text)")
                        .font(.regular(16))
                        .foregroundColor(Color.appGray)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                Button(action: onSelectFile) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("Select File")
                            .font(.semiBold(16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.appWhite)
                    .cornerRadius(16)
                    .shadow(color: Color.appWhite.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
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
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.documents) { document in
                        DocumentRowView(document: document)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
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

// MARK: - Document Row

struct DocumentRowView: View {
    let document: DocumentDTO
    @EnvironmentObject private var viewModel: EditViewModel
    
    var body: some View {
        Button {
            if viewModel.selectedDocuments.isEmpty {
                viewModel.openDocument(document)
            } else {
                viewModel.toggleDocumentSelection(document.id)
            }
        } label: {
            HStack(spacing: 16) {
                // Selection indicator
                if !viewModel.selectedDocuments.isEmpty {
                    Image(systemName: viewModel.selectedDocuments.contains(document.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(viewModel.selectedDocuments.contains(document.id) ? Color.appWhite : Color.appGray)
                        .font(.system(size: 20))
                }
                
                // Thumbnail
                Image(uiImage: document.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .background(Color.appWhite)
                    .cornerRadius(8)
                
                // Document info
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.semiBold(16))
                        .foregroundColor(Color.appGray)
                        .lineLimit(1)
                    
                    Text(document.type.rawValue.uppercased())
                        .font(.medium(12))
                        .foregroundColor(Color.appGray)
                    
                    Text(document.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.regular(12))
                        .foregroundColor(Color.appGray)
                }
                
                Spacer()
                
                // Favorite indicator
                if document.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
                
                // Edit indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.appGray)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appWhite)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.selectedDocuments.contains(document.id) ? Color.appWhite : Color.appGray, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                viewModel.toggleDocumentSelection(document.id)
            } label: {
                Label("Select", systemImage: "checkmark.circle")
            }
        }
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
