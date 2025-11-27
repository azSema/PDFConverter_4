import SwiftUI
import Combine

final class PremiumManager: ObservableObject {
    
    @Published var isProcessing = false
    
    @Published var hasSubscription = false
    
    @Published var isPresentingPaywall = false
    
    func makePurchase() async {
        withAnimation { isProcessing = true }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            withAnimation {
                isProcessing = false
                hasSubscription = true
            }
        }
    }
    
    func presentPaywall(_ isPresenting: Bool) {
        withAnimation {
            isPresentingPaywall = isPresenting
        }
    }
    
}

// MARK: - Features
extension PremiumManager {
    
    func canEdit() -> Bool {
        hasSubscription
    }
    
    func canConvert(currentCount: Int) -> Bool {
        if hasSubscription { return true }
        return currentCount < 3
    }
    
    func canScan(currentCount: Int) -> Bool {
        if hasSubscription { return true }
        return currentCount < 3
    }
    
}
