import SwiftUI

enum SheetKind { case info, success, warning, error }

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let kind: SheetKind
    let primaryLabel: String
    let secondaryLabel: String?
    let onPrimary: (() -> Void)?
    let onSecondary: (() -> Void)?

    init(
        title: String,
        message: String? = nil,
        kind: SheetKind = .info,
        primaryLabel: String = "OK",
        secondaryLabel: String? = nil,
        onPrimary: (() -> Void)? = nil,
        onSecondary: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.kind = kind
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }
}

struct AppAlertSheet: View {
    let alert: AppAlert
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(TwendeColor.border)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)

            HStack(alignment: .top, spacing: TwendeSpacing.md) {
                glyph
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title).font(TwendeTypography.h3)
                        .foregroundStyle(TwendeColor.textPrimary)
                    if let msg = alert.message {
                        Text(msg).font(TwendeTypography.body)
                            .foregroundStyle(TwendeColor.textSecondary)
                            .lineLimit(8)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, TwendeSpacing.xl)
            .padding(.bottom, TwendeSpacing.xl)

            VStack(spacing: TwendeSpacing.sm) {
                Button(action: { dismiss(); alert.onPrimary?() }) {
                    Text(alert.primaryLabel)
                        .font(TwendeTypography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TwendeSpacing.md)
                        .background(TwendeColor.primary)
                        .clipShape(Capsule())
                }
                if let secondary = alert.secondaryLabel {
                    Button(action: { dismiss(); alert.onSecondary?() }) {
                        Text(secondary)
                            .font(TwendeTypography.button)
                            .foregroundStyle(TwendeColor.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TwendeSpacing.md)
                            .overlay(Capsule().stroke(TwendeColor.border, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, TwendeSpacing.xl)
            .padding(.bottom, TwendeSpacing.xl)
        }
        .presentationDetents([.medium])
        .background(TwendeColor.surface)
    }

    private var glyph: some View {
        let (icon, color, bg): (String, Color, Color) = {
            switch alert.kind {
            case .success: return ("checkmark.circle.fill", TwendeColor.success, TwendeColor.successBg)
            case .warning: return ("exclamationmark.triangle.fill", TwendeColor.warning, TwendeColor.warningBg)
            case .error:   return ("xmark.octagon.fill", TwendeColor.danger, TwendeColor.dangerBg)
            case .info:    return ("info.circle.fill", TwendeColor.primary, TwendeColor.surfaceMuted)
            }
        }()
        return ZStack {
            Circle().fill(bg).frame(width: 40, height: 40)
            Image(systemName: icon).foregroundStyle(color)
        }
    }
}

#Preview("Alert Sheet") {
    Color.gray.opacity(0.1).ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AppAlertSheet(alert: AppAlert(
                title: "Booking confirmed",
                message: "Your trip to Nungwi Snorkeling Adventure is reserved.",
                kind: .success,
                primaryLabel: "View bookings",
                secondaryLabel: "Close"
            ))
        }
}
