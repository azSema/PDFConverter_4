import SwiftUI
import PDFKit

struct PDFConversionScreen: View {
    let document: DocumentDTO
    @EnvironmentObject private var storage: PDFConverterStorage
    @Environment(\.dismiss) private var dismiss
    
    @State private var isConverting = false
    @State private var convertedImages: [UIImage] = []
    @State private var conversionProgress: Double = 0
    @State private var conversionError: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            documentInfoView
            
            Spacer()
            
            // Conversion section
            if isConverting {
                conversionProgressView
            } else if !convertedImages.isEmpty {
                conversionResultsView
            } else {
                conversionOptionsView
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.appWhite)
        .alert("Error", isPresented: .constant(conversionError != nil)) {
            Button("OK") {
                conversionError = nil
            }
        } message: {
            if let error = conversionError {
                Text(error)
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("PDF converted to \(convertedImages.count) images successfully!")
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.regular(16))
            .foregroundColor(.appRed)
            
            Spacer()
            
            Text("Convert Document")
                .font(.semibold(18))
                .foregroundColor(.appBlack)
            
            Spacer()
            
            Text("Cancel")
                .font(.regular(16))
                .foregroundColor(.clear)
        }
        .padding(.top, 20)
    }
    
    private var documentInfoView: some View {
        VStack(spacing: 16) {
            Image(uiImage: document.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 160)
                .background(Color.appWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .appBlack.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 8) {
                Text(document.name)
                    .font(.semibold(18))
                    .foregroundColor(.appBlack)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("PDF Document")
                    .font(.medium(14))
                    .foregroundColor(.appGray)
            }
        }
    }
    
    private var conversionOptionsView: some View {
        VStack(spacing: 20) {
            Text("Conversion Options")
                .font(.semibold(18))
                .foregroundColor(.appBlack)
            
            Button(action: convertToImages) {
                HStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 24))
                        .foregroundColor(.appOrange)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Convert to Images")
                            .font(.semibold(16))
                            .foregroundColor(.appBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Extract all pages as separate image files")
                            .font(.regular(14))
                            .foregroundColor(.appGray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.appGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.appWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appStroke.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .appBlack.opacity(0.08), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var conversionProgressView: some View {
        VStack(spacing: 20) {
            Text("Converting PDF...")
                .font(.semibold(18))
                .foregroundColor(.appBlack)
            
            ProgressView(value: conversionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .appOrange))
                .frame(height: 8)
            
            Text("\(Int(conversionProgress * 100))%")
                .font(.medium(14))
                .foregroundColor(.appGray)
        }
        .padding()
    }
    
    private var conversionResultsView: some View {
        VStack(spacing: 20) {
            Text("Conversion Complete!")
                .font(.semibold(18))
                .foregroundColor(.appBlack)
            
            Text("Converted to \(convertedImages.count) images")
                .font(.medium(16))
                .foregroundColor(.appGray)
            
            // Preview grid of converted images
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(0..<min(convertedImages.count, 6), id: \.self) { index in
                    Image(uiImage: convertedImages[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appStroke.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
            
            Button("Save Images") {
                showSuccessAlert = true
            }
            .font(.semibold(16))
            .foregroundColor(.appWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appRed)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func convertToImages() {
        guard !isConverting else { return }
        
        Task {
            await performConversion()
        }
    }
    
    @MainActor
    private func performConversion() async {
        isConverting = true
        conversionProgress = 0
        conversionError = nil
        
        do {
            // Update progress
            conversionProgress = 0.3
            
            let images = try await storage.convertPDFToImages(document)
            
            // Update progress
            conversionProgress = 0.8
            
            // Save images to storage as individual documents
            for (index, image) in images.enumerated() {
                let imageName = "\(document.name.replacingOccurrences(of: ".pdf", with: "")) - Page \(index + 1)"
                
                // Create temporary URL for image
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(imageName).png")
                
                if let imageData = image.pngData() {
                    try imageData.write(to: tempURL)
                    
                    let imageDoc = DocumentDTO(
                        name: imageName,
                        type: .image,
                        date: Date(),
                        url: tempURL,
                        isFavorite: false
                    )
                    
                    try await storage.saveDocument(imageDoc)
                }
            }
            
            convertedImages = images
            conversionProgress = 1.0
            isConverting = false
            
        } catch {
            isConverting = false
            conversionError = "Failed to convert PDF: \(error.localizedDescription)"
        }
    }
}
