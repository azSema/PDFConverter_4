import SwiftUI

@main
struct PDFConverterApp: App {
    
    @StateObject private var router = Router()
    @StateObject private var pdfStorage = PDFConverterStorage()
    @StateObject private var premium = PremiumManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(router)
                .environmentObject(pdfStorage)
                .environmentObject(premium)
        }
    }
}
