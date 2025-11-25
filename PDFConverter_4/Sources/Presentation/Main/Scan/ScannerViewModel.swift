import SwiftUI
import Combine
import VisionKit

@MainActor
final class ScannerViewModel: ObservableObject {
    
    @Published var isShowingScanner: Bool = false
    @Published var scannedImages: [UIImage] = []
    @Published var isProcessing: Bool = false
    
    private let scannerService = ScannerService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind scanner service properties to view model
        scannerService.$scannedImages
            .receive(on: DispatchQueue.main)
            .assign(to: &$scannedImages)
        
        scannerService.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isProcessing)
    }
    
    // MARK: - Actions
    
    func startScanning() {
        guard scannerService.isSupported else {
            print("Scanner not supported on this device")
            return
        }
        isShowingScanner = true
        scannerService.startScanning()
    }
    
    func handleScanCompleted(images: [UIImage]) {
        isShowingScanner = false
        scannerService.handleScanCompleted(images: images)
    }
    
    func handleScanCancelled() {
        isShowingScanner = false
        scannerService.handleScanCancelled()
    }
    
    func handleScanError(_ error: Error) {
        isShowingScanner = false
        scannerService.handleScanError(error)
    }
    
    func clearScannedImages() {
        scannerService.clearScannedImages()
    }
    
    var isSupported: Bool {
        scannerService.isSupported
    }
}