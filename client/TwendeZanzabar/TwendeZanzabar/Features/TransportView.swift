import SwiftUI

struct TransportView: View {
    @State private var cars: [[String: Any]] = []
    @State private var loading = true
    @State private var presentedAlert: AppAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TwendeSpacing.md) {
                Text("Move with ease").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Airport transfers, day rentals and chauffeur-driven trips.")
                    .font(TwendeTypography.bodyLarge)
                    .foregroundStyle(TwendeColor.textSecondary)

                quickTile(icon: "airplane",
                          title: "Airport Transfer",
                          subtitle: "Arrivals & departures from ZNZ")
                quickTile(icon: "car",
                          title: "Day Rental",
                          subtitle: "Self-drive or with a driver, 8h package")
                quickTile(icon: "mappin.and.ellipse",
                          title: "Point-to-point",
                          subtitle: "One-way intercity transfer")

                Text("Available cars")
                    .font(TwendeTypography.h3)
                    .padding(.top, TwendeSpacing.lg)

                if loading {
                    ProgressView().tint(TwendeColor.primary)
                        .frame(maxWidth: .infinity)
                } else if cars.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(TwendeColor.primary)
                        Text("Car hire (Pistoni) is not running. Start the Go API on :1010 to load live cars.")
                            .font(TwendeTypography.body)
                            .foregroundStyle(TwendeColor.textPrimary)
                    }
                    .padding(TwendeSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwendeColor.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusLg, style: .continuous))
                } else {
                    ForEach(cars.indices, id: \.self) { idx in
                        carTile(cars[idx])
                    }
                }
            }
            .padding(TwendeSpacing.xl)
        }
        .background(TwendeColor.background)
        .sheet(item: $presentedAlert) { a in AppAlertSheet(alert: a) }
        .task { await load() }
        .refreshable { await load() }
    }

    private func quickTile(icon: String, title: String, subtitle: String) -> some View {
        Button(action: {
            presentedAlert = AppAlert(
                title: title,
                message: subtitle,
                kind: .info
            )
        }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous)
                        .fill(TwendeColor.surfaceMuted)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .foregroundStyle(TwendeColor.primary)
                }
                VStack(alignment: .leading) {
                    Text(title).font(TwendeTypography.title)
                        .foregroundStyle(TwendeColor.textPrimary)
                    Text(subtitle).font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(TwendeColor.textTertiary)
            }
            .padding(TwendeSpacing.md)
            .twendeCard()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func carTile(_ data: [String: Any]) -> some View {
        let title = (data["name"] as? String) ?? (data["model"] as? String) ?? "Car"
        let price = data["pricePerDay"] ?? data["daily_rate"]
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(TwendeTypography.title)
                if let p = price {
                    Text("$\(p) / day").font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.primary)
                }
            }
            Spacer()
        }
        .padding(TwendeSpacing.md)
        .twendeCard()
    }

    private func load() async {
        loading = true
        cars = (try? await TransportRepository.shared.listCars()) ?? []
        loading = false
    }
}
