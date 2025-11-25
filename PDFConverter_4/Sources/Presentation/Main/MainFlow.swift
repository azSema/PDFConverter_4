import SwiftUI

enum AppTab: CaseIterable {
    case convert
    case edit
    case scan
    case sign
    case settings
    
    var title: String {
        switch self {
        case .convert: return "Convert"
        case .edit: return "Edit"
        case .scan: return "Scan"
        case .sign: return "Sign"
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
        case .sign:
                .signSelected
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
        case .sign:
                .signNonSelected
        case .settings:
                .settingsNonSelected
        }
    }
}

struct MainFlow: View {
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var pdfStorage: PDFConverterStorage
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
             
             ConvertView()
                 .tag(AppTab.convert)
             
             EditView()
                 .tag(AppTab.edit)
             
             ScanView()
                 .tag(AppTab.scan)
             
             SignView()
                 .tag(AppTab.sign)
             
             SettingsView()
                 .tag(AppTab.settings)
         }
         .overlay(
             VStack {
                 Spacer()
                 CustomTabBar(selectedTab: $router.selectedTab)
             }
         )
         .ignoresSafeArea(.all, edges: .bottom)
     }
    
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var animation
    
    var body: some View {
        
        HStack(spacing: 8) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                HStack(spacing: 20) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
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
