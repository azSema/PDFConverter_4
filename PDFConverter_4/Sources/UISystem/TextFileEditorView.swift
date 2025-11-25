import SwiftUI
import UniformTypeIdentifiers

struct TextFileEditorView: View {
    @State private var text = ""
    @State private var fileName = "Text Document"
    @State private var showingFilePicker = false
    @Environment(\.dismiss) private var dismiss
    
    let onConvert: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // File Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Name")
                        .font(.semiBold(16))
                        .foregroundColor(Color.appWhite)
                    
                    TextField("Enter file name", text: $fileName)
                        .font(.regular(16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.appGray)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.appBlack, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                
                // Content Options
                VStack(spacing: 16) {
                    Button("Load from File") {
                        showingFilePicker = true
                    }
                    .font(.medium(16))
                    .foregroundColor(Color.appWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appWhite, lineWidth: 2)
                    )
                    .padding(.horizontal, 16)
                    
                    Text("or type your text below:")
                        .font(.regular(14))
                        .foregroundColor(Color.appGray)
                }
                
                // Text Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.semiBold(16))
                        .foregroundColor(Color.appGray)
                        .padding(.horizontal, 16)
                    
                    TextEditor(text: $text)
                        .font(.regular(16))
                        .scrollContentBackground(.hidden)
                        .background(Color.appWhite)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.appGray, lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Convert Button
                Button("Convert to PDF") {
                    onConvert(text, fileName)
                    dismiss()
                }
                .font(.semiBold(16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(text.isEmpty ? Color.appGray : Color.appWhite)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .disabled(text.isEmpty)
            }
            .padding(.top, 20)
            .navigationTitle("Text to PDF")
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
        .sheet(isPresented: $showingFilePicker) {
            TextFilePickerSheet { url in
                loadTextFromFile(url: url)
            }
        }
    }
    
    private func loadTextFromFile(url: URL) {
        do {
            let loadedText = try String(contentsOf: url, encoding: .utf8)
            text = loadedText
            fileName = url.deletingPathExtension().lastPathComponent
        } catch {
            print("Failed to load text file: \(error)")
        }
    }
}

#Preview {
    TextFileEditorView { text, fileName in
        print("Convert: \(fileName) - \(text.prefix(50))...")
    }
}
