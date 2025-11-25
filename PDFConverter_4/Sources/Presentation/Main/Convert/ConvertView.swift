import SwiftUI
import UniformTypeIdentifiers

struct ConvertView: View {
    
    @EnvironmentObject private var storage: PDFConverterStorage
    @StateObject private var viewModel = ConvertViewModel()
    @State private var inputText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ConvertOptionCard(option: .textToPDF, action: viewModel.handleTextToPDF)
                    
                        ConvertOptionCard(option: .imageToPDF, action: viewModel.handleImageToPDF)

                        ConvertOptionCard(option: .pdfToImage, action: viewModel.handlePDFToImage)
                    }
                    
                    Button {
                        viewModel.handlePDFImport()
                    } label: {
                        HStack(spacing: 24) {
                            FileType.pdf.icon
                            
                            Text("Import PDF")
                                .foregroundStyle(.appBlack)
                                .font(.medium(13))
                                .lineLimit(1)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(.appWhite)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.appGray, lineWidth: 1)
                        }
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .shadow(color: .appBlack.opacity(0.1), radius: 4, y: 1)
                    }
                                        
                }
                
                if viewModel.filteredDocuments.isEmpty {
                    if viewModel.documents.isEmpty {
                        emptyState
                    } else if viewModel.documents.isEmpty && viewModel.isLoading {
                        ZStack {
                            emptyState
                            ProgressView()
                        }
                    } else {
                        noResultsState
                    }
                } else {
                    documentsListView
                }
            }
        }
        .animation(.easeIn, value: viewModel.filteredDocuments)
        .frame(maxWidth: .infinity)
        .padding(.top, 130)
        .background(Color.appWhite)
        .overlay(alignment: .top, content: { toolbar })
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.isConverting {
                ConvertProgressView(progress: viewModel.convertProgress)
            }
        }
        .sheet(isPresented: $viewModel.showTextFilePicker) {
            TextFilePickerSheet { url in
                viewModel.handleTextFileImport(url: url)
            }
        }
        .sheet(isPresented: $viewModel.showTextEditor) {
            TextFileEditorView { text, fileName in
                Task {
                    await viewModel.convertTextToPDF(text: text, fileName: fileName)
                }
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePickerSheet { images in
                Task {
                    await viewModel.convertImagesToPDF(images: images, fileName: "Images Document")
                }
            }
            .presentationDetents([.fraction(0.33)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showFilePicker) {
            PDFPickerSheet { url in
                Task {
                    await viewModel.convertPDFToImages(fileURL: url)
                }
            }
        }
        .sheet(isPresented: $viewModel.showPDFImportPicker) {
            PDFPickerSheet { url in
                Task {
                    await viewModel.importPDFDocument(fileURL: url)
                }
            }
        }
        .alert("Conversion Successful", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                viewModel.dismissSuccess()
            }
        } message: {
            Text("Your document has been converted successfully!")
        }
        .alert("Conversion Error", isPresented: .constant(viewModel.conversionError != nil)) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let error = viewModel.conversionError {
                Text(error)
            }
        }
        .sheet(isPresented: $viewModel.showPDFPreview) {
            if let document = viewModel.selectedDocument {
                PDFDetailedPreview(document: document)
            }
        }
        .onAppear {
            viewModel.updateStorage(storage)
        }
    }
    
    private var toolbar: some View {
        CustomToolbar(
            title: "LiteConvert",
            showProButton: true,
            content: {
                VStack {
                    HStack {
                        HStack {
                            
                            TextField(
                                "",
                                text: $viewModel.searchText,
                                prompt: Text("Search").foregroundColor(.white)
                            )
                                .font(.regular(16))
                                .tint(.appWhite)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.appWhite)
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.appWhite.opacity(0.2))
                        .cornerRadius(10)
                    }
                    CustomHorizontalPicker(selectedFileType: $viewModel.selectedFileType)
                        .padding(.top, 8)
                        .padding(.bottom, -16)
                }
            }
        )
    }
    
    private var emptyState: some View {
        Image(.empty)
            .resizable()
            .scaledToFit()
            .padding(30)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.appGray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No results found")
                    .font(.semibold(18))
                    .foregroundColor(.appBlack)
                
                Text("Try adjusting your search or filter")
                    .font(.regular(14))
                    .foregroundColor(.appGray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private var documentsListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredDocuments) { document in
                DocumentRowView(document: document) {
                    viewModel.openDocument(document)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 80)
    }
}

struct ConvertProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 40))
                        .foregroundColor(.appRed)
                    
                    Text("Converting Document")
                        .font(.semiBold(18))
                        .foregroundColor(.appBlack)
                }
                
                VStack(spacing: 12) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.appRed))
                        .frame(width: 200)
                        .scaleEffect(y: 2)
                    
                    Text("\(Int(progress * 100))% Complete")
                        .font(.medium(14))
                        .foregroundColor(.appGray)
                }
            }
            .padding(32)
            .background(.appWhite)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ConvertView()
}

struct CustomHorizontalPicker: View {
    
    @Binding var selectedFileType: FileType?
    
    @Namespace var rectangleID
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            let options: [FileType?] = [nil] + FileType.allCases
            ForEach(options, id: \.self) { option in
                optionSegment(option)
            }
            
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func optionSegment(_ opt: FileType?) -> some View {
        if let opt {
            Button {
                withAnimation(.bouncy(duration: 0.3)) {
                    selectedFileType = opt
                }
            } label: {
                VStack(spacing: 4) {
                    Text(opt.name)
                        .font(.medium(14))
                        .foregroundColor(.white)
                        .opacity(selectedFileType == opt ? 1 : 0.5)
                    if selectedFileType == opt {
                        Rectangle()
                            .fill(.white)
                            .frame(width: nil, height: 1.5)
                            .padding(.horizontal, -5)
                            .matchedGeometryEffect(id: "rectangleID", in: rectangleID)
                    }
                }
                .fixedSize()
                .frame(maxWidth: .infinity)
            }
        } else {
            Button {
                withAnimation(.bouncy(duration: 0.3)) {
                    selectedFileType = opt
                }
            } label: {
                VStack(spacing: 4) {
                    Text("All files")
                        .font(.medium(14))
                        .foregroundColor(.white)
                        .opacity(selectedFileType == nil ? 1 : 0.5)
                    if selectedFileType == nil {
                        Rectangle()
                            .fill(.white)
                            .frame(width: nil, height: 1.5)
                            .padding(.horizontal, -5)
                            .matchedGeometryEffect(id: "rectangleID", in: rectangleID)
                    }
                }
                .fixedSize()
                .frame(maxWidth: .infinity)
            }
        }
    }
    
}

struct ConvertOptionCard: View {
    let option: ConvertOption
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack {
                Image(option.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 48)
                
                Text(option.title)
                    .foregroundStyle(.appBlack)
                    .font(.medium(13))
                    .lineLimit(1)
            }
            .padding(16)
            .background(.appWhite)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.appGray, lineWidth: 1)
            }
            .cornerRadius(12)
            .shadow(color: .appBlack.opacity(0.1), radius: 4, y: 1)
        }
    }
}

#Preview {
    ConvertView()
}
