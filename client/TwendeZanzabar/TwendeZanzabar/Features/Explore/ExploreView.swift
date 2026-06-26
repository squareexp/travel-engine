import SwiftUI

struct ExploreView: View {
    @State private var query = ""
    @State private var typeFilter: String?
    @State private var results: [Listing] = []
    @State private var loading = false
    @State private var searchTask: Task<Void, Never>?

    private let filters: [(String, String?, String)] = [
        ("All", nil, "square.grid.2x2"), ("Sites", "site", "building.columns"),
        ("Experiences", "experience", "sparkles"), ("Trips", "trip", "map"),
        ("Safari", "safari", "leaf")
    ]

    var body: some View {
        Group {
            if loading && results.isEmpty {
                ProgressView("Finding experiences…").tint(TwendeColor.accent)
            } else if results.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a place, activity or travel style.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: TwendeSpacing.md), GridItem(.flexible(), spacing: TwendeSpacing.md)], spacing: TwendeSpacing.lg) {
                        ForEach(results) { listing in
                            NavigationLink(value: listing) { ListingCard(listing: listing) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(TwendeSpacing.xl)
                }
            }
        }
        .background(TwendeColor.background)
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Zanzibar and Tanzania")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Filters", systemImage: "line.3.horizontal.decrease.circle") {
                    ForEach(filters, id: \.0) { filter in
                        Button { typeFilter = filter.1 } label: {
                            Label(filter.0, systemImage: filter.2)
                        }
                    }
                }
                .accessibilityLabel("Filter results")
            }
        }
        .safeAreaInset(edge: .top) { filterRow }
        .task { await runSearch() }
        .onChange(of: query) { _, _ in scheduleSearch() }
        .onChange(of: typeFilter) { _, _ in scheduleSearch() }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TwendeSpacing.sm) {
                ForEach(filters, id: \.0) { filter in
                    let selected = typeFilter == filter.1
                    Button {
                        typeFilter = filter.1
                    } label: {
                        Label(filter.0, systemImage: filter.2)
                            .font(TwendeTypography.label.weight(.semibold))
                            .foregroundStyle(selected ? .white : TwendeColor.textPrimary)
                            .padding(.horizontal, TwendeSpacing.md)
                            .padding(.vertical, 9)
                            .background(selected ? TwendeColor.primary : TwendeColor.surfaceMuted, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, TwendeSpacing.xl)
            .padding(.vertical, TwendeSpacing.sm)
        }
        .background(TwendeColor.background.opacity(0.96))
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await runSearch()
        }
    }

    private func runSearch() async {
        loading = true
        defer { loading = false }
        results = (try? await CatalogRepository.shared.search(type: typeFilter, text: query.isEmpty ? nil : query)) ?? []
    }
}
