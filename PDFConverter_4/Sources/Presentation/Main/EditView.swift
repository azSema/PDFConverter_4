import SwiftUI

struct EditView: View {
    
    @State private var showDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "Edit",
                showProButton: true
            )
            
            VStack(spacing: 0) {
                
                // Empty State
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "C7C7CC"))
                    
                    VStack(spacing: 12) {
                        Text("No files to edit")
                            .font(.semiBold(20))
                            .foregroundColor(Color(hex: "000000"))
                        
                        Text("Select a file to start editing")
                            .font(.regular(16))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    
                    Button {
                        showDocumentPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            
                            Text("Select File")
                                .font(.semiBold(16))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "007AFF"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(hex: "FFFFFF"))
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { url in
                // Handle selected document
                print("Selected document: \(url)")
            }
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .text])
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
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

#Preview {
    EditView()
}