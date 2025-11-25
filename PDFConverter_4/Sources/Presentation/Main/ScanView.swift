import SwiftUI

struct ScanView: View {
    
    @State private var showScanner = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "Scan",
                showProButton: true
            )
            
            VStack(spacing: 0) {
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Scanner Icon
                    VStack(spacing: 16) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: "007AFF"))
                        
                        VStack(spacing: 12) {
                            Text("Document Scanner")
                                .font(.semiBold(24))
                                .foregroundColor(Color(hex: "000000"))
                            
                            Text("Scan documents using your camera\nwith AI-powered edge detection")
                                .font(.regular(16))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    
                    // Scan Button
                    Button {
                        showScanner = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                            
                            Text("Start Scanning")
                                .font(.semiBold(18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "007AFF"))
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 32)
                    
                    // Features List
                    VStack(spacing: 12) {
                        ScanFeatureRow(
                            icon: "doc.text.magnifyingglass",
                            title: "Auto Detection",
                            description: "Automatically detects document edges"
                        )
                        
                        ScanFeatureRow(
                            icon: "wand.and.rays",
                            title: "Enhancement",
                            description: "Enhances quality and removes shadows"
                        )
                        
                        ScanFeatureRow(
                            icon: "square.and.arrow.down",
                            title: "Save as PDF",
                            description: "Export scanned documents as PDF"
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
        }
        .background(Color(hex: "FFFFFF"))
        .fullScreenCover(isPresented: $showScanner) {
            ScannerViewController()
        }
    }
}

struct ScanFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "007AFF"))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.medium(16))
                    .foregroundColor(Color(hex: "000000"))
                
                Text(description)
                    .font(.regular(14))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// TODO: Integrate Vision API Scanner from PDFScanner_1
struct ScannerViewController: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        
        let label = UILabel()
        label.text = "Scanner Coming Soon..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    ScanView()
}