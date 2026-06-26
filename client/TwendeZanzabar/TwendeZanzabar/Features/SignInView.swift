import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthController
    @State private var showDevSheet = false
    @State private var email = "traveler@test.com"
    @State private var password = "Test1234!"
    @State private var presentedAlert: AppAlert?

    var body: some View {
        VStack(spacing: 0) {
            hero
            sheet
        }
        .background(TwendeColor.background)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showDevSheet) {
            devSignInSheet.presentationDetents([.medium])
        }
        .sheet(item: $presentedAlert) { a in
            AppAlertSheet(alert: a)
        }
        .onChange(of: auth.status) { _, new in
            guard new == .error, let msg = auth.errorMessage else { return }
            presentedAlert = AppAlert(
                title: "Sign-in failed",
                message: msg,
                kind: .error,
                primaryLabel: "Try again"
            )
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: "https://images.unsplash.com/photo-1559825481-12a05cc00344?w=1200")
                .frame(minHeight: 300, maxHeight: 400)
                .clipped()
            Rectangle().fill(.black.opacity(0.35))
                .frame(minHeight: 300, maxHeight: 400)
            VStack(alignment: .leading, spacing: 12) {
                BrandHeader(subtitle: "One App. Zanzibar & Tanzania.",
                            color: .white, fontSize: 34)
                Text("Discover Zanzibar.\nExplore Tanzania.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 6)
            }
            .padding(.horizontal, TwendeSpacing.xxl)
            .padding(.bottom, TwendeSpacing.xxxl)
        }
    }

    @ViewBuilder
    private var sheet: some View {
        VStack(alignment: .leading, spacing: TwendeSpacing.md) {
            Text("Welcome").font(TwendeTypography.h2)
                .padding(.top, TwendeSpacing.xl)
            Text(APIConfig.devBypassAuth
                 ? "Skip auth and explore the prototype."
                 : "Sign in securely with your Base account.")
                .font(TwendeTypography.body)
                .foregroundStyle(TwendeColor.textSecondary)

            Spacer()

            if APIConfig.devBypassAuth {
                Button(action: { auth.signInAsDev() }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Enter as Preview Traveler")
                    }
                    .font(TwendeTypography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TwendeSpacing.md)
                    .background(TwendeColor.primary)
                    .clipShape(Capsule())
                }

                Button(action: { Task { await auth.signInWithBaseIdP() } }) {
                    Text("Continue with Base (IdP)")
                        .font(TwendeTypography.button)
                        .foregroundStyle(TwendeColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TwendeSpacing.md)
                        .background(TwendeColor.surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(TwendeColor.border, lineWidth: 1))
                }
            } else {
                Button(action: { Task { await auth.signInWithBaseIdP() } }) {
                    HStack {
                        if auth.status == .signingIn {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "shield.checkered")
                            Text("Continue with Base")
                        }
                    }
                    .font(TwendeTypography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TwendeSpacing.md)
                    .background(TwendeColor.primary)
                    .clipShape(Capsule())
                }
                .disabled(auth.status == .signingIn)

                Button(action: { showDevSheet = true }) {
                    Text("Dev sign-in (email/password)")
                        .font(TwendeTypography.button)
                        .foregroundStyle(TwendeColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TwendeSpacing.md)
                        .background(TwendeColor.surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(TwendeColor.border, lineWidth: 1))
                }
            }

            Text("By continuing you agree to the Twende Terms & Privacy Policy.")
                .font(TwendeTypography.caption)
                .foregroundStyle(TwendeColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, TwendeSpacing.sm)
        }
        .padding(.horizontal, TwendeSpacing.xxl)
        .padding(.bottom, TwendeSpacing.xxl)
        .frame(maxHeight: .infinity)
        .background(TwendeColor.background)
    }

    private var devSignInSheet: some View {
        VStack(alignment: .leading, spacing: TwendeSpacing.md) {
            Capsule().fill(TwendeColor.border)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            Text("Dev sign-in").font(TwendeTypography.h3)
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .padding(TwendeSpacing.md)
                .background(TwendeColor.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
            SecureField("Password", text: $password)
                .padding(TwendeSpacing.md)
                .background(TwendeColor.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
            Button(action: {
                showDevSheet = false
                Task { await auth.signInWithEmail(email: email, password: password) }
            }) {
                Text("Sign in").font(TwendeTypography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TwendeSpacing.md)
                    .background(TwendeColor.primary)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(TwendeSpacing.xxl)
    }
}
