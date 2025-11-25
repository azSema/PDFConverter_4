import SwiftUI

struct DocumentRowView: View {
    let document: DocumentDTO
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                
                // Document thumbnail with type indicator
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: document.thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 80)
                        .clipped()
                        .background(Color.appGray.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Use FileType icon instead of text badge
                    document.type.icon
                        .offset(x: -4, y: -4)
                }
                
                // Document info
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.name)
                        .font(.semibold(16))
                        .foregroundColor(.appBlack)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.appGray)
                            
                            Text(document.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.regular(12))
                                .foregroundColor(.appGray)
                        }
                        
                        HStack(spacing: 4) {
                            Text(document.type.name.uppercased())
                                .font(.semibold(10))
                                .foregroundColor(typeColor)
                        }
                        
                        if document.isFavorite {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appRed)
                                
                                Text("Favorite")
                                    .font(.regular(12))
                                    .foregroundColor(.appRed)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Action indicator (subtle)
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appGray.opacity(0.6))
            }
            .padding(16)
            .background(.appWhite)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.appStroke, lineWidth: 1)
            )
            .shadow(color: .appBlack.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var typeColor: Color {
        switch document.type {
        case .pdf:
            return .appRed
        case .image:
            return .appOrange
        case .text:
            return .appBlue
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DocumentRowView(
            document: DocumentDTO(
                id: "1",
                name: "Contract Agreement",
                type: .pdf,
                date: Date(),
                isFavorite: false
            ),
            onTap: {}
        )
        
        DocumentRowView(
            document: DocumentDTO(
                id: "2",
                name: "Important Image",
                type: .image,
                date: Date().addingTimeInterval(-86400),
                isFavorite: true
            ),
            onTap: {}
        )
        
        DocumentRowView(
            document: DocumentDTO(
                id: "3",
                name: "Text Document",
                type: .text,
                date: Date().addingTimeInterval(-172800),
                isFavorite: false
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Color.appWhite)
}