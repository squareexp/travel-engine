import SwiftUI

struct ListingDetailView: View {
    let listingId: String
    @State private var listing: Listing?
    @State private var loading = true
    @ObservedObject private var favorites = FavoritesStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if let l = listing {
                    content(for: l)
                } else if loading {
                    ProgressView().padding(.top, 60).tint(TwendeColor.primary)
                } else {
                    Text("Couldn't load listing").padding(.top, 60)
                }
            }
            .scrollIndicators(.hidden)
            .background(TwendeColor.background)
            .scrollEdgeEffectStyle(.soft, for: .top)
            if let l = listing { bookBar(for: l) }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
    }

    @ViewBuilder
    private func content(for listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: TwendeSpacing.lg) {
            ZStack(alignment: .topLeading) {
                RemoteImage(url: listing.heroImageURL)
                    .frame(height: 320)
                    .clipped()

                HStack {
                    iconButton(systemName: "chevron.left") { dismiss() }
                    Spacer()
                    iconButton(
                        systemName: favorites.contains(listing.id)
                            ? "heart.fill" : "heart"
                    ) {
                        favorites.toggle(listing.id)
                    }
                }
                .padding(.horizontal, TwendeSpacing.lg)
                .padding(.top, 56)
            }

            VStack(alignment: .leading, spacing: TwendeSpacing.md) {
                Text(listing.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(TwendeColor.textPrimary)

                if let dest = listing.destination_name {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(TwendeColor.textTertiary)
                            .font(.system(size: 13))
                        Text(dest).font(TwendeTypography.body).foregroundStyle(TwendeColor.textSecondary)
                    }
                }

                if let rating = listing.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(TwendeColor.star)
                            .font(.system(size: 13))
                        Text(String(format: "%.1f", rating))
                            .font(TwendeTypography.title)
                            .foregroundStyle(TwendeColor.textPrimary)
                        if let count = listing.review_count {
                            Text("(\(count) reviews)")
                                .font(TwendeTypography.body)
                                .foregroundStyle(TwendeColor.textSecondary)
                        }
                    }
                }

                infoChips(for: listing)

                if let desc = listing.description {
                    Text("About this experience")
                        .font(TwendeTypography.h3)
                        .padding(.top, TwendeSpacing.sm)
                    Text(desc)
                        .font(TwendeTypography.bodyLarge)
                        .foregroundStyle(TwendeColor.textSecondary)
                        .padding(.top, TwendeSpacing.sm)
                }

                if let incs = listing.inclusions, !incs.isEmpty {
                    Text("Inclusions")
                        .font(TwendeTypography.h3)
                        .padding(.top, TwendeSpacing.md)
                    ForEach(incs, id: \.self) { item in
                        HStack(spacing: TwendeSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(TwendeColor.success)
                            Text(item).font(.system(size: 15))
                                .foregroundStyle(TwendeColor.textPrimary)
                        }
                    }
                }
                Spacer(minLength: 100)
            }
            .padding(.horizontal, TwendeSpacing.xl)
        }
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GlassAction {
                Image(systemName: systemName)
                    .foregroundStyle(TwendeColor.textPrimary)
                    .frame(width: 20, height: 20)
            }
        }
        .accessibilityLabel(systemName == "heart" || systemName == "heart.fill" ? "Save experience" : "Go back")
    }

    private func infoChips(for listing: Listing) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TwendeSpacing.sm) {
            chip(icon: "clock", label: "Duration",
                 value: listing.duration_hours.map { "\($0) hours" } ?? "Flexible")
            chip(icon: "person.2", label: "Group",
                 value: listing.capacity.map { "Up to \($0)" } ?? "—")
            chip(icon: "dollarsign.circle", label: "Price",
                 value: "From \(listing.formattedPrice)")
            }
        }
    }

    private func chip(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(TwendeColor.primary)
                .font(.system(size: 16, weight: .semibold))
            Text(label)
                .font(TwendeTypography.caption)
                .foregroundStyle(TwendeColor.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(TwendeColor.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(TwendeSpacing.md)
        .background(TwendeColor.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
    }

    private func bookBar(for listing: Listing) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("From").font(TwendeTypography.caption)
                    .foregroundStyle(TwendeColor.textTertiary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(listing.formattedPrice)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(TwendeColor.textPrimary)
                    Text("/ person")
                        .font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.textTertiary)
                }
            }
            Spacer()
            NavigationLink(value: BookListing(listing: listing)) {
                Text("Book Now")
                    .font(TwendeTypography.button)
                    .foregroundStyle(TwendeColor.textInverse)
                    .padding(.horizontal, TwendeSpacing.xxl)
                    .padding(.vertical, TwendeSpacing.md)
                    .background(TwendeColor.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, TwendeSpacing.xl)
        .padding(.vertical, TwendeSpacing.md)
        .background(.regularMaterial)
        .overlay(Divider(), alignment: .top)
    }

    private func load() async {
        loading = true
        do { self.listing = try await CatalogRepository.shared.listing(id: listingId) }
        catch { print("Listing load failed: \(error)") }
        loading = false
    }
}
