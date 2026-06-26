import SwiftUI

struct ListingCard: View {
    let listing: Listing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(url: listing.heroImageURL)
                .frame(height: 130)
                .clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(TwendeTypography.title)
                    .foregroundStyle(TwendeColor.textPrimary)
                    .lineLimit(1)
                if let dest = listing.destination_name {
                    Text(dest)
                        .font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.textTertiary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Text(listing.formattedPrice)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TwendeColor.primary)
                    Text("/ person")
                        .font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.textTertiary)
                    Spacer()
                    if let rating = listing.rating {
                        Image(systemName: "star.fill")
                            .foregroundStyle(TwendeColor.star)
                            .font(.system(size: 11))
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TwendeColor.textPrimary)
                    }
                }
                .padding(.top, 2)
            }
            .padding(TwendeSpacing.md)
        }
        .background(TwendeColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusLg, style: .continuous))
    }
}

extension Listing {
    /// Pick a fallback Unsplash photo based on listing_type when the API doesn't return media.
    var heroImageURL: String {
        switch listing_type {
        case "safari": return "https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=800"
        case "trip":   return "https://images.unsplash.com/photo-1591608971362-f08b2a75731a?w=800"
        case "site":   return "https://images.unsplash.com/photo-1580973193083-c2b8a37d6a6a?w=800"
        default:       return "https://images.unsplash.com/photo-1571401835393-8c5f35328320?w=800"
        }
    }
}
