import SwiftUI

struct FavoritesView: View {
    @ObservedObject private var favorites = FavoritesStore.shared
    @State private var listings: [Listing] = []
    @State private var loading = true

    var liked: [Listing] { listings.filter { favorites.contains($0.id) } }

    var body: some View {
        VStack(alignment: .leading, spacing: TwendeSpacing.md) {
            Text("Saved for later").font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("\(liked.count) saved listings")
                .font(TwendeTypography.body)
                .foregroundStyle(TwendeColor.textSecondary)

            if loading && listings.isEmpty {
                Spacer()
                ProgressView().tint(TwendeColor.primary)
                Spacer()
            } else if liked.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.system(size: 36))
                        .foregroundStyle(TwendeColor.textTertiary)
                    Text("Nothing saved yet").font(TwendeTypography.h3)
                    Text("Tap the heart on any listing to save it here.")
                        .font(TwendeTypography.body)
                        .foregroundStyle(TwendeColor.textSecondary)
                        .multilineTextAlignment(.center)
                    Text("Explore experiences and save the ones that feel like you.")
                        .font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.accent)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: TwendeSpacing.lg),
                        GridItem(.flexible(), spacing: TwendeSpacing.lg),
                    ], spacing: TwendeSpacing.lg) {
                        ForEach(liked) { l in
                            NavigationLink(value: l) {
                                ListingCard(listing: l)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(TwendeSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TwendeColor.background)
        .task { await load() }
    }

    private func load() async {
        loading = true
        listings = (try? await CatalogRepository.shared.featuredListings()) ?? []
        loading = false
    }
}
