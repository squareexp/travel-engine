import SwiftUI

struct BookingsView: View {
    @State private var bookings: [Booking] = []
    @State private var loading = true
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Trip content", selection: $tab) {
                Text("Itinerary").tag(0)
                Text("Bookings").tag(1)
                Text("Saved").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, TwendeSpacing.xl)
            .padding(.top, TwendeSpacing.sm)

            if loading {
                Spacer()
                ProgressView("Loading your trip…").tint(TwendeColor.accent)
                Spacer()
            } else {
                TabView(selection: $tab) {
                    itinerary.tag(0)
                    bookingList.tag(1)
                    savedState.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background(TwendeColor.background)
        .navigationTitle("My trip")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Share", systemImage: "square.and.arrow.up") { }
                    .accessibilityLabel("Share trip")
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var itinerary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TwendeSpacing.lg) {
                if let next = bookings.sorted(by: { $0.travel_date ?? "" < $1.travel_date ?? "" }).first {
                    AppSurface(emphasis: true) {
                        VStack(alignment: .leading, spacing: TwendeSpacing.sm) {
                            Label("UP NEXT", systemImage: "calendar.badge.clock")
                                .font(TwendeTypography.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.76))
                            Text(next.listing_title ?? "Your Zanzibar itinerary")
                                .font(TwendeTypography.h2)
                                .foregroundStyle(.white)
                            Text("\(next.travel_date ?? "Date to be confirmed") · \(next.guests) guest\(next.guests == 1 ? "" : "s")")
                                .font(TwendeTypography.body)
                                .foregroundStyle(.white.opacity(0.86))
                        }
                    }
                } else {
                    AppSurface(emphasis: true) {
                        VStack(alignment: .leading, spacing: TwendeSpacing.sm) {
                            Label("READY WHEN YOU ARE", systemImage: "map.fill")
                                .font(TwendeTypography.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.76))
                            Text("Build a trip worth remembering")
                                .font(TwendeTypography.h2)
                                .foregroundStyle(.white)
                            Text("Save experiences and we’ll keep the plan in one calm place.")
                                .font(TwendeTypography.body)
                                .foregroundStyle(.white.opacity(0.86))
                        }
                    }
                }

                Text("Your schedule").font(TwendeTypography.h2)
                if bookings.isEmpty {
                    ContentUnavailableView("Nothing scheduled yet", systemImage: "calendar.badge.plus", description: Text("Book an experience and it will appear in your itinerary."))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TwendeSpacing.xxl)
                } else {
                    ForEach(Array(bookings.enumerated()), id: \.element.id) { index, booking in
                        itineraryRow(booking, isLast: index == bookings.count - 1)
                    }
                }
            }
            .padding(TwendeSpacing.xl)
        }
    }

    private var bookingList: some View {
        Group {
            if bookings.isEmpty {
                ContentUnavailableView("No bookings yet", systemImage: "ticket", description: Text("Your confirmed experiences will live here."))
            } else {
                List(bookings) { BookingTile(booking: $0) }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    private var savedState: some View {
        ContentUnavailableView("Saved experiences", systemImage: "heart", description: Text("Use the heart on an experience to keep it handy for later."))
    }

    private func itineraryRow(_ booking: Booking, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: TwendeSpacing.md) {
            VStack(spacing: 0) {
                Circle().fill(TwendeColor.accent).frame(width: 12, height: 12)
                if !isLast { Rectangle().fill(TwendeColor.border).frame(width: 2, height: 72) }
            }
            AppSurface(padding: TwendeSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.travel_date ?? "Choose date")
                        .font(TwendeTypography.caption.weight(.semibold))
                        .foregroundStyle(TwendeColor.accent)
                    Text(booking.listing_title ?? "Experience")
                        .font(TwendeTypography.title)
                    Text("(booking.guests) guest\(booking.guests == 1 ? "" : "s") · (booking.status.capitalized)")
                        .font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func reload() async {
        loading = true
        bookings = (try? await BookingsRepository.shared.myBookings()) ?? []
        loading = false
    }
}

struct BookingTile: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: TwendeSpacing.md) {
            Image(systemName: "calendar")
                .foregroundStyle(TwendeColor.accent)
                .frame(width: 44, height: 44)
                .background(TwendeColor.surfaceMuted, in: RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.listing_title ?? "Booking").font(TwendeTypography.title).lineLimit(1)
                Text("\(booking.travel_date ?? "Date pending") · \(booking.guests) guest\(booking.guests == 1 ? "" : "s")")
                    .font(TwendeTypography.caption).foregroundStyle(TwendeColor.textSecondary)
            }
            Spacer()
            Text(booking.status.capitalized)
                .font(TwendeTypography.caption.weight(.bold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(statusColor.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, TwendeSpacing.sm)
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        switch booking.status {
        case "confirmed", "completed": return TwendeColor.success
        case "cancelled": return TwendeColor.danger
        default: return TwendeColor.warning
        }
    }
}
