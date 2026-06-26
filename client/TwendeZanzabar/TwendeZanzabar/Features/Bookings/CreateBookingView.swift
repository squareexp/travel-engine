import SwiftUI

struct CreateBookingView: View {
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    @State private var travelDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var guests = 2
    @State private var submitting = false
    @State private var presentedAlert: AppAlert?
    @State private var showDatePicker = false

    var total: Double { listing.price * Double(guests) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TwendeSpacing.xl) {
                summaryCard
                section("Select Travel Date")
                dateRow
                section("Guests")
                guestsRow
                priceSummary
                confirmButton
            }
            .padding(TwendeSpacing.xl)
        }
        .navigationTitle("Review your trip")
        .navigationBarTitleDisplayMode(.inline)
        .background(TwendeColor.background)
        .sheet(item: $presentedAlert) { a in AppAlertSheet(alert: a) }
        .sheet(isPresented: $showDatePicker) {
            VStack {
                Capsule().fill(TwendeColor.border)
                    .frame(width: 36, height: 4).padding(.top, 8)
                DatePicker("Travel date",
                           selection: $travelDate,
                           in: Date()...,
                           displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(TwendeColor.primary)
                .padding(.horizontal, TwendeSpacing.xl)
                Button(action: { showDatePicker = false }) {
                    Text("Done")
                        .font(TwendeTypography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TwendeSpacing.md)
                        .background(TwendeColor.primary)
                        .clipShape(Capsule())
                }
                .padding(TwendeSpacing.xl)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(listing.title).font(TwendeTypography.title)
                .foregroundStyle(TwendeColor.textPrimary)
            if let dest = listing.destination_name {
                Text(dest).font(TwendeTypography.caption)
                    .foregroundStyle(TwendeColor.textTertiary)
            }
            HStack {
                Text(listing.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(TwendeColor.primary)
                Text("/ person").font(TwendeTypography.caption)
                    .foregroundStyle(TwendeColor.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TwendeSpacing.md)
        .twendeCard()
    }

    private func section(_ title: String) -> some View {
        Text(title).font(TwendeTypography.h3)
            .foregroundStyle(TwendeColor.textPrimary)
    }

    private var dateRow: some View {
        Button(action: { showDatePicker = true }) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(TwendeColor.primary)
                Text(travelDate.formatted(date: .complete, time: .omitted))
                    .font(TwendeTypography.title)
                    .foregroundStyle(TwendeColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(TwendeColor.textTertiary)
            }
            .padding(TwendeSpacing.md)
            .background(TwendeColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous).strokeBorder(TwendeColor.borderSubtle))
        }
        .buttonStyle(.plain)
    }

    private var guestsRow: some View {
        HStack {
            Image(systemName: "person.2")
                .foregroundStyle(TwendeColor.primary)
            Text("\(guests) adult\(guests == 1 ? "" : "s")")
                .font(TwendeTypography.title)
                .foregroundStyle(TwendeColor.textPrimary)
            Spacer()
            stepperButton(systemImage: "minus", disabled: guests <= 1) {
                if guests > 1 { guests -= 1 }
            }
            Text("\(guests)").font(TwendeTypography.h3)
                .frame(minWidth: 28)
            stepperButton(systemImage: "plus", disabled: guests >= 20) {
                if guests < 20 { guests += 1 }
            }
        }
        .padding(TwendeSpacing.md)
        .background(TwendeColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous).strokeBorder(TwendeColor.borderSubtle))
    }

    private func stepperButton(systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .foregroundStyle(disabled ? TwendeColor.textTertiary : TwendeColor.textPrimary)
                .frame(width: 32, height: 32)
                .background(disabled ? TwendeColor.surfaceSubtle : TwendeColor.surfaceMuted)
                .clipShape(Circle())
        }
        .disabled(disabled)
    }

    private var priceSummary: some View {
        VStack(spacing: TwendeSpacing.md) {
            HStack {
                Text("\(listing.formattedPrice) × \(guests)")
                    .font(TwendeTypography.body)
                Spacer()
                Text("$\(Int(listing.price * Double(guests)))")
                    .font(TwendeTypography.title)
            }
            Divider()
            HStack {
                Text("Total").font(TwendeTypography.h3)
                Spacer()
                Text("$\(Int(total))").font(TwendeTypography.h2)
            }
            Text("All prices in USD")
                .font(TwendeTypography.caption)
                .foregroundStyle(TwendeColor.textTertiary)
        }
        .padding(TwendeSpacing.lg)
        .twendeCard()
    }

    private var confirmButton: some View {
        Button(action: submit) {
            HStack {
                if submitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Confirm Booking")
                        .font(TwendeTypography.button)
                    Image(systemName: "arrow.right")
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, TwendeSpacing.md)
            .background(TwendeColor.primary)
            .clipShape(Capsule())
        }
        .disabled(submitting)
    }

    private func submit() {
        submitting = true
        Task {
            defer { submitting = false }
            let df = ISO8601DateFormatter()
            df.formatOptions = [.withFullDate]
            let iso = df.string(from: travelDate)
            do {
                _ = try await BookingsRepository.shared.createBooking(
                    listingId: listing.id,
                    travelDate: iso,
                    guests: guests
                )
                presentedAlert = AppAlert(
                    title: "Booking confirmed",
                    message: "Your trip to \(listing.title) is reserved.",
                    kind: .success,
                    primaryLabel: "View bookings",
                    onPrimary: { dismiss() }
                )
            } catch {
                presentedAlert = AppAlert(
                    title: "Saved locally",
                    message: "Backend round-trip failed (you may be in dev-bypass mode without a real user). \n\n\(error.localizedDescription)",
                    kind: .warning,
                    primaryLabel: "OK"
                )
            }
        }
    }
}
