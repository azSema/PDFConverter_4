import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onDocumentsPicked: ([URL]) -> Void
    
    init(
        allowedContentTypes: [UTType] = [.pdf],
        allowsMultipleSelection: Bool = false,
        onDocumentsPicked: @escaping ([URL]) -> Void
    ) {
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onDocumentsPicked = onDocumentsPicked
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onDocumentsPicked(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}

// MARK: - Convenience Views

struct PDFPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onDocumentPicked: (URL) -> Void
    
    var body: some View {
        DocumentPickerView(
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { urls in
            if let firstUrl = urls.first {
                onDocumentPicked(firstUrl)
            }
            dismiss()
        }
        .ignoresSafeArea()
    }
}

struct TextFilePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onDocumentPicked: (URL) -> Void
    
    var body: some View {
        DocumentPickerView(
            allowedContentTypes: FileType.text.UTTypes,
            allowsMultipleSelection: false
        ) { urls in
            if let firstUrl = urls.first {
                onDocumentPicked(firstUrl)
            }
            dismiss()
        }
        .ignoresSafeArea()
    }
}

struct ImagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var showFilePicker = false
    
    let onImagesPicked: ([UIImage]) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                Text("Select Images")
                    .font(.semiBold(18))
                    .foregroundColor(.appBlack)
                    .padding(.top, 8)
                
                VStack(spacing: 12) {
                    Button("Choose from Gallery") {
                        showImagePicker = true
                    }
                    .font(.semiBold(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appRed)
                    .cornerRadius(12)
                    .shadow(color: Color.appRed.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Button("Choose from Files") {
                        showFilePicker = true
                    }
                    .font(.semiBold(16))
                    .foregroundColor(Color.appRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appRed, lineWidth: 2)
                    )
                }
                .padding(.horizontal, 20)
            }
            
            Spacer(minLength: 20)
        }
        .sheet(isPresented: $showImagePicker) {
            PhotoLibraryPickerView { images in
                onImagesPicked(images)
                dismiss()
            }
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPickerView(
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { urls in
                let images = urls.compactMap { url -> UIImage? in
                    guard let data = try? Data(contentsOf: url) else { return nil }
                    return UIImage(data: data)
                }
                onImagesPicked(images)
                dismiss()
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Photo Library Picker

import PhotosUI

struct PhotoLibraryPickerView: UIViewControllerRepresentable {
    let onImagesPicked: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0 // 0 means no limit
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPickerView
        
        init(_ parent: PhotoLibraryPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let group = DispatchGroup()
            var images: [UIImage] = []
            
            for result in results {
                group.enter()
                
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.onImagesPicked(images)
            }
        }
    }
}

#Preview {
    VStack {
        Button("Pick PDF") {
            // Test action
        }
    }
    .sheet(isPresented: .constant(true)) {
        ImagePickerSheet { images in
            print("Selected \(images.count) images")
        }
    }
}
