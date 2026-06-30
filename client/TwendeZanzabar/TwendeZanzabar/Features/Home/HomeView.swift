import SwiftUI

struct HomeView: View {
    @State private var destinations: [Destination] = []
    @State private var listings: [Listing] = []
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TwendeSpacing.xxl) {
                welcome
                categoryRow
                hero
                sectionHeader("Start with a place", action: "See all")
                destinationRow
                sectionHeader("Hand-picked for you", action: "Explore")
                listingsGrid
            }
            .padding(.horizontal, TwendeSpacing.xl)
            .padding(.bottom, TwendeSpacing.xxxl)
        }
        .background(TwendeColor.background)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if #available(iOS 27, *) {
                ToolbarItem(placement: .topBarPinnedTrailing) {
                    Button("Alerts", systemImage: "bell") { }
                        .accessibilityLabel("Travel alerts")
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Alerts", systemImage: "bell") { }
                        .accessibilityLabel("Travel alerts")
                }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
        .minimizeNavBarOnScroll()
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: TwendeSpacing.sm) {
            Text("Good to have you here")
                .font(TwendeTypography.caption)
                .foregroundStyle(TwendeColor.accent)
                .textCase(.uppercase)
            Text("Where will Tanzania take you?")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(TwendeColor.textPrimary)
            Text("Plan a beach day, safari or city escape without losing the details.")
                .font(TwendeTypography.bodyLarge)
                .foregroundStyle(TwendeColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var categoryRow: some View {
        let items: [(String, String)] = [("Beaches", "sun.max.fill"), ("Safari", "leaf.fill"), ("Stone Town", "building.columns.fill"), ("Hotels", "bed.double.fill"), ("Transfers", "car.fill")]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TwendeSpacing.sm) {
                ForEach(items, id: \.0) { item in
                    Label(item.0, systemImage: item.1)
                        .font(TwendeTypography.label.weight(.semibold))
                        .foregroundStyle(TwendeColor.textPrimary)
                        .padding(.horizontal, TwendeSpacing.md)
                        .padding(.vertical, 10)
                        .background(TwendeColor.surfaceMuted, in: Capsule())
                }
            }
        }
        .accessibilityLabel("Travel categories")
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: "https://images.unsplash.com/photo-1571401835393-8c5f35328320?w=1200")
                .frame(height: 280)
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, TwendeColor.primary.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                }
            VStack(alignment: .leading, spacing: TwendeSpacing.sm) {
                Text("This season")
                    .font(TwendeTypography.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
                Text("Zanzibar, at your pace")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text("Thoughtful stays, sea days and local stories.")
                    .font(TwendeTypography.body)
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(TwendeSpacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusXl, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("This season: Zanzibar, at your pace")
    }

    private func sectionHeader(_ title: String, action: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(TwendeTypography.h2)
            Spacer()
            Button(action) { }
                .font(TwendeTypography.label.weight(.semibold))
                .foregroundStyle(TwendeColor.accent)
        }
    }

    private var destinationRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TwendeSpacing.md) {
                if loading {
                    ForEach(0..<3, id: \.self) { _ in placeholder(width: 220, height: 150) }
                } else if destinations.isEmpty {
                    ContentUnavailableView("No destinations yet", systemImage: "map")
                } else {
                    ForEach(destinations) { destination in
                        DestinationTile(destination: destination)
                    }
                }
            }
        }
    }

    private var listingsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: TwendeSpacing.md), GridItem(.flexible(), spacing: TwendeSpacing.md)], spacing: TwendeSpacing.lg) {
            if loading {
                ForEach(0..<4, id: \.self) { _ in placeholder(width: nil, height: 240) }
            } else if listings.isEmpty {
                ContentUnavailableView("No experiences yet", systemImage: "sparkles")
                    .gridCellColumns(2)
            } else {
                ForEach(listings) { listing in
                    NavigationLink(value: listing) { ListingCard(listing: listing) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func placeholder(width: CGFloat?, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: TwendeSpacing.radiusLg, style: .continuous)
            .fill(TwendeColor.surfaceMuted)
            .frame(width: width, height: height)
            .redacted(reason: .placeholder)
    }

    private func reload() async {
        loading = true
        async let fetchedDestinations = (try? await CatalogRepository.shared.destinations()) ?? []
        async let fetchedListings = (try? await CatalogRepository.shared.featuredListings()) ?? []
        destinations = await fetchedDestinations
        listings = await fetchedListings
        loading = false
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
