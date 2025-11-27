import SwiftUI

struct SubsView: View {
    
    @EnvironmentObject var premium: PremiumManager
    
    #warning("заменить на реальные продукты")
    var products: [SubscriptionItem] = SubscriptionItem.mocks(.main)
    
    @State private var selectedIndex = 0
    
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var isShowAlert = false
    
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        NavigationView {
            ZStack {
                background()
                
                VStack {
#warning("заменить UI")
                    Spacer()
                    VStack {
                        title("Mock Title")
                        subtitle(getSubtitle())
                        offers
                        nextButton
                        FooterView(color: Color.init(hex: "#AEAEB2"), font: .regular(12), onRestore: {
    #warning("restore tapped")
                        })
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                    .background {
                        UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
                            .fill(.clear)
                            .cornerRadius(16)
                            .overlay {
                                UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
                                    .stroke(Color.init(hex: "#E9ECEF"), lineWidth: 1)
                            }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation {
                            premium.presentPaywall(false)
                        }
                    }, label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .semibold))
                    })
                }
            }
            .alert(isPresented: $isShowAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage))
            }
        }
        .navigationViewStyle(.stack)
        .onRotate(perform: { orientation = $0 })
    }
    
    private var nextButton: some View {
        Button {
            purchaseTapped(index: selectedIndex)
        } label: {
            Text(getButtonTitle())
                .padding()
                .foregroundStyle(.white)
                .font(.medium(20))
                .frame(maxWidth: 600)
                .background { Color.appRed }
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        }
    }
    
    private var offers: some View {
        VStack(spacing: 4) {
            ForEach(Array(products.enumerated()), id: \.offset) { offset, offer in
                Button {
                    selectedIndex = offset
                    purchaseTapped(index: offset)
                } label: {
                    labelOffer(from: offer, index: offset)
                }
            }
        }
    }
    
    @ViewBuilder
    private func title(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.system(size: 28, weight: .medium))
    }
    
    @ViewBuilder
    private func subtitle(_ text: String) -> some View {
        
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
    }
    
    @ViewBuilder
    private func labelOffer(from offer: SubscriptionItem, index: Int) -> some View {
        let isSelected = selectedIndex == index
        
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(offer.title)
                    .foregroundStyle(.black)
                    .font(.system(size: 16, weight: .semibold))
                    .opacity(isSelected ? 1 : 0.7)
                Text(offer.pricePerWeek)
                    .foregroundStyle(.black.opacity(isSelected ? 0.6 : 0.35))
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(offer.pricePerPeriod)
                .foregroundStyle(.black)
                .font(.system(size: 16, weight: .semibold))
                .opacity(isSelected ? 1 : 0.7)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            backgroundOffer(isSelected: isSelected)
        )
    }
    
    @ViewBuilder
    private func backgroundOffer(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.25))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 0.5)
                        .foregroundStyle(.black.opacity(0.1))
                }
                .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
        }
    }
    
    @ViewBuilder
    private func background() -> some View {
        BackImage(baseName: "paywall")
            .overlay {
                if deviceType != .iphoneSE
                    && !orientation.isLandscape
                {
                    VStack {
                        LottieView(item: .onb_paywall)
                            .frame(width: deviceType == .ipad ? 250 : 100,
                                   height: deviceType == .ipad ? 250 : 100)
                            .padding(.top, deviceType == .ipad ? 30 : 50)
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
            }
    }
    
    //MARK: - logic
#warning("заменить UI")
    func getSubtitle() -> String {
        "Try 3 days free, then $4,99 / week"
    }
#warning("заменить UI")
    private func getButtonTitle() -> String {
        "Button purchase"
    }
    
#warning("заменить логику")
    func purchaseTapped(index: Int) {
        Task(priority: .userInitiated) { @MainActor in
            premium.isProcessing.toggle()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            premium.hasSubscription = true
            premium.isProcessing.toggle()
            withAnimation {
                premium.presentPaywall(false)
            }
        }
    }
    
    private func showError() {
        presentedAlert(title: "Error",
                       message: "Cancel")
        
    }
    
    private func presentedAlert(title: String, message: String) {
        alertMessage = message
        alertTitle = title
        isShowAlert.toggle()
    }
}
