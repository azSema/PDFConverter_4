import SwiftUI
import Combine

final class Router: ObservableObject {
    
    @AppStorage("isOnboarding") var isOnboarding = true
    
    @Published var path: [Destination] = []
    @Published var selectedTab: AppTab = .convert
    
    // Scanner state
    @Published var isShowingScanner = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupScannerBinding()
    }
    
    private func setupScannerBinding() {
        // Automatically show scanner when scan tab is selected
        $selectedTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tab in
                if tab == .scan {
                    self?.isShowingScanner = true
                }
            }
            .store(in: &cancellables)
    }
    
    func finishOnboarding() {
        withAnimation { isOnboarding = false }
    }
    
    func push(_ route: Destination) {
        path.append(route)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func dismissScanner() {
        isShowingScanner = false
        // Switch back to convert tab after scanner dismissal
        if selectedTab == .scan {
            selectedTab = .convert
        }
    }
    
}

enum Destination: Hashable {
    case home(HomeRoute)
    case history(HistoryRoute)
    case pdfDetail(DocumentDTO)
    case pdfEditor(DocumentDTO)
    case pdfConverter(DocumentDTO)
}

extension Destination: AppDesination {
    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .home(let r):
            r.makeView()
        case .history(let r):
            r.makeView()
        case .pdfDetail(let document):
            PDFDetailedPreview(document: document)
                .environmentObject(ConvertViewModel())
        case .pdfEditor(let document):
            PDFEditorScreen(document: document)
        case .pdfConverter(let document):
            PDFConversionScreen(document: document)
        }
    }
}

protocol AppDesination: Hashable {
    associatedtype Screen: View
    @ViewBuilder func makeView() -> Screen
}

enum HomeRoute: AppDesination {
    case start
    case result(id: UUID)

    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .start: Text("Start")
        case .result(let id):Text("Result")
        }
    }
}

enum HistoryRoute: AppDesination {
    case editor(id: UUID)

    @ViewBuilder
    func makeView() -> some View {
        Text("Edit")
    }
}

