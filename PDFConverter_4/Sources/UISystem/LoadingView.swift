import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.appGray.opacity(0.3), lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.appRed, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                }
                
                VStack(spacing: 8) {
                    Text("Loading Documents")
                        .font(.semiBold(16))
                        .foregroundColor(.appBlack)
                    
                    Text("Please wait while we load your documents")
                        .font(.regular(14))
                        .foregroundColor(.appGray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(.appWhite)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 40)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingView()
}