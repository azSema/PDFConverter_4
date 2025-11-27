import SwiftUI
import Lottie

enum LottieItem: String, CaseIterable {
    case onb2 = "onb 2"
    case onb_paywall = "onb 5-6"

    var fileName: String {
        return rawValue
    }
}

struct LottieView: UIViewRepresentable {
    let item: LottieItem

    let animationView = LottieAnimationView()
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        
        animationView.animation = LottieAnimation.named(item.fileName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        
        view.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        animationView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
