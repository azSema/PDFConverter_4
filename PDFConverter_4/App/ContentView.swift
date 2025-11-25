import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var pdfStorage: PDFConverterStorage
    @EnvironmentObject private var premium: PremiumManager
    
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
    }
    
}

