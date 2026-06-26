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
