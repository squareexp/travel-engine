import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthController
    @State private var presentedAlert: AppAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TwendeSpacing.xxl) {
                Text("Profile").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Your travel preferences and account.")
                    .font(TwendeTypography.bodyLarge)
                    .foregroundStyle(TwendeColor.textSecondary)
                profileCard
                AppSurface(padding: TwendeSpacing.sm) {
                    VStack(spacing: 0) {
                    NavigationLink(value: ProfileRoute.favorites) {
                        row(icon: "heart", title: "Favorites")
                    }
                    .buttonStyle(.plain)
                    settingsButton(icon: "creditcard", title: "Payments")
                    settingsButton(icon: "bell", title: "Notifications")
                    settingsButton(icon: "lock.shield", title: "Security")
                    settingsButton(icon: "questionmark.circle", title: "Help & Support")
                    }
                }
                Button(action: { auth.signOut() }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign out").font(TwendeTypography.button)
                    }
                    .foregroundStyle(TwendeColor.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TwendeSpacing.md)
                    .background(TwendeColor.surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(TwendeColor.border, lineWidth: 1))
                }
            }
            .padding(TwendeSpacing.xl)
        }
        .background(TwendeColor.background)
        .sheet(item: $presentedAlert) { AppAlertSheet(alert: $0) }
    }

    private var profileCard: some View {
        let name = auth.session?.user.full_name ?? "Traveler"
        let email = auth.session?.user.email ?? ""
        return HStack(spacing: TwendeSpacing.md) {
            ZStack {
                Circle().fill(TwendeColor.primary).frame(width: 48, height: 48)
                Text(name.first.map { String($0).uppercased() } ?? "T")
                    .foregroundStyle(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            VStack(alignment: .leading) {
                Text(name).font(TwendeTypography.title)
                    .foregroundStyle(TwendeColor.textPrimary)
                if !email.isEmpty {
                    Text(email).font(TwendeTypography.caption)
                        .foregroundStyle(TwendeColor.textTertiary)
                }
            }
            Spacer()
        }
        .padding(TwendeSpacing.lg)
        .twendeCard()
    }

    private func row(icon: String, title: String) -> some View {
        HStack(spacing: TwendeSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(TwendeColor.textPrimary)
            Text(title).font(.system(size: 15))
                .foregroundStyle(TwendeColor.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(TwendeColor.textTertiary)
                .font(.system(size: 13))
        }
        .padding(.vertical, TwendeSpacing.md)
        .contentShape(Rectangle())
    }

    private func settingsButton(icon: String, title: String) -> some View {
        Button {
            presentedAlert = AppAlert(title: title, message: "This area will be available soon.", kind: .info)
        } label: {
            row(icon: icon, title: title)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(title)")
    }
}
