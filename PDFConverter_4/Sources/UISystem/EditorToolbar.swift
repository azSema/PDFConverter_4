import SwiftUI

struct EditorToolbar: View {
    @ObservedObject var editService: PDFEditService
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(EditorTool.allCases, id: \.self) { tool in
                HStack(spacing: 20) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if editService.selectedTool == tool {
                                editService.deselectTool()
                            } else {
                                editService.selectTool(tool)
                            }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.systemImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(editService.selectedTool == tool ? .appRed : .appStroke)
                            
                            Text(tool.title)
                                .font(.regular(10))
                                .foregroundColor(editService.selectedTool == tool ? .appRed : .appStroke)
                        }
                    }
                    
                    if tool != EditorTool.allCases.last {
                        Rectangle()
                            .fill(.appStroke)
                            .frame(width: 1, height: 32)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color.appWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

#Preview {
    EditorToolbar(editService: PDFEditService())
        .padding()
        .background(.gray.opacity(0.2))
}