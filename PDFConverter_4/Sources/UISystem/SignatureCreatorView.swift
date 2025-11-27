import SwiftUI

struct SignatureCreatorView: View {
    
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @StateObject private var signatureService = SignatureService()
    @StateObject private var signatureStorage = SignatureStorage()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingNameAlert = false
    @State private var signatureName = ""
    @State private var selectedTab = 0
    @State private var saveAndUseMode = false  // true for "Save & Use", false for "Save only"
    @State private var showingSavedAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Mode", selection: $selectedTab) {
                    Text("Draw").tag(0)
                    Text("Saved").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    drawingTabContent
                } else {
                    savedSignaturesTabContent
                }
                
                Spacer()
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.appGray)
                }
                
                if selectedTab == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Use Signature") {
                                useCurrentSignature()
                            }
                            .disabled(!signatureService.hasSignature)
                            
                            Button("Save & Use") {
                                saveAndUseMode = true
                                showingNameAlert = true
                            }
                            .disabled(!signatureService.hasSignature)
                            
                            Button("Clear") {
                                signatureService.clearSignature()
                            }
                            .disabled(!signatureService.hasSignature)
                            
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.appRed)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Save Signature", isPresented: $showingNameAlert) {
            TextField("Signature name", text: $signatureName)
            
            Button("Save") {
                saveSignature()
            }
            .disabled(signatureName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Button("Cancel", role: .cancel) {
                signatureName = ""
                saveAndUseMode = false
            }
        } message: {
            Text("Enter a name for your signature")
        }
        .alert("Signature Saved", isPresented: $showingSavedAlert) {
            Button("OK") {
                showingSavedAlert = false
            }
        } message: {
            Text("Your signature has been saved successfully!")
        }
    }
    
    // MARK: - Drawing Tab
    
    private var drawingTabContent: some View {
        VStack(spacing: 16) {
            // Color picker
            colorPickerView
            
            // Drawing canvas
            drawingCanvasView
            
            // Instructions
            instructionsView
        }
        .padding()
    }
    
    private var colorPickerView: some View {
        VStack(spacing: 8) {
            Text("Signature Color")
                .font(.semiBold(16))
                .foregroundColor(.appBlack)
            
            HStack(spacing: 12) {
                ForEach(signatureService.availableColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .opacity(signatureService.selectedColor == color ? 1 : 0)
                        )
                        .overlay(
                            Circle()
                                .stroke(.appGray, lineWidth: 1)
                        )
                        .onTapGesture {
                            signatureService.updateColor(color)
                        }
                }
            }
        }
    }
    
    private var drawingCanvasView: some View {
        VStack(spacing: 12) {
            Text("Draw Your Signature")
                .font(.semiBold(16))
                .foregroundColor(.appBlack)
            
            GeometryReader { geometry in
                ZStack {
                    // Canvas background
                    Rectangle()
                        .fill(.white)
                        .overlay(
                            Rectangle()
                                .stroke(.appGray.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Signature path
                    Path { path in
                        let swiftUIPath = signatureService.drawingPath.swiftUIPath
                        path.addPath(swiftUIPath)
                    }
                    .stroke(
                        signatureService.selectedColor,
                        style: StrokeStyle(
                            lineWidth: signatureService.lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    
                    // Touch handling overlay
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let canvasRect = CGRect(
                                        x: 0, 
                                        y: 0, 
                                        width: geometry.size.width, 
                                        height: geometry.size.height
                                    )
                                    
                                    if !signatureService.isDrawing {
                                        signatureService.startDrawing(at: value.location, in: canvasRect)
                                    } else {
                                        signatureService.continueDrawing(to: value.location, in: canvasRect)
                                    }
                                }
                                .onEnded { _ in
                                    signatureService.endDrawing()
                                }
                        )
                }
                .clipShape(Rectangle())
            }
            .frame(height: signatureService.maxHeight)
            .shadow(color: .black.opacity(0.1), radius: 5)
        }
    }
    
    private var instructionsView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "hand.draw")
                    .foregroundColor(.appGray)
                Text("Draw your signature in the box above")
                    .font(.regular(14))
                    .foregroundColor(.appGray)
            }
            
            if signatureService.hasSignature {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Signature ready! Tap the menu to use or save it.")
                        .font(.regular(14))
                        .foregroundColor(.appBlack)
                }
            }
        }
    }
    
    // MARK: - Saved Signatures Tab
    
    private var savedSignaturesTabContent: some View {
        VStack(spacing: 16) {
            if signatureStorage.savedSignatures.isEmpty {
                emptySavedSignaturesView
            } else {
                savedSignaturesListView
            }
        }
        .padding()
    }
    
    private var emptySavedSignaturesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "signature")
                .font(.system(size: 48))
                .foregroundColor(.appGray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Saved Signatures")
                    .font(.semiBold(18))
                    .foregroundColor(.appBlack)
                
                Text("Draw a signature and save it to see it here")
                    .font(.regular(14))
                    .foregroundColor(.appGray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var savedSignaturesListView: some View {
        VStack(spacing: 16) {
            Text("Select a Saved Signature")
                .font(.semiBold(16))
                .foregroundColor(.appBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(signatureStorage.savedSignatures) { signature in
                        SavedSignatureRowView(
                            signature: signature,
                            onUse: { useSignature(signature) },
                            onDelete: { deleteSignature(signature) }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Actions
    
    private func useCurrentSignature() {
        guard let image = signatureService.generateSignatureImage() else { return }
        onSave(image)
    }
    
    private func useSignature(_ signature: SavedSignature) {
        guard let image = signatureStorage.loadSignatureImage(signature) else { return }
        onSave(image)
    }
    
    private func saveSignature() {
        guard let image = signatureService.generateSignatureImage() else { return }
        
        let name = signatureName.trimmingCharacters(in: .whitespacesAndNewlines)
        let colorHex = signatureService.selectedColor.hexString
        
        if let savedSignature = signatureStorage.saveSignature(image, name: name, color: colorHex) {
            signatureName = ""
            
            if saveAndUseMode {
                onSave(image)
                saveAndUseMode = false
            } else {
                showingSavedAlert = true
                // Switch to saved tab to show the new signature
                selectedTab = 1
            }
        }
    }
    
    private func deleteSignature(_ signature: SavedSignature) {
        signatureStorage.deleteSignature(signature)
    }
}

// MARK: - Saved Signature Row View

struct SavedSignatureRowView: View {
    let signature: SavedSignature
    let onUse: () -> Void
    let onDelete: () -> Void
    
    @StateObject private var signatureStorage = SignatureStorage()
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Signature preview
            Group {
                if let image = signatureStorage.loadSignatureImage(signature) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(.appGray.opacity(0.3))
                        .overlay(
                            Text("Preview\nUnavailable")
                                .font(.caption)
                                .foregroundColor(.appGray)
                                .multilineTextAlignment(.center)
                        )
                }
            }
            .frame(width: 80, height: 40)
            .background(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.appGray.opacity(0.3), lineWidth: 1)
            )
            
            // Signature info
            VStack(alignment: .leading, spacing: 4) {
                Text(signature.name)
                    .font(.semiBold(14))
                    .foregroundColor(.appBlack)
                    .lineLimit(1)
                
                Text(signature.createdDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.regular(12))
                    .foregroundColor(.appGray)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button("Use") {
                    onUse()
                }
                .font(.semiBold(14))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.appRed)
                .cornerRadius(8)
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.appGray)
                }
            }
        }
        .padding(12)
        .background(.appWhite)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.appStroke, lineWidth: 1)
        )
        .alert("Delete Signature", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(signature.name)'? This action cannot be undone.")
        }
    }
}

#Preview {
    SignatureCreatorView(
        onSave: { _ in },
        onCancel: { }
    )
}
