import SwiftUI

struct SettingsView: View {
    
    @State private var showShareSheet = false
    @State private var showContactUs = false
    @State private var showPrivacyTerms = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "Settings",
                showProButton: true, content: {}
            )
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // App Info Section
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(Color.appWhite)
                        
                        VStack(spacing: 8) {
                            Text("LiteConvert")
                                .font(.semiBold(24))
                                .foregroundColor(Color.appWhite)
                            
                            Text("PDF Converter & Editor")
                                .font(.regular(16))
                                .foregroundColor(Color.appWhite)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                    
                    // Settings Options
                    VStack(spacing: 1) {
                        
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Share App",
                            showChevron: true
                        ) {
                            showShareSheet = true
                        }
                        
                        SettingsRow(
                            icon: "star.fill",
                            title: "Rate App",
                            showChevron: true
                        ) {
                            rateApp()
                        }
                        
                        SettingsRow(
                            icon: "envelope.fill",
                            title: "Contact Us",
                            showChevron: true
                        ) {
                            showContactUs = true
                        }
                        
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "App Version",
                            subtitle: appVersion,
                            showChevron: false
                        ) {
                            // No action
                        }
                        
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Privacy Policy & Terms",
                            showChevron: true
                        ) {
                            showPrivacyTerms = true
                        }
                    }
                    .background(Color.appWhite)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .background(Color.appWhite)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [URL(string: "https://apps.apple.com/app/liteconvert")!])
        }
        .sheet(isPresented: $showContactUs) {
            ContactUsView()
        }
        .sheet(isPresented: $showPrivacyTerms) {
            PrivacyTermsView()
        }
    }
    
    private func rateApp() {
        guard let url = URL(string: "https://apps.apple.com/app/liteconvert") else { return }
        UIApplication.shared.open(url)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.appWhite)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.regular(16))
                        .foregroundColor(Color.appWhite)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.regular(14))
                            .foregroundColor(Color.appWhite)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appWhite)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appWhite)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContactUsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Get in touch with us!")
                    .font(.semiBold(20))
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Button("Email Support") {
                        let email = "support@liteconvert.app"
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.regular(16))
                    .foregroundColor(Color.appWhite)
                }
                
                Spacer()
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PrivacyTermsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy & Terms of Service")
                        .font(.semiBold(20))
                        .padding(.bottom, 10)
                    
                    Text("This application respects your privacy and handles your data securely.")
                        .font(.regular(16))
                    
                    Text("All document processing is done locally on your device.")
                        .font(.regular(16))
                    
                    Text("We do not collect, store, or transmit your personal documents.")
                        .font(.regular(16))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Privacy & Terms")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
