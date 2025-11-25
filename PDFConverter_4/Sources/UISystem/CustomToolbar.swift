import SwiftUI

struct CustomToolbar<ToolBarContent: View>: View {
    let title: String
    let showBackButton: Bool
    let showProButton: Bool
    @ViewBuilder let content: ToolBarContent?
    let backAction: (() -> Void)?
    let proAction: (() -> Void)?
    
    init(
        title: String,
        showBackButton: Bool = false,
        showProButton: Bool = false,
        @ViewBuilder content: () -> ToolBarContent,
        backAction: (() -> Void)? = nil,
        proAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.showProButton = showProButton
        self.content = content()
        self.backAction = backAction
        self.proAction = proAction
    }
    
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
        self.content = nil
        self.backAction = backAction
        self.proAction = proAction
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                
                backButton
                
                Text(title)
                    .font(.semibold(28))
                    .foregroundColor(Color.appWhite)
                
                Spacer()
                
                proBadge
            }
            if let content {
                content
            }
        }
        
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
        .background(Color.appRed)
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0, bottomLeading: 12, bottomTrailing: 12, topTrailing: 0)))
        .shadow(color: .appBlack.opacity(0.15), radius: 16, y: 4)
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var backButton: some View {
        if showBackButton {
            Button(action: backAction ?? {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.appWhite)
            }
            .frame(width: 32, height: 32)
        } 
    }
    
    @ViewBuilder
    private var proBadge: some View {
        if showProButton {
            ProBadge()
        } else {
            Spacer()
                .frame(width: 32, height: 32)
        }
    }
    
}
