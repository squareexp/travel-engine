import SwiftUI

struct RootShell: View {
    @State private var selected: Tab = .home

    enum Tab: Hashable { case home, explore, bookings, transport, profile }

    var body: some View {
        TabView(selection: $selected) {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: Listing.self) { listing in
                        ListingDetailView(listingId: listing.id)
                    }
                    .navigationDestination(for: BookListing.self) { wrap in
                        CreateBookingView(listing: wrap.listing)
                    }
            }
            .tabItem {
                Label("Home", systemImage: selected == .home ? "house.fill" : "house")
            }
            .tag(Tab.home)

            NavigationStack {
                ExploreView()
                    .navigationDestination(for: Listing.self) { listing in
                        ListingDetailView(listingId: listing.id)
                    }
                    .navigationDestination(for: BookListing.self) { wrap in
                        CreateBookingView(listing: wrap.listing)
                    }
            }
            .tabItem {
                Label("Explore", systemImage: selected == .explore ? "safari.fill" : "safari")
            }
            .tag(Tab.explore)

            BookingsView()
                .tabItem {
                Label("My trip",
                          systemImage: selected == .bookings ? "map.circle.fill" : "map")
                }
                .tag(Tab.bookings)

            TransportView()
                .tabItem {
                    Label("Transport", systemImage: selected == .transport ? "car.fill" : "car")
                }
                .tag(Tab.transport)

            NavigationStack {
                ProfileView()
                    .navigationDestination(for: ProfileRoute.self) { route in
                        switch route {
                        case .favorites: FavoritesView()
                        }
                    }
            }
            .tabItem {
                Label("Profile", systemImage: selected == .profile ? "person.fill" : "person")
            }
            .tag(Tab.profile)
        }
        .tint(TwendeColor.accent)
    }
}

extension Listing: Hashable {
    public static func == (lhs: Listing, rhs: Listing) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Distinct path wrapper so NavigationStack can differentiate "show details"
/// from "book this listing" using the same Listing value type.
struct BookListing: Hashable {
    let listing: Listing
    static func == (lhs: BookListing, rhs: BookListing) -> Bool { lhs.listing.id == rhs.listing.id }
    func hash(into hasher: inout Hasher) { hasher.combine(listing.id); hasher.combine("book") }
}

enum ProfileRoute: Hashable { case favorites }
