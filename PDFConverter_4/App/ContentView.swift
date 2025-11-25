import SwiftUI

struct ContentView: View {
    
    @StateObject private var router = Router()
    @StateObject private var pdfStorage = PDFConverterStorage()
    @StateObject private var premium = PremiumManager()
    
    var body: some View {
        
        Group {
            if router.isOnboarding {
                OnboardingFlow()
            } else {
                MainFlow()
            }
        }
        .overlay {
             if premium.isProcessing {
                 AppLoaderView()
             }
         }
         .animation(.easeInOut, value: premium.isProcessing)
         .environmentObject(router)
         .environmentObject(pdfStorage)
         .environmentObject(premium)
    }
    
}

