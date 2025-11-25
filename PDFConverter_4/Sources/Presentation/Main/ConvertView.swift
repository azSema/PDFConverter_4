import SwiftUI

struct ConvertView: View {
    
    @State private var selectedOption: ConvertOption = .textToPDF
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Toolbar
            CustomToolbar(
                title: "LiteConvert",
                showProButton: true
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color(hex: "8E8E93"))
                                .font(.system(size: 16))
                            
                            TextField("Search", text: $searchText)
                                .font(.regular(16))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(hex: "F2F2F7"))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    
                    // Custom Horizontal Picker
                    CustomHorizontalPicker(selectedOption: $selectedOption)
                        .padding(.horizontal, 16)
                    
                    // Conversion Options
                    VStack(spacing: 16) {
                        ConvertOptionCard(
                            title: "Text To PDF",
                            description: "Convert text files to PDF format",
                            iconName: "doc.text",
                            color: Color(hex: "FF6B6B")
                        ) {
                            // Handle Text to PDF
                        }
                        
                        ConvertOptionCard(
                            title: "Image to PDF",
                            description: "Convert images to PDF format",
                            iconName: "photo",
                            color: Color(hex: "4ECDC4")
                        ) {
                            // Handle Image to PDF
                        }
                        
                        ConvertOptionCard(
                            title: "PDF To Image",
                            description: "Convert PDF pages to images",
                            iconName: "doc.badge.gearshape",
                            color: Color(hex: "45B7D1")
                        ) {
                            // Handle PDF to Image
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .background(Color(hex: "FFFFFF"))
    }
}

enum ConvertOption: String, CaseIterable {
    case textToPDF = "Text to PDF"
    case imageToPDF = "Image to PDF"
    case pdfToImage = "PDF to Image"
    
    var title: String {
        return self.rawValue
    }
}

struct CustomHorizontalPicker: View {
    @Binding var selectedOption: ConvertOption
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ConvertOption.allCases, id: \.self) { option in
                Button {
                    selectedOption = option
                } label: {
                    Text(option.title)
                        .font(.medium(14))
                        .foregroundColor(selectedOption == option ? .white : Color(hex: "8E8E93"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedOption == option ? Color(hex: "007AFF") : Color.clear
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "E5E5E7"), lineWidth: 1)
                                .opacity(selectedOption == option ? 0 : 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct ConvertOptionCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "C7C7CC"))
                    }
                    
                    Text(title)
                        .font(.semiBold(18))
                        .foregroundColor(Color(hex: "000000"))
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.regular(14))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(hex: "F8F9FA"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ConvertView()
}