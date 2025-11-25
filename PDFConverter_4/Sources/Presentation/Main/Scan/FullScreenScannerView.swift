import SwiftUI
import VisionKit

struct FullScreenScannerView: View {
    
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var pdfStorage: PDFConverterStorage
    @StateObject private var viewModel = ScannerViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                headerView
                
                if viewModel.isSupported {
                    if viewModel.scannedImages.isEmpty {
                        emptyStateView
                            .onAppear { print("🔍 UI State: Showing empty state view") }
                    } else {
                        scannedImagesView
                            .onAppear { print("📱 UI State: Showing scanned images view with \(viewModel.scannedImages.count) images") }
                    }
                } else {
                    unsupportedDeviceView
                        .onAppear { print("❌ UI State: Device not supported") }
                }
            }
            
            // Processing overlay
            if viewModel.isProcessing {
                processingOverlay
                    .onAppear { print("⏳ UI State: Showing processing overlay") }
            }
        }
        .onAppear {
            print("👀 FullScreenScannerView appeared")
            print("📊 isSupported: \(viewModel.isSupported), scannedImages count: \(viewModel.scannedImages.count)")
            
            if viewModel.isSupported && viewModel.scannedImages.isEmpty {
                print("🚀 Starting scanning...")
                viewModel.startScanning()
            }
        }
        .sheet(isPresented: $viewModel.isShowingScanner) {
            DocumentCameraScannerView(
                onScanCompleted: { images in
                    print("🔄 System Save button tapped! Got \(images.count) images")
                    viewModel.handleScanCompleted(images: images)
                    
                    // Automatically save when user taps system Save button
                    Task {
                        await saveScannedDocument()
                    }
                },
                onScanCancelled: { 
                    viewModel.handleScanCancelled()
                    router.dismissScanner()
                },
                onScanError: { error in
                    viewModel.handleScanError(error)
                    router.dismissScanner()
                }
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - UI Components

extension FullScreenScannerView {
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                router.dismissScanner()
            }
            .font(.regular(16))
            .foregroundColor(.appWhite)
            
            Spacer()
            
            Text("Document Scanner")
                .font(.semibold(18))
                .foregroundColor(.appWhite)
            
            Spacer()
            
            if !viewModel.scannedImages.isEmpty {
                Button("Save") {
                    print("💾 Header Save button tapped!")
                    Task {
                        await saveScannedDocument()
                    }
                }
                .font(.semibold(16))
                .foregroundColor(.appBlue)
            } else {
                Spacer()
                    .frame(width: 50)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.appWhite.opacity(0.8))
                
                VStack(spacing: 12) {
                    Text("Ready to Scan")
                        .font(.bold(24))
                        .foregroundColor(.appWhite)
                    
                    Text("Position your document and tap the scan button")
                        .font(.regular(16))
                        .foregroundColor(.appWhite.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: {
                viewModel.startScanning()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 20))
                    
                    Text("Start Scanning")
                        .font(.semibold(18))
                }
                .foregroundColor(.appWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appRed)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .opacity(0)
    }
    
    private var scannedImagesView: some View {
        VStack(spacing: 20) {
            // Pages count
            HStack {
                Text("Scanned Pages")
                    .font(.bold(20))
                    .foregroundColor(.appWhite)
                
                Spacer()
                
                Text("\(viewModel.scannedImages.count) pages")
                    .font(.medium(14))
                    .foregroundColor(.appWhite.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Images grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.scannedImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 160)
                            .background(Color.appWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("\(index + 1)")
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.black.opacity(0.7))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    Spacer()
                                }
                                .padding(8)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.clearScannedImages()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.medium(16))
                        .foregroundColor(.appWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appWhite.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        viewModel.startScanning()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add More")
                        }
                        .font(.medium(16))
                        .foregroundColor(.appWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appRed)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    print("💾 Bottom Save Document button tapped!")
                    Task {
                        await saveScannedDocument()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Save Document")
                    }
                    .font(.bold(16))
                    .foregroundColor(.appWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appBlue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var unsupportedDeviceView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.appOrange)
            
            Text("Scanner Not Available")
                .font(.bold(20))
                .foregroundColor(.appWhite)
            
            Text("Document scanning is not supported on this device")
                .font(.regular(16))
                .foregroundColor(.appWhite.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Close") {
                router.dismissScanner()
            }
            .font(.semibold(16))
            .foregroundColor(.appBlue)
            .padding(.top, 20)
        }
        .padding(.horizontal, 32)
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .appRed))
                
                Text("Processing Images...")
                    .font(.medium(16))
                    .foregroundColor(.appWhite)
            }
            .padding(32)
            .background(Color.appWhite.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Private Methods
    
    private func saveScannedDocument() async {
        guard !viewModel.scannedImages.isEmpty else {
            print("❌ No scanned images to save")
            return
        }
        
        print("🚀 Starting to save \(viewModel.scannedImages.count) scanned images...")
        
        do {
            viewModel.isProcessing = true
            
            // Create PDF from scanned images
            let fileName = "Scanned Document \(Date().formatted(date: .numeric, time: .omitted))"
            print("📄 Creating PDF with name: \(fileName)")
            
            let savedDocument = try await pdfStorage.convertImagesToPDF(viewModel.scannedImages, fileName: fileName)
            print("✅ Document saved with ID: \(savedDocument.id)")
            
            await MainActor.run {
                viewModel.isProcessing = false
                print("🔄 Dismissing scanner...")
                
                // First dismiss scanner
                router.dismissScanner()
                
                // Then navigate to detail view with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("🧭 Navigating to PDF detail view...")
                    router.push(.pdfDetail(savedDocument))
                }
            }
        } catch {
            await MainActor.run {
                viewModel.isProcessing = false
                print("❌ Failed to save scanned document: \(error.localizedDescription)")
                router.dismissScanner()
            }
        }
    }
}

#Preview {
    FullScreenScannerView()
        .environmentObject(Router())
        .environmentObject(PDFConverterStorage())
}
