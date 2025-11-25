import SwiftUI
import PhotosUI
import PDFKit
import UniformTypeIdentifiers

struct PDFEditorView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var editService = PDFEditService()

    let document: PDFDocument
    let storage: PDFConverterStorage
        
    @State private var selectedPhotosPickerItems: [PhotosPickerItem] = []
    @State private var showingUnsavedChangesAlert = false
    
    var body: some View {
        ZStack {
            Color.appWhite
                .ignoresSafeArea()
            
            // Main PDF Content
            if editService.pdfDocument != nil {
                VStack(spacing: 0) {
                    // PDF Editor View with Overlays
                    GeometryReader { geometry in
                        
                        ZStack {
                            
                            PDFEditorView_Internal(editService: editService)
                                .onReceive(editService.$insertionPoint) { point in
                                    if editService.showingImagePicker && point != .zero {
                                        editService.insertionGeometry = geometry.size
                                    }
                                }
                                .offset(x: 18)
                                .offset(y: 36)
                            
                            if let signatureAnnotation = editService.activeSignatureOverlay {
                                SignatureOverlay(
                                    editService: editService,
                                    annotation: Binding<IdentifiablePDFAnnotation>(
                                        get: { editService.activeSignatureOverlay ?? signatureAnnotation },
                                        set: { editService.activeSignatureOverlay = $0 }
                                    ),
                                    geometry: geometry
                                )
                                .onTapGesture(count: 2) {
                                    editService.finalizeSignatureOverlay()
                                }
                                
                                VStack {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 8) {
                                            Text("Position your signature")
                                                .font(.medium(14))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.black.opacity(0.7))
                                                .cornerRadius(8)
                                            
                                            Button("Done") {
                                                editService.finalizeSignatureOverlay()
                                            }
                                            .font(.medium(14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.appRed)
                                            .cornerRadius(8)
                                        }
                                        .padding(.top, 80) // Ниже navigation buttons
                                        .padding(.trailing, 16)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            
                            // Image overlay when active
                            if let imageAnnotation = editService.activeImageOverlay {
                                ImageOverlay(
                                    editService: editService,
                                    annotation: Binding<IdentifiablePDFAnnotation>(
                                        get: { editService.activeImageOverlay ?? imageAnnotation },
                                        set: { editService.activeImageOverlay = $0 }
                                    ),
                                    geometry: geometry
                                )
                                .onTapGesture(count: 2) {
                                    editService.finalizeImageOverlay()
                                }
                                
                                // Image overlay instruction
                                VStack {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 8) {
                                            Text("Position your image")
                                                .font(.medium(14))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.black.opacity(0.7))
                                                .cornerRadius(8)
                                            
                                            Button("Done") {
                                                editService.finalizeImageOverlay()
                                            }
                                            .font(.medium(14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.appRed)
                                            .cornerRadius(8)
                                        }
                                        .padding(.top, 80) // Ниже navigation buttons
                                        .padding(.trailing, 16)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .pdfDocumentFrame(
                            pageRect: editService.currentPage?.bounds(for: .mediaBox) ?? CGRect(x: 0, y: 0, width: 595, height: 842),
                            rotation: Int(editService.currentPage?.rotation ?? 0),
                            maxRatio: 0.7
                        )
                    }
                    
                    // Toolbar внизу
                    if editService.isToolbarVisible {
                        EditorToolbar(editService: editService)
                    }
                }
                
                // Processing overlay
                if editService.isProcessing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .appRed))
                        
                        Text("Saving changes...")
                            .font(.medium(16))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
            }
            
            // Overlay navigation buttons ПОВЕРХ всего!
            VStack {
                HStack {
                    // Back button
                    Button(action: handleBackAction) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.regular(16))
                        }
                        .foregroundColor(.appBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appWhite.opacity(0.95))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button(action: {
                        Task {
                            await editService.saveDocument()
                        }
                    }) {
                        Text("Save")
                            .font(.semiBold(16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.appRed)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Save") {
                Task {
                    await editService.saveDocument()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Do you want to save them before leaving?")
        }
        .onAppear {
            editService.loadDocument(document, storage: storage)
        }
        .onDisappear {
            editService.deselectTool()
        }
        // PhotosPicker for adding images
        .photosPicker(
            isPresented: $editService.showingImagePicker,
            selection: $selectedPhotosPickerItems,
            maxSelectionCount: 1,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotosPickerItems) { items in
            guard let item = items.first else { return }
            
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        if editService.insertionPoint != .zero {
                            editService.insertImageAtStoredPoint(image)
                        } else {
                            editService.createImageOverlay(with: image)
                        }
                        selectedPhotosPickerItems.removeAll()
                    }
                }
            }
        }
        // Signature creator sheet
        .sheet(isPresented: $editService.showingSignatureCreator) {
            SignatureCreatorView { signature in
                editService.saveSignature(signature)
            } onCancel: {
                editService.resetSignatureService()
            }
        }
    }
    
    private func handleBackAction() {
        if editService.hasUnsavedChanges {
            showingUnsavedChangesAlert = true
        } else {
            dismiss()
        }
    }
}

// Renamed internal PDFView to avoid conflicts
struct PDFEditorView_Internal: UIViewRepresentable {
    
    @ObservedObject var editService: PDFEditService
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure PDF view
        pdfView.backgroundColor = UIColor.systemBackground
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.pageBreakMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // Set delegate for interactions
        pdfView.delegate = context.coordinator
        
        // Set PDFView reference in EditService for coordinate calculations
        editService.setPDFViewReference(pdfView)
        
        // Add gesture recognizers and notifications
        setupGestureRecognizers(for: pdfView, coordinator: context.coordinator)
        setupNotifications(for: pdfView, coordinator: context.coordinator)
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update document
        if let document = editService.pdfDocument {
            pdfView.document = document
            
            // Go to current page
            if let page = document.page(at: editService.currentPageIndex) {
                pdfView.go(to: page)
            }
            
            // Log actual PDFView bounds for coordinate debugging
            print("📐 PDFView actual bounds: \(pdfView.bounds)")
            if let documentView = pdfView.documentView {
                print("📐 PDFView documentView bounds: \(documentView.bounds)")
            }
        }
        
        // Update gesture recognizers based on selected tool
        updateGestureRecognizers(for: pdfView, coordinator: context.coordinator)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setupGestureRecognizers(for pdfView: PDFView, coordinator: Coordinator) {
        // Add tap gesture for tool interactions
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        pdfView.addGestureRecognizer(tapGesture)
        
        // Store reference for updates
        coordinator.tapGesture = tapGesture
    }
    
    private func setupNotifications(for pdfView: PDFView, coordinator: Coordinator) {
        // Text selection changed notification for highlights
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(coordinator.handleSelectionChanged(notification:)),
            name: .PDFViewSelectionChanged,
            object: pdfView
        )
        
        // Annotation hit notification
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(coordinator.handleAnnotationHit(notification:)),
            name: .PDFViewAnnotationHit,
            object: pdfView
        )
    }
    
    private func updateGestureRecognizers(for pdfView: PDFView, coordinator: Coordinator) {
        guard let tapGesture = coordinator.tapGesture else { return }
        
        // Enable/disable based on selected tool
        switch editService.selectedTool {
        case .highlight:
            // For highlights, we rely on text selection, not tap
            tapGesture.isEnabled = false
        case .addImage, .signature:
            tapGesture.isEnabled = true
        default:
            tapGesture.isEnabled = false
        }
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        let parent: PDFEditorView_Internal
        var tapGesture: UITapGestureRecognizer?
        
        init(_ parent: PDFEditorView_Internal) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let pdfView = gesture.view as? PDFView else { return }
            
            let point = gesture.location(in: pdfView)
            
            // Get geometry size for coordinate conversion
            let geometrySize = pdfView.bounds.size
            
            // Handle tap based on selected tool
            switch parent.editService.selectedTool {
            case .addImage:
                if parent.editService.showingImageInsertMode {
                    parent.editService.insertionPoint = point
                    parent.editService.showingImagePicker = true
                }
                
            case .signature:
                if parent.editService.showingSignatureInsertMode {
                    // Handle signature insertion
                    print("📍 Signature tap at: \(point)")
                }
                
            default:
                break
            }
        }
        
        @objc func handleSelectionChanged(notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page = pdfView.currentPage,
                  let selection = pdfView.currentSelection,
                  let selectedText = selection.string else { return }
            
            // Handle text selection for highlights
            if parent.editService.selectedTool == .highlight {
                let bounds = selection.bounds(for: page)
                let geometrySize = pdfView.bounds.size
                
                parent.editService.handleTextSelection(
                    selectedText: selectedText,
                    bounds: bounds,
                    geometrySize: geometrySize
                )
                
                // Clear selection after processing
                pdfView.clearSelection()
            }
        }
        
        @objc func handleAnnotationHit(notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let annotation = userInfo["PDFAnnotationHit"] as? PDFAnnotation else { return }
            
            print("📝 Annotation tapped: \(type(of: annotation))")
        }
        
        // MARK: - PDFViewDelegate
        
        func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
            // Handle link clicks if needed
        }
        
        func pdfViewParentViewController(for sender: PDFView) -> UIViewController? {
            return nil
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: .PDFViewSelectionChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .PDFViewAnnotationHit, object: nil)
        }
    }
}
