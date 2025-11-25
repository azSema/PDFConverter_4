import SwiftUI

struct CustomToolbar: View {
    let title: String
    let showBackButton: Bool
    let showProButton: Bool
    let backAction: (() -> Void)?
    let proAction: (() -> Void)?
    
    init(
        title: String,
        showBackButton: Bool = false,
        showProButton: Bool = false,
        backAction: (() -> Void)? = nil,
        proAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.showProButton = showProButton
        self.backAction = backAction
        self.proAction = proAction
    }
    
    var body: some View {
        HStack {
            // Left Side - Back Button or Spacer
            if showBackButton {
                Button(action: backAction ?? {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "007AFF"))
                }
                .frame(width: 44, height: 44)
            } else {
                Spacer()
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Center - Title
            Text(title)
                .font(.semiBold(18))
                .foregroundColor(Color(hex: "000000"))
            
            Spacer()
            
            // Right Side - Pro Button or Spacer
            if showProButton {
                Button(action: proAction ?? {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "FFD700"))
                        
                        Text("PRO")
                            .font(.medium(14))
                            .foregroundColor(Color(hex: "007AFF"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "F0F8FF"))
                    .cornerRadius(16)
                }
            } else {
                Spacer()
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(hex: "FFFFFF"))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(hex: "E5E5E7")),
            alignment: .bottom
        )
    }
}

#Preview {
    VStack {
        CustomToolbar(
            title: "LiteConvert",
            showProButton: true
        )
        
        Spacer()
        
        CustomToolbar(
            title: "Edit",
            showBackButton: true,
            showProButton: true
        )
    }
}