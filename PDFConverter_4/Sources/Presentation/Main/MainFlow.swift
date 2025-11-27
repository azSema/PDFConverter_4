import SwiftUI
import StoreKit

enum AppTab: CaseIterable {
    case convert
    case scan
    case edit
    case settings
    
    var title: String {
        switch self {
        case .convert: return "Convert"
        case .edit: return "Edit"
        case .scan: return "Scan"
        case .settings: return "Settings"
        }
    }
    
    var selectedIcon: ImageResource {
        switch self {
        case .convert:
                .convertSelected
        case .edit:
                .editSelected
        case .scan:
                .scan
        case .settings:
                .settingsSelected
        }
    }
    
    var nonSelectedIcon: ImageResource {
        switch self {
        case .convert:
                .convertNonSelected
        case .edit:
                .editNonSelected
        case .scan:
                .scan
        case .settings:
                .settingsNonSelected
        }
    }
}

struct MainFlow: View {
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var pdfStorage: PDFConverterStorage
    
    @AppStorage("didRequestedReview") var didRequestedReview = false
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $router.selectedTab) {
                
                ConvertView()
                    .tag(AppTab.convert)
                
                EditView()
                    .tag(AppTab.edit)
                
                EmptyView()
                    .tag(AppTab.scan)
                
                SettingsView()
                    .tag(AppTab.settings)
            }
            .navigationDestination(for: Destination.self) { destination in
                destination.makeView()
                    .environmentObject(pdfStorage)
                    .environmentObject(router)
            }
            .overlay(
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $router.selectedTab)
                }
            )
            .ignoresSafeArea(.all, edges: .bottom)
            .fullScreenCover(isPresented: $router.isShowingScanner) {
                FullScreenScannerView()
                    .environmentObject(router)
                    .environmentObject(pdfStorage)
            }
            .onAppear(perform: requestReview)
        }
    }
    
    func requestReview() {
        if didRequestedReview { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: windowScene)
        didRequestedReview = true
    }
    
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var animation
    
    @EnvironmentObject var premium: PremiumManager
    @EnvironmentObject var pdfStorage: PDFConverterStorage
    
    
    var body: some View {
        
        HStack(spacing: 8) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                HStack(spacing: 28) {
                    Button {
                        if tab == .scan {
                            guard premium.canScan(currentCount: pdfStorage.documents.count) else { return
                                premium.presentPaywall(true)
                                return
                            }
                        }
                        selectedTab = tab
                    } label: {
                        Image(selectedTab == tab ? tab.selectedIcon : tab.nonSelectedIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == tab ? .appRed : .appStroke)
                    }
                    if tab != .settings {
                        Rectangle()
                            .fill(.appStroke)
                            .frame(width: 1, height: 16)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 24)
        .background(Color.appWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
        .padding(20)
        .padding(.bottom, 10)
    }
}

#Preview {
    MainFlow()
}
