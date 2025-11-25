import SwiftUI

@main
struct PDFConverterApp: App {
    
    @StateObject private var router = Router()
    @StateObject private var pdfStorage = DocumentStorage()
    @StateObject private var premium = PremiumManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(pdfStorage)
                .environmentObject(premium)
        }
    }
}