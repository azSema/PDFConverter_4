import SwiftUI
import MessageUI

struct SettingsView: View {
    
    @State private var showShareSheet = false
    @State private var showContactAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    @EnvironmentObject var premium: PremiumManager
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "Settings",
                showProButton: !premium.hasSubscription, content: {}
            )
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // App Info Section
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Color.appRed)
                        
                        VStack(spacing: 4) {
                            Text("LiteConvert")
                                .font(.semiBold(24))
                                .foregroundColor(Color.appBlack)
                            
                            Text("PDF Converter & Editor")
                                .font(.regular(16))
                                .foregroundColor(Color.appGray)
                        }
                    }
                    .padding(.bottom, 40)
                    
                    // Settings Options
                    VStack(spacing: 8) {
                        
                        if !premium.hasSubscription {
                            ProBanner()
                        }
                        
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
                            contactUs()
                        }
                        
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Privacy Policy",
                            showChevron: true
                        ) {
                            showPrivacyPolicy = true
                        }
                        
                        SettingsRow(
                            icon: "doc.plaintext.fill",
                            title: "Terms of Use",
                            showChevron: true
                        ) {
                            showTermsOfUse = true
                        }
                        
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "App Version",
                            subtitle: appVersion,
                            showChevron: false
                        ) {
                            // No action
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .padding(.top, -20)
        }
        .background(Color.appWhite)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [AppConstants.shareURL])
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfUse) {
            TermsOfUseView()
        }
        .alert("Contact Us", isPresented: $showContactAlert) {
            Button("OK") { }
        } message: {
            Text("Please email us at \(AppConstants.supportEmail)")
        }
    }
    
    private func rateApp() {
        guard let url = URL(string: AppConstants.appStoreURL) else { return }
        UIApplication.shared.open(url)
    }
    
    private func contactUs() {
        let emailURL = URL(string: "mailto:\(AppConstants.supportEmail)")
        
        if let emailURL = emailURL, UIApplication.shared.canOpenURL(emailURL) {
            UIApplication.shared.open(emailURL)
        } else {
            showContactAlert = true
        }
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
                    .foregroundColor(Color.appRed)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.regular(16))
                        .foregroundColor(Color.appBlack)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.regular(14))
                            .foregroundColor(Color.appGray)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appGray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.appWhite)
            .cornerRadius(12)
            .shadow(color: .appBlack.opacity(0.1), radius: 8)
        }

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

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Privacy Policy")
                        .font(.semiBold(24))
                        .foregroundColor(.appBlack)
                        .padding(.bottom, 10)
                    
                    Group {
                        privacySection(
                            title: "Information Collection",
                            content: "LiteConvert does not collect, store, or transmit any personal information or documents. All processing is done locally on your device."
                        )
                        
                        privacySection(
                            title: "Document Processing",
                            content: "Your documents are processed entirely on your device. We never have access to your files or their content."
                        )
                        
                        privacySection(
                            title: "Data Security",
                            content: "Since no data leaves your device, your privacy and security are guaranteed. Your documents remain completely private."
                        )
                        
                        privacySection(
                            title: "Updates to Privacy Policy",
                            content: "We may update this privacy policy from time to time. Any changes will be posted in this section."
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.appRed)
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.semiBold(18))
                .foregroundColor(.appBlack)
            
            Text(content)
                .font(.regular(16))
                .foregroundColor(.appGray)
                .lineSpacing(4)
        }
    }
}

struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Terms of Use")
                        .font(.semiBold(24))
                        .foregroundColor(.appBlack)
                        .padding(.bottom, 10)
                    
                    Group {
                        termsSection(
                            title: "Acceptance of Terms",
                            content: "By using LiteConvert, you agree to these terms of use. If you do not agree with any part of these terms, you may not use our application."
                        )
                        
                        termsSection(
                            title: "Permitted Use",
                            content: "LiteConvert is intended for converting and editing PDF documents. You may use the app for personal or commercial purposes in accordance with applicable laws."
                        )
                        
                        termsSection(
                            title: "Restrictions",
                            content: "You may not reverse engineer, modify, or distribute the application. You are responsible for ensuring your use complies with applicable laws."
                        )
                        
                        termsSection(
                            title: "Disclaimer",
                            content: "LiteConvert is provided \"as is\" without warranties. We are not liable for any damages resulting from the use of this application."
                        )
                        
                        termsSection(
                            title: "Changes to Terms",
                            content: "We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of any changes."
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .navigationTitle("Terms of Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.appRed)
                }
            }
        }
    }
    
    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.semiBold(18))
                .foregroundColor(.appBlack)
            
            Text(content)
                .font(.regular(16))
                .foregroundColor(.appGray)
                .lineSpacing(4)
        }
    }
}

#Preview {
    SettingsView()
}
