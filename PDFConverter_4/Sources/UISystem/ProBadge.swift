import SwiftUI

struct ProBadge: View {
    
    @EnvironmentObject var premium: PremiumManager
    
    var body: some View {
        Button {
            premium.presentPaywall(true)
        } label: {
            HStack(spacing: 4) {
                Image(.diamond)
                Text("Pro")
            }
            .foregroundStyle(.appWhite)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(goldenGradient)
            .clipShape(Capsule())
        }
    }
    
}

struct ProBanner: View {
    
    @EnvironmentObject var premium: PremiumManager
    
    var body: some View {
        Button {
            premium.presentPaywall(true)
        } label: {
            Image(.banner)
                .resizable()
                .scaledToFit()
                .padding(-26)
        }
    }
    
}
