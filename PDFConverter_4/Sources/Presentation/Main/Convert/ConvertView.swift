import SwiftUI
import UniformTypeIdentifiers

struct ConvertView: View {
    
    @StateObject private var viewModel = ConvertViewModel()
    @State private var inputText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                HStack(spacing: 12) {
                    ConvertOptionCard(option: .textToPDF, action: viewModel.handleTextToPDF)
                
                    ConvertOptionCard(option: .imageToPDF, action: viewModel.handleImageToPDF)

                    ConvertOptionCard(option: .pdfToImage, action: viewModel.handlePDFToImage)
                }
                
                if true {
                    emptyState
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 130)
        .background(Color.appWhite)
        .overlay(alignment: .top, content: { toolbar })
        .overlay {
            if viewModel.isConverting {
                ConvertProgressView(progress: viewModel.convertProgress)
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
        }
        .sheet(isPresented: $viewModel.showFilePicker) {
            PDFPickerSheet { url in
                Task {
                    await viewModel.convertPDFToImages(fileURL: url)
                }
            }
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
}

struct ConvertProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.appWhite))
                .frame(width: 200)
            
            Text("Converting... \(Int(progress * 100))%")
                .font(.medium(16))
                .foregroundColor(Color.appGray)
        }
        .padding(24)
        .background(Color.appRed)
        .cornerRadius(12)
        .shadow(radius: 10)
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
