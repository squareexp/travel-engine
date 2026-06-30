import SwiftUI

struct BrandHeader: View {
    var subtitle: String?
    var color: Color = TwendeColor.textPrimary
    var fontSize: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Twende Zanzibar")
                .font(.system(size: fontSize, weight: .bold, design: .serif))
                .foregroundStyle(color)
                .kerning(-0.3)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(color.opacity(0.7))
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        BrandHeader()
        BrandHeader(subtitle: "One App. Zanzibar & Tanzania.")
        BrandHeader(subtitle: "One App. Zanzibar & Tanzania.", color: .white, fontSize: 34)
            .padding()
            .background(Color(red: 0.043, green: 0.231, blue: 0.325))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .padding()
}
