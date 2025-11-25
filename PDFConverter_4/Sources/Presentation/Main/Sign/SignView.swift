import SwiftUI

struct SignView: View {
    
    @State private var showDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "Sign",
                showProButton: true, content: {}
            )
            
            VStack(spacing: 0) {
                
                // Empty State
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "signature")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "C7C7CC"))
                    
                    VStack(spacing: 12) {
                        Text("No documents to sign")
                            .font(.semiBold(20))
                            .foregroundColor(Color(hex: "000000"))
                        
                        Text("Select a document to add your signature")
                            .font(.regular(16))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    
                    Button {
                        showDocumentPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            
                            Text("Select Document")
                                .font(.semiBold(16))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "007AFF"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Sign Features
                    VStack(spacing: 16) {
                        SignFeatureRow(
                            icon: "pencil.tip.crop.circle",
                            title: "Digital Signature",
                            description: "Create and place your signature"
                        )
                        
                        SignFeatureRow(
                            icon: "textformat.abc",
                            title: "Text Fields",
                            description: "Add text fields and annotations"
                        )
                        
                        SignFeatureRow(
                            icon: "calendar.badge.clock",
                            title: "Date Stamps",
                            description: "Insert current date and time"
                        )
                    }
                    .padding(.top, 32)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(hex: "FFFFFF"))
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { url in
                print("Selected document for signing: \(url)")
            }
        }
    }
}

struct SignFeatureRow: View {
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

#Preview {
    SignView()
}
