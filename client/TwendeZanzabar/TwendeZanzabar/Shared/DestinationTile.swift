import SwiftUI

struct DestinationTile: View {
    let destination: Destination

    var body: some View {
        ZStack(alignment: .bottom) {
            RemoteImage(url: destination.image_urls?.first
                ?? "https://images.unsplash.com/photo-1568126879226-7e937ae84927?w=600")
                .frame(width: 180, height: 130)
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .font(TwendeTypography.title)
                    .foregroundStyle(TwendeColor.textPrimary)
                    .lineLimit(1)
                Text(destination.region ?? destination.country)
                    .font(TwendeTypography.caption)
                    .foregroundStyle(TwendeColor.textTertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, TwendeSpacing.md)
            .padding(.vertical, TwendeSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TwendeColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
            .padding(TwendeSpacing.sm)
        }
        .frame(width: 180, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusLg, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 12) {
        DestinationTile(destination: .preview)
        DestinationTile(destination: .previewStone)
    }
    .padding()
    .background(Color(red: 0.988, green: 0.980, blue: 0.961))
}
