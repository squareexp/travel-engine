import SwiftUI

struct CategoryChip: View {
    let label: String
    let systemImage: String
    var selected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(selected ? TwendeColor.textInverse : TwendeColor.textPrimary)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? TwendeColor.textInverse : TwendeColor.textPrimary)
        }
        .padding(.horizontal, TwendeSpacing.md)
        .padding(.vertical, TwendeSpacing.sm)
        .frame(minWidth: 76)
        .background(selected ? TwendeColor.primary : TwendeColor.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 8) {
        CategoryChip(label: "Beaches", systemImage: "sun.max.fill", selected: true)
        CategoryChip(label: "Safari", systemImage: "leaf.fill")
        CategoryChip(label: "Hotels", systemImage: "bed.double.fill")
    }
    .padding()
}
