import SwiftUI
import Combine
import VisionKit

enum ScannerState {
    case idle
    case scanning
    case processing
    case completed([UIImage])
    case error(Error)
}

@MainActor
final class ScannerService: ObservableObject {
    
    @Published var scannedImages: [UIImage] = []
    @Published var isProcessing: Bool = false
    @Published var state: ScannerState = .idle
    @Published var isSupported: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkDeviceSupport()
        setupStateBindings()
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard isSupported else {
            print("Document scanning is not supported on this device")
            state = .error(ScannerError.deviceNotSupported)
            return
        }
        
        state = .scanning
        print("Started document scanning")
    }
    
    func handleScanCompleted(images: [UIImage]) {
        print("Scan completed with \(images.count) images")
        
        scannedImages = images
        state = .processing
        isProcessing = true
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.completeScanProcessing(images: images)
        }
    }
    
    func handleScanCancelled() {
        print("Scanning cancelled by user")
        
        isProcessing = false
        state = .idle
        clearScannedImages()
    }
    
    func handleScanError(_ error: Error) {
        print("Scanning error: \(error.localizedDescription)")
        
        isProcessing = false
        state = .error(error)
        clearScannedImages()
    }
    
    func clearScannedImages() {
        scannedImages.removeAll()
        isProcessing = false
        state = .idle
    }
    
    func resetToIdle() {
        state = .idle
        isProcessing = false
    }
    
    // MARK: - Private Methods
    
    private func checkDeviceSupport() {
        isSupported = VNDocumentCameraViewController.isSupported
        print("Scanner device support: \(isSupported)")
    }
    
    private func setupStateBindings() {
        // Bind state changes to published properties
        $state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.handleStateChange(newState)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ newState: ScannerState) {
        switch newState {
        case .idle:
            isProcessing = false
            
        case .scanning:
            isProcessing = false
            
        case .processing:
            isProcessing = true
            
        case .completed(let images):
            isProcessing = false
            scannedImages = images
            print("Scan processing completed successfully")
            
        case .error(let error):
            isProcessing = false
            print("Scanner error: \(error.localizedDescription)")
        }
    }
    
    private func completeScanProcessing(images: [UIImage]) {
        state = .completed(images)
        print("Scan processing completed with \(images.count) pages")
        
        // TODO: Integrate with PDFConverterStorage to save scanned documents
    }
}

// MARK: - Scanner Errors

enum ScannerError: LocalizedError {
    case deviceNotSupported
    case processingFailed
    case savingFailed
    
    var errorDescription: String? {
        switch self {
        case .deviceNotSupported:
            return "Document scanning is not supported on this device"
        case .processingFailed:
            return "Failed to process scanned images"
        case .savingFailed:
            return "Failed to save scanned document"
        }
    }
}