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
    
    var iconName: String {
        switch self {
        case .convert: return "arrow.triangle.2.circlepath"
        case .edit: return "pencil.circle"
        case .scan: return "doc.viewfinder"
        case .sign: return "signature"
        case .settings: return "gearshape"
        }
    }
}

struct MainFlow: View {
    
    @State private var selectedTab: AppTab = .convert
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Main Content
            Group {
                switch selectedTab {
                case .convert:
                    ConvertView()
                case .edit:
                    EditView()
                case .scan:
                    ScanView()
                case .sign:
                    SignView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == tab ? Color(hex: "007AFF") : Color(hex: "8E8E93"))
                        
                        Text(tab.title)
                            .font(.medium(10))
                            .foregroundColor(selectedTab == tab ? Color(hex: "007AFF") : Color(hex: "8E8E93"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: "F8F9FA"))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(hex: "E5E5E7")),
            alignment: .top
        )
    }
}

#Preview {
    MainFlow()
}
